import ExtCore "./Core";
module ExtFee = {
  public type TransferRequest = {
    from : ExtCore.User;
    to : ExtCore.User;
    token : ExtCore.TokenIdentifier;
    amount : ExtCore.Balance;
    fee : ExtCore.Balance;
    memo : ExtCore.Memo;
    notify : Bool;
    subaccount : ?ExtCore.SubAccount;
  };
  public type Service = actor {
    fee: (token : ExtCore.TokenIdentifier) -> async ();
  }
};