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
    #user : User;
    #date : (Date, Date); //from - to
    #page : (Nat, Nat); // all per page - page
    #all;
  }
  token : TokenIdentifier;
};

//Private/internal add function for archive

type Token_archive = actor {
  add : shared (request : TransferRequest) -> TransactionId;
  transactions : query (request : TransactionsRequest) -> async Result<[Transaction], CommonError>;
};