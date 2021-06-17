/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
module ExtOperator = {
  public type Tokens = {
    #All; //all tokens for all balances
    #Some: (ExtCore.TokenIdentifier, ?ExtCore.Balance); //null balance = for all balance of that token
  };

  public type OperatorAction = {
    #SetOperator: Tokens;
    #RemoveOperator: ?[ExtCore.TokenIdentifier]; //null removes from all
  };

  public type OperatorRequest = {
    subaccount : ?ExtCore.SubAccount;
    operators: [(Principal, OperatorAction)]
  };

  public type OperatorResponse = Result.Result<(), {
    #Unauthorized;
  }>;
  public type IsAuthorizedRequest = {
    owner: ExtCore.User;
    operator: Princpal;
    token : ExtCore.TokenIdentifier
    amount: ExtCore.Balance;
  };

  public type ValidActor = actor {
    updateOperator : shared (request : OperatorRequest) -> async OperatorResponse;
    
    isAuthorized : shared (request : IsAuthorizedRequest) -> async Result.Result<Bool, ExtCore.CommonError>;
  };
};