/**
//Needs more work...
 */
import ExtCore "./Core";
module ExtLedger = {
  public type AccountBalanceArgs = { 
    account : ExtCore.AccountIdentifier;
    token : ExtCore.TokenIdentifier; 
  };
  public type ICPTs = { e8s : Nat64 };
  public type BlockHeight = Nat64;
  public type SendArgs = {
    to : ExtCore.AccountIdentifier;
    fee : ICPTs;
    memo : Nat64;
    from_subaccount : ?ExtCore.SubAccount;
    created_at_time : ?{ timestamp_nanos : Nat64 };
    amount : ICPTs;
    token : ExtCore.TokenIdentifier;
  };

  public type ValidActor = actor {
    account_balance_dfx : shared query AccountBalanceArgs -> async ICPTs;
    
    send_dfx : shared SendArgs -> async BlockHeight;
  };
};