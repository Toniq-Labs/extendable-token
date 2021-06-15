//Add erc20 like allowances
//We use transfer still not transferFrom (as transfer has a from field)
type AllowanceRequest = {
  owner : User;
  spender : Principal;
};

type ApproveRequest = {
  subaccount : ?SubAccount;
  spender : Principal;
  allowance : Balance;
};

type Token_allowance = actor {
  allowance: shared query (request : AllowanceRequest) -> async async Result<Balance, NoTokenError>;
      
  approve: shared (request : ApproveRequest) -> async ();
};