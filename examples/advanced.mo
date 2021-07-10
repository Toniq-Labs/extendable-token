/*
Multi-token canister
*/

import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Array "mo:base/Array";

//Get the path right
import AID "../motoko/util/AccountIdentifier";
import ExtCore "../motoko/ext/Core";
import ExtCommon "../motoko/ext/Common";

actor class advanced_token(init_admin: Principal) = this{
  
  // Types
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type TokenIndex = ExtCore.TokenIndex;
  type Extension = ExtCore.Extension;
  type CommonError = ExtCore.CommonError;
  type NotifyService = ExtCore.NotifyService;
  
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  type Metadata = ExtCommon.Metadata;
  
  type RegisterTokenRequest = {
    metadata : Metadata;
    supply : Balance;
    owner : AccountIdentifier;
  };
  type TokenLedger = HashMap.HashMap<AccountIdentifier, Balance>;
  
  private let EXTENSIONS : [Extension] = ["@ext/common"];
  
  //State work
  private var CREATE_TOKEN_FEE : Nat = 1_000_000_000_000;
  private stable var _nextTokenId : TokenIndex = 0;
  private stable var _registryState : [(TokenIndex, [(AccountIdentifier, Balance)])] = [];
  private stable var _metadataState : [(TokenIndex, (Metadata, Balance))] = [];
  private stable var _admin : Principal = init_admin;
  
  private var _registry = HashMap.HashMap<TokenIndex, TokenLedger>(1, Nat32.equal, func(x : Nat32) : Hash.Hash {x});
  Iter.iterate<(TokenIndex, [(AccountIdentifier, Balance)])>(_registryState.vals(), func(x, _index) {
    _registry.put(x.0, HashMap.fromIter(x.1.vals(), 0, AID.equal, AID.hash));
  });
  
  private var _metadata = HashMap.HashMap<TokenIndex, (Metadata, Balance)>(1, Nat32.equal, func(x : Nat32) : Hash.Hash {x});
  Iter.iterate<(TokenIndex, (Metadata, Balance))>(_metadataState.vals(), func(x, _index) {
    _metadata.put(x.0, x.1);
  });
  
    
  //State functions
  system func preupgrade() {
    Iter.iterate(_registry.entries(), func(x : (TokenIndex, TokenLedger), _index : Nat) {
      _registryState := Array.append(_registryState, [(x.0, Iter.toArray(x.1.entries()))]);
    });
    _metadataState := Iter.toArray(_metadata.entries());
  };
  system func postupgrade() {
    _registryState := [];
    _metadataState := [];
  };
  
  public shared(msg) func changeAdmin(newAdmin : Principal) : async () {
    assert(msg.caller == _admin);
    _admin := newAdmin;
  };
  
  public shared(msg) func registerToken(request: RegisterTokenRequest) : async Result.Result<TokenIndex,Text> {
    /*if (msg.caller != _admin) {
      let available = Cycles.available();
      if (available < CREATE_TOKEN_FEE) {        
        return #err("Please send the correct amount of cycles to create your new token");
      };
      ignore(Cycles.accept(available));
    };*/
    let tokenId : TokenIndex = _nextTokenId;
    let ledger = HashMap.HashMap<AccountIdentifier, Balance>(1, AID.equal, AID.hash);
    ledger.put(request.owner, request.supply);
    _registry.put(tokenId, ledger);
    _metadata.put(tokenId, (request.metadata, request.supply));
    _nextTokenId := _nextTokenId + 1;
    return #ok(tokenId);
  };
  
  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
    let tokenIndex = ExtCore.TokenIdentifier.getIndex(request.token);
    var tokenBalances = switch(_registry.get(tokenIndex)) {
      case (?balances) balances;
      case (_) return #err(#InvalidToken(request.token));
    };
    
    let sender = ExtCore.User.toAID(request.from);
    let spender = AID.fromPrincipal(msg.caller, request.subaccount);
    let receiver = ExtCore.User.toAID(request.to);
    if (AID.equal(sender, spender) == false) {
      return #err(#Unauthorized(spender));
    };
    
    switch (tokenBalances.get(sender)) {
      case (?sender_balance) {
        if (sender_balance >= request.amount) {
          //Remove from sender first
          var sender_balance_new : Balance = sender_balance - request.amount;
          tokenBalances.put(sender, sender_balance_new);
          
          var provisional_amount : Balance = request.amount;
          var receiver_balance_new = switch (tokenBalances.get(receiver)) {
            case (?receiver_balance) {
                receiver_balance + provisional_amount;
            };
            case (_) {
                provisional_amount;
            };
          };
          if (request.notify) {
            switch(ExtCore.User.toPrincipal(request.to)) {
              case (?canisterId) {
                let notifier : NotifyService = actor(Principal.toText(canisterId));
                switch(await notifier.tokenTransferNotification(request.token, request.from, request.amount, request.memo)) {
                  //Refresh token balances after an await
                  case (?balance) {
                    provisional_amount := balance;
                    tokenBalances := switch(_registry.get(tokenIndex)) {
                      case (?balances) balances;
                      case (_) return #err(#Other("Token was deleted during transfer..."));
                    };
                    assert(provisional_amount <= request.amount);
                    receiver_balance_new := switch (tokenBalances.get(receiver)) {
                      case (?receiver_balance) {
                          receiver_balance + provisional_amount;
                      };
                      case (_) {
                          provisional_amount;
                      };
                    };
                  };
                  case (_) {
                    tokenBalances := switch(_registry.get(tokenIndex)) {
                      case (?balances) balances;
                      case (_) return #err(#Other("Token was deleted during transfer..."));
                    };
                    var sender_balance_new2 = switch (tokenBalances.get(sender)) {
                      case (?sender_balance) {
                          sender_balance + request.amount;
                      };
                      case (_) {
                          request.amount;
                      };
                    };
                    tokenBalances.put(sender, sender_balance_new2);
                    return #err(#Rejected);
                  };
                };
              };
              case (_) {
                tokenBalances.put(sender, sender_balance);
                return #err(#CannotNotify(receiver));
              }
            };
          };
          tokenBalances.put(receiver, receiver_balance_new);
          
          //Process sender refund
          if (provisional_amount < request.amount) {
            var sender_refund : Balance = request.amount - provisional_amount;
            var sender_balance_new2 = switch (tokenBalances.get(sender)) {
              case (?sender_balance) {
                  sender_balance + sender_refund;
              };
              case (_) {
                  sender_refund;
              };
            };
            tokenBalances.put(sender, sender_balance_new2);
          };
          
          //Update registry
          _registry.put(tokenIndex, tokenBalances);
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
    if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
    let tokenIndex = ExtCore.TokenIdentifier.getIndex(request.token);
    var tokenBalances = switch(_registry.get(tokenIndex)) {
      case (?balances) balances;
      case (_) return #err(#InvalidToken(request.token));
    };
    let aid = ExtCore.User.toAID(request.user);
    switch (tokenBalances.get(aid)) {
      case (?balance) {
        return #ok(balance);
      };
      case (_) {
        return #ok(0);
      };
    }
  };
  
  public query func numberOfTokenHolders(token : TokenIdentifier) : async Result.Result<Nat, CommonError> {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
    let tokenIndex = ExtCore.TokenIdentifier.getIndex(token);
    var tokenBalances = switch(_registry.get(tokenIndex)) {
      case (?balances) balances;
      case (_) return #err(#InvalidToken(token));
    };
    return #ok(Iter.size(tokenBalances.entries()));
  };
  
  public query func numberOfTokens() : async Nat {
    return Iter.size(_registry.entries());
  };

  public query func supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
    let tokenIndex = ExtCore.TokenIdentifier.getIndex(token);
    var tokenData = switch(_metadata.get(tokenIndex)) {
      case (?metadata) metadata;
      case (_) return #err(#InvalidToken(token));
    };
    #ok(tokenData.1);
  };
  public query func metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
    let tokenIndex = ExtCore.TokenIdentifier.getIndex(token);
    var tokenData = switch(_metadata.get(tokenIndex)) {
      case (?metadata) metadata;
      case (_) return #err(#InvalidToken(token));
    };
    #ok(tokenData.0);
  };
  public query func registry(token : TokenIdentifier) : async Result.Result<[(AccountIdentifier, Balance)], CommonError> {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
    let tokenIndex = ExtCore.TokenIdentifier.getIndex(token);
    var tokenBalances = switch(_registry.get(tokenIndex)) {
      case (?balances) balances;
      case (_) return #err(#InvalidToken(token));
    };
    return #ok(Iter.toArray(tokenBalances.entries()));
  };
  
  public query func allMetadata() : async [(TokenIndex, (Metadata, Balance))] {
    Iter.toArray(_metadata.entries());
  };
  
  public query func allRegistry() : async [(TokenIndex, [(AccountIdentifier, Balance)])] {
    var ret : [(TokenIndex, [(AccountIdentifier, Balance)])] = [];
    Iter.iterate(_registry.entries(), func(x : (TokenIndex, TokenLedger), _index : Nat) {
      ret := Array.append(ret, [(x.0, Iter.toArray(x.1.entries()))]);
    });
    ret;
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
