//Archive extension to allow for storage of txs/retreival of txs
//TODO
type Date = Nat64;
type TransactionId = Nat;
type Transaction = {
  txid : TransactionId;
  request : TransferRequest;
  date : Date;
};

type TransactionsRequest = {
  query : {
    #txid : TransactionId;
    #user : ;
    #date : (DatUsere, Nat64);
    #page : (Nat, Nat);
    #all;
  }
  token : TokenIdentifier;
};

//Private/internal add function for archive
type add = shared (request : TransferRequest) -> TransactionId;

type Token_archive = actor {
  public transactions: shared query (request : TransactionsRequest) -> async Result<[Transaction], NoTokenError>;
};