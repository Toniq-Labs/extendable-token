type Tokens = {
  #All; //all tokens for all balances
  #Some: (TokenIdentifier, ?Balance); //null balance for all balancer of that token
};

type OperatorAction = {
  #SetOperator: Tokens;
  #RemoveOperator: ?[TokenIdentifier]; //null removes from all
};

type OperatorRequest = {
  owner: User;
  operators: [(Principal, OperatorAction)]
};

type OperatorResponse = Result.Result<(), {
  #Unauthorized;
}>;
type IsAuthorizedRequest = {
  owner: User;
  operator: Princpal;
  token : TokenIdentifier
  amount: Balance;
};
type Token_allowance = actor {
  updateOperator : shared (request : OperatorRequest) -> async OperatorResponse;
  
  isAuthorized : shared (request : IsAuthorizedRequest) -> async Result<Bool, CommonError>;
};