/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
module ExtAllowance = {
  public type AllowanceRequest = {
    owner : ExtCore.User;
    spender : Principal;
    token : ExtCore.TokenIdentifier;
  };

  public type ApproveRequest = {
    subaccount : ?ExtCore.SubAccount;
    spender : Principal;
    allowance : ExtCore.Balance;
    token : ExtCore.TokenIdentifier;
  };

  public type ValidActor = actor {
    allowance: shared query (request : AllowanceRequest) -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
        
    approve: shared (request : ApproveRequest) -> async ();
  };
};