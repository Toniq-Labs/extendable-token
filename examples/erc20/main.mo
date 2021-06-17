import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import AID "./util/AccountIdentifier";
import ExtCore "./ext/Core";
import ExtCommon "./ext/Common";
import ExtSecure "./ext/Secure";
import ExtFee "./ext/Fee";

actor WTC_Token {
  
  // Types
  // inherit from ext
  type AccountIdentifier = AID.AccountIdentifier;
  type SubAccount = AID.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type Extension = ExtCore.Extension;
  type Memo = ExtCore.Memo;
  type CommonError = ExtCore.CommonError;
  type NotifyService = ExtCore.NotifyService;
  
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtFee.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;

  type Metadata = ExtCommon.Metadata;
  
  // wtc types
  type Callback = shared () -> async ();
  type CallbackService = actor{ acceptCycles : Callback };
  
  //Init variables
  //No real point this being stable when using let? 
  //maybe better as a stable var
  private stable let WTCMETADATA : Metadata = #fungible({
    name = "Wrapped Cycles";
    symbol = "WTC";
    decimals = 12;
    metadata = null;
  }); 
  
  private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/secure", "@ext/fee"];
  private let MINTING_FEE : Balance = 1_000_000_000;
  private let MIN_CYCLE_THRESHOLD : Balance = 500_000_000_000;
  private let BURN_MEMO : Memo = Blob.fromArray([107, 100, 107, 110, 114, 115]); //6b646b6e7273 or 0x6b646b6e7273

  //stable state
  private stable var _supply : Balance  = 0;
  private stable var _balanceState : [(AccountIdentifier, Balance)] = [];
  private var _balances : HashMap.HashMap<AccountIdentifier, Balance> = HashMap.fromIter(_balanceState.vals(), 0, AID.equal, AID.hash);
  system func preupgrade() {
      _balanceState := Iter.toArray(_balances.entries());
  };

  system func postupgrade() {
      _balanceState := [];
  };
  
  // WTC specific calls
  //To convert Cycles into WTC
  //You can use the cycle wallets `wallet_call` method
  public shared(msg) func mint(user : ?User) : async () {
    let aid = switch (user) {
      case (?u) {
        _aidFromUser(u);
      };
      case (_) {
        //Currently defaults to sender, but maybe we return an error here?
        AID.fromPrincipal(msg.caller, null);
      };
    };
    let amount = Cycles.available();
    assert(amount > 0);
    let accepted = Cycles.accept(amount);
    assert(accepted == amount);
    let new_balance = switch (_balances.get(aid)) {
      case (?balance) {
        balance + amount;
      };
      case (_) {
        amount;
      };
    };
    _balances.put(aid, new_balance);
    _supply += amount;
  };
  
  /*
    Caller should submit a function to accept the cycles, e.g.:
    Callback function should be of type callback shared() -> async ()
    e.g. below:
    public func acceptCycles() : async () {
      let available = Cycles.available();
      let accepted = Cycles.accept(available);
      assert (accepted == available);
    };
  */
  //TODO add fee in burn
  public shared(msg) func burn(amount : Balance, callback : Callback) : async Bool {
    _assertCycles();
    let aid = AID.fromPrincipal(msg.caller, null);
    await _burnAndSendCycles(aid, amount, callback);
  };
  
  
  public query func minCyclesThreshold() : async Balance {
    return MIN_CYCLE_THRESHOLD;
  };
  public query func fee() : async Balance {
    return MINTING_FEE;
  };

  //Internal cycle management
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };

  public query func actualCycles() : async Nat {
    assert(Cycles.balance() > _supply);
    return Cycles.balance() - _supply;
  };
  
  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };
  
  //ext specific calls
  //Update calls
  //customized to allow for BURN on the fly (easier for users to send WTC as cycles to a canister
  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    _assertCycles();
    let from_aid = AID.fromPrincipal(msg.caller, request.subaccount);
    if (AID.equal(from_aid, _aidFromUser(request.from)) == false) {
      return #err(#Unauthorized(from_aid));
    };
    let to_aid = _aidFromUser(request.to);
    let amountAndFee : Balance = request.amount + request.fee;
    switch (_balances.get(from_aid)) {
      case (?from_balance) {
        if (from_balance >= amountAndFee) {
          //Fee is always consumed
          _supply := _supply - request.fee;
          let from_balance_after_fee : Balance = from_balance - request.fee;
          _balances.put(from_aid, from_balance_after_fee);
          
          if (request.memo == BURN_MEMO) {
            //Special case for converting WTC to cycles on the fly
            //We do not notify here
            //request.to must be a principal
            switch(request.to) {
              case (#address address) {
                return #err(#Other("Can only BURN to principals"));
              };
              case (#principal principal) {
                let cs : CallbackService = actor(Principal.toText(principal));
                
                //This handles balance update, refunds and cycle transfer and supply updates - same as with burn()
                let r = await _burnAndSendCycles(from_aid, request.amount, cs.acceptCycles);
                if (r == true){
                  //0 because 0 is transferred through the ledger the amount is burnt or refunded
                  //todo maybe return actual amount sent
                  return #ok(0);
                } else {
                  return #err(#InsufficientBalance); //shouldn't ever hit...
                };
              };
            };
          } else {
            //Remove funds from sender first
            _balances.put(from_aid, from_balance_after_fee - request.amount);
            
            var accepted : Balance = request.amount;
            //Try and notify
            if (request.notify == true) {
              switch(request.to) {
                case (#address address) {
                  //Refund and exit - can only notify principals
                  _refund(from_aid, request.amount);
                  return #err(#CannotNotify(address));
                };
                case (#principal principal) {
                  let ns : NotifyService = actor(Principal.toText(principal));
                  let r = await ns.tokenTransferNotification(request.token, request.from, request.amount, request.memo);
                  accepted := switch(r){
                    case (?b) b;
                    case (_) {
                      _refund(from_aid, request.amount);
                      return #err(#Rejected);
                    };
                  };
                };
              };
            };
            assert(accepted <= request.amount); //Should never trigger...
            if (accepted < request.amount) {
              //There was a refund
              _refund(from_aid, request.amount - accepted);
            };
            
            //Add to new balance
            let to_balance_new = switch (_balances.get(to_aid)) {
            case (?to_balance) {
                to_balance + accepted;
              };
            case (_) {
                accepted;
              };
            };
            assert(to_balance_new >= accepted); //Should never trigger...
            _balances.put(to_aid, to_balance_new);
            return #ok(accepted);
          }
        } else if (from_balance >= request.fee) {
          _supply := _supply - request.fee;
          _balances.put(from_aid, from_balance - request.fee);
          return #err(#InsufficientBalance);
        } else {
          _supply := _supply - from_balance;
          var v = _balances.remove(from_aid);
          return #err(#InsufficientBalance);
        };
      };
      case (_) {
        return #err(#InsufficientBalance);
      };
    };
  };

  //ext-secure calls here
  public func extensions_secure() : async [Extension] {
    EXTENSIONS;
  };
  public func metadata_secure(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    #ok(WTCMETADATA);
  };
  public func supply_secure(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(_supply);
  };
  public func balance_secure(request : BalanceRequest) : async BalanceResponse {
    return await balance(request);
  };
    
  //Query calls
  public query func extensions() : async [Extension] {
    EXTENSIONS;
  };
  public query func balance(request : BalanceRequest) : async BalanceResponse {
    let aid = _aidFromUser(request.user);
    switch (_balances.get(aid)) {
      case (?balance) {
        return #ok(balance);
      };
      case (_) {
        return #ok(0);
      };
    }
  };
  
  //ext-common queries
  //We don't have multiple tokens, so just use 0;
  public query func supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(_supply);
  };
  public query func metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    #ok(WTCMETADATA);
  };
  
  //Remove soon?
  public query func balances() : async [(AccountIdentifier, Balance)] {
    Iter.toArray(_balances.entries());
  };
  

  //Private
  //Ensure there are tokens available for computation
  private func _assertCycles() : () {
    assert( Cycles.balance() > (_supply + MIN_CYCLE_THRESHOLD) );
  };
  private func _aidFromUser(user : User) : AccountIdentifier {
    switch(user) {
      case (#address address) address;
      case (#principal principal) {
        AID.fromPrincipal(principal, null);
      };
    };
  };
  private func _burnAndSendCycles(aid : AccountIdentifier, amount : Balance, callback : Callback) : async Bool {
    switch (_balances.get(aid)) {
      case (?balance) {
        if (amount > balance) {
          return false;
        } else {
          //Remove WTC before we call
          _balances.put(aid, balance - amount);
          
          //If this fails, cycles are lost so remove from supply first (so we can still use the cycles)
          _supply -= amount;
          Cycles.add(amount);
          await callback();
          
          //Refund refused cycles
          let refund : Balance = Cycles.refunded();
          if (refund > 0){
            _refund(aid, refund);
            _supply += refund;
          };
          return true;
        };
      };
      case (_) {
        return false;
      };
    }
  };
  private func _refund(aid : AccountIdentifier, refund : Balance) : () {
    switch (_balances.get(aid)) {
      case (?balance_now) {
        //Get updated balance incase it has changed after
        _balances.put(aid, balance_now + refund);                        
      };
      case (_) {
        _balances.put(aid, refund);                        
      };
    }
  };
}