/*
Basic single token per canister
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

actor class standard_token(init_name: Text, init_symbol: Text, init_decimals: Nat8, init_supply: ExtCore.Balance, init_owner: Principal) = this{
  
  // Types
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type Extension = ExtCore.Extension;
  type CommonError = ExtCore.CommonError;
  type NotifyService = ExtCore.NotifyService;
  
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  type Metadata = ExtCommon.Metadata;
  
  private let EXTENSIONS : [Extension] = ["@ext/common"];
  
  //State work
  private stable var _balancesState : [(AccountIdentifier, Balance)] = [(AID.fromPrincipal(init_owner, null), init_supply)];
  private var _balances : HashMap.HashMap<AccountIdentifier, Balance> = HashMap.fromIter(_balancesState.vals(), 0, AID.equal, AID.hash);
  private stable let METADATA : Metadata = #fungible({
    name = init_name;
    symbol = init_symbol;
    decimals = init_decimals;
    metadata = null;
  }); 
  private stable var _supply : Balance  = init_supply;
  
  //State functions
  system func preupgrade() {
    _balancesState := Iter.toArray(_balances.entries());
  };
  system func postupgrade() {
    _balancesState := [];
  };
  
  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
    if (ExtCore.TokenIdentifier.getIndex(request.token) != 0) {
			return #err(#InvalidToken(request.token));
		};
    let sender = ExtCore.User.toAID(request.from);
    let spender = AID.fromPrincipal(msg.caller, request.subaccount);
    let receiver = ExtCore.User.toAID(request.to);
    if (AID.equal(sender, spender) == false) {
      return #err(#Unauthorized(spender));
    };
    
    switch (_balances.get(sender)) {
      case (?sender_balance) {
        if (sender_balance >= request.amount) {
          //Remove from sender first
          var sender_balance_new : Balance = sender_balance - request.amount;
          _balances.put(sender, sender_balance_new);
          
          var provisional_amount : Balance = request.amount;
          if (request.notify) {
            switch(ExtCore.User.toPrincipal(request.to)) {
              case (?canisterId) {
                let notifier : NotifyService = actor(Principal.toText(canisterId));
                switch(await notifier.tokenTransferNotification(request.token, request.from, request.amount, request.memo)) {
                  case (?balance) {
                    provisional_amount := balance;
                  };
                  case (_) {
                    var sender_balance_new2 = switch (_balances.get(sender)) {
                      case (?sender_balance) {
                          sender_balance + request.amount;
                      };
                      case (_) {
                          request.amount;
                      };
                    };
                    _balances.put(sender, sender_balance_new2);
                    return #err(#Rejected);
                  };
                };
              };
              case (_) {
                var sender_balance_new2 = switch (_balances.get(sender)) {
                  case (?sender_balance) {
                      sender_balance + request.amount;
                  };
                  case (_) {
                      request.amount;
                  };
                };
                _balances.put(sender, sender_balance_new2);
                return #err(#CannotNotify(receiver));
              }
            };
          };
          assert(provisional_amount <= request.amount); //should never hit
          
          var receiver_balance_new = switch (_balances.get(receiver)) {
            case (?receiver_balance) {
                receiver_balance + provisional_amount;
            };
            case (_) {
                provisional_amount;
            };
          };
          _balances.put(receiver, receiver_balance_new);
          
          //Process sender refund
          if (provisional_amount < request.amount) {
            var sender_refund : Balance = request.amount - provisional_amount;
            var sender_balance_new2 = switch (_balances.get(sender)) {
              case (?sender_balance) {
                  sender_balance + sender_refund;
              };
              case (_) {
                  sender_refund;
              };
            };
            _balances.put(sender, sender_balance_new2);
          };
          
          return #ok(provisional_amount);
        } else {
          return #err(#InsufficientBalance);
        };
      };
      case (_) {
        return #err(#InsufficientBalance);
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
  
  public query func registry() : async [(AccountIdentifier, Balance)] {
    Iter.toArray(_balances.entries());
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
