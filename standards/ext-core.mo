//HM Do we abstract transfers out, and just have extensions and balance calls?
//and move transfer into a "transfer" extension?

//SubAccount and AID to support native addresses
type AccountIdentifier = Text;
type SubAccount = [Nat8];

// A user can be any principal or canister, which can hold a balance
type User = {
  #address : AccountIdentifier; //No notification
  #principal : Principal; //defaults to sub account 0
}

// An amount of tokens, unbound
type Balance = Nat;

// A global uninque id for a token
type TokenIdentifier  = {
  canister : Principal;
  index : Nat32;
};

// Extension nane, e.g. 'batch' for batch requests
type Extension = Text;

// Additional data field for transfers to describe the tx
// Data will also be forwarded to notify callback
type Memo : Blob;

//Call back for notifications
type NotifyService = actor { tokenTransferNotification : shared (TokenIdentifier, User, Balance, ?Memo) -> async ?Balance)};

//Common error respone
type CommonError = {
  #InvalidToken: TokenIdentifier;
  #Other : Text;
};

//Requests and Responses
type BalanceRequest = { 
  user : User; 
  token: TokenIdentifier;
};
type BalanceResponse = Result<Balance, CommonError>;

type TransferRequest = {
  from : User;
  to : User;
  token : TokenIdentifier;
  amount : Balance;
  memo : ?Memo;
  notify : Bool;
};
type TransferResponse = Result<Balance, {
  #Unauthorized;
  #InsufficientBalance;
  #Rejected; //Rejected by canister
  #InvalidToken: TokenIdentifier;
  #CannotNotify: AccountIdentifier;
  #Other : Text;
}>;

type Token = actor {
  extensions : shared query () -> async [Extension];

  balance: shared query (request : BalanceRequest) -> async BalanceResponse;
      
  transfer: shared (request : TransferRequest) -> async TransferResponse;
};