//Add erc20 like allowances
//We use transfer still not transferFrom (as transfer has a from field)
type AllowanceRequest = {
  owner : User;
  spender : Principal;
  token : TokenIdentifier;
};

type ApproveRequest = {
  subaccount : ?SubAccount;
  spender : Principal;
  allowance : Balance;
  token : TokenIdentifier;
};

type Token_allowance = actor {
  allowance: shared query (request : AllowanceRequest) -> async async Result<Balance, CommonError>;
      
  approve: shared (request : ApproveRequest) -> async ();
};