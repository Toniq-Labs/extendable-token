//Common
// If a token supports fee it must overwrite the default TransferRequest with this one
type TransferRequest = {
  from : User;
  to : User;
  token : TokenIdentifier;
  amount : Balance;
  fee : Balance;
  memo : Memo;
  notify : Bool;
  subaccount : ?SubAccount;
};

type Token_fee = actor {
  fee: (token : TokenIdentifier) -> async ();
};