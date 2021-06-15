// A user can be any principal or canister, which can hold a balance
type User = {
  #address : AccountIdentifier; //No notification
  #principal : Principal; //defaults to sub account 0
}

type SubAccount = [Nat8];

type AccountIdentifier = Text;

// An amount of tokens, unbound
type Balance = Nat;

// A global uninque id for a token
type TokenIdentifier  = {
  canister : Token;
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
type NoTokenError = {
  #InvalidToken: TokenIdentifier;
  #Other : Text;
};

//Requests and Responses
type BalanceRequest = { 
  user : User; 
  token: TokenIdentifier;
};
type BalanceResponse = Result<Balance, NoTokenError>;

type TransferRequest = {
  from : User;
  to : User;
  token : TokenIdentifier;
  amount : Balance;
  memo : ?Memo;
  notify : Bool;
};
type TransferResponse = {
  #ok : Balance;
  #err : {
    #Unauthorized;
    #InsufficientBalance;
    #Rejected; //Rejected by canister
    #InvalidToken: TokenIdentifier;
    #CannotNotify: AccountIdentifier;
    #Other : Text;
  }
};

type Token = actor {
  extensions : shared query () -> async [Extension];

  balance: shared query (request : BalanceRequest) -> async BalanceResponse;
      
  transfer: shared (request : TransferRequest) -> async TransferResponse;
};