/*
ERC20 - note the following:
-No notifications (can be added)
-All tokenids are ignored
-You can use the canister address as the token id
-Memo is ignored
-No transferFrom (as transfer includes a from field)
*/
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

//Get the path right
import AID "../motoko/util/AccountIdentifier";
import ExtCore "../motoko/ext/Core";
import ExtCommon "../motoko/ext/Common";
import ExtAllowance "../motoko/ext/Allowance";

actor class erc20_token(init_name: Text, init_symbol: Text, init_decimals: Nat8, init_supply: ExtCore.Balance, init_owner: Principal) {
  
  // Types
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type Extension = ExtCore.Extension;
  type CommonError = ExtCore.CommonError;
  
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  type AllowanceRequest = ExtAllowance.AllowanceRequest;
  type ApproveRequest = ExtAllowance.ApproveRequest;

  type Metadata = ExtCommon.Metadata;
  
  private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/allowance"];

  
  //State work
  private stable var _balancesState : [(AccountIdentifier, Balance)] = [];
  private var _balances : HashMap.HashMap<AccountIdentifier, Balance> = HashMap.fromIter(_balancesState.vals(), 0, AID.equal, AID.hash);
  private var _allowances = HashMap.HashMap<AccountIdentifier, HashMap.HashMap<Principal, Balance>>(1, AID.equal, AID.hash);
  
  //State functions
  system func preupgrade() {
    _balancesState := Iter.toArray(_balances.entries());
    //Allowances are not stable, they are lost during upgrades...
  };
  system func postupgrade() {
    _balancesState := [];
  };
  
    //Initial state - could set via class setter
  private stable let METADATA : Metadata = #fungible({
    name = init_name;
    symbol = init_symbol;
    decimals = init_decimals;
    metadata = null;
  }); 
  private stable var _supply : Balance  = init_supply;
  
  _balances.put(AID.fromPrincipal(init_owner, null), _supply);

  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    let owner = ExtCore.User.toAID(request.from);
    let spender = AID.fromPrincipal(msg.caller, request.subaccount);
    let receiver = ExtCore.User.toAID(request.to);
    
    switch (_balances.get(owner)) {
      case (?owner_balance) {
        if (owner_balance >= request.amount) {
          if (AID.equal(owner, spender) == false) {
            //Operator is not owner, so we need to validate here
            switch (_allowances.get(owner)) {
              case (?owner_allowances) {
                switch (owner_allowances.get(msg.caller)) {
                  case (?spender_allowance) {
                    if (spender_allowance < request.amount) {
                      return #err(#Other("Spender allowance exhausted"));
                    } else {
                      var spender_allowance_new : Balance = spender_allowance - request.amount;
                      owner_allowances.put(msg.caller, spender_allowance_new);
                      _allowances.put(owner, owner_allowances);
                    };
                  };
                  case (_) {
                    return #err(#Unauthorized(spender));
                  };
                };
              };
              case (_) {
                return #err(#Unauthorized(spender));
              };
            };
          };
          
          var owner_balance_new : Balance = owner_balance - request.amount;
          _balances.put(owner, owner_balance_new);
          var receiver_balance_new = switch (_balances.get(receiver)) {
            case (?receiver_balance) {
                receiver_balance + request.amount;
            };
            case (_) {
                request.amount;
            };
          };
          _balances.put(receiver, receiver_balance_new);
          return #ok(request.amount);
        } else {
          return #err(#InsufficientBalance);
        };
      };
      case (_) {
        return #err(#InsufficientBalance);
      };
    };
  };
  
  public shared(msg) func approve(request: ApproveRequest) : async () {
    let owner = AID.fromPrincipal(msg.caller, request.subaccount);
    switch (_allowances.get(owner)) {
      case (?owner_allowances) {
        owner_allowances.put(request.spender, request.allowance);
        _allowances.put(owner, owner_allowances);
      };
      case (_) {
        var temp = HashMap.HashMap<Principal, Balance>(1, Principal.equal, Principal.hash);
        temp.put(request.spender, request.allowance);
        _allowances.put(owner, temp);
      };
    };
  };

  public query func extensions() : async [Extension] {
    EXTENSIONS;
  };
  
  public query func balance(request : BalanceRequest) : async BalanceResponse {
    let aid = ExtCore.User.toAID(request.user);
    switch (_balances.get(aid)) {
      case (?balance) {
        return #ok(balance);
      };
      case (_) {
        return #ok(0);
      };
    }
  };

  public query func supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(_supply);
  };
  
  public query func metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    #ok(METADATA);
  };
  
  //Internal cycle management - good general case
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };
}
