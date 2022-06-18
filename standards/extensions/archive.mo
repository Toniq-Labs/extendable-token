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
    #date : (Date, Date); //from - to, range is inclusive on both ends
    #page : (Nat, Nat); // all per page - page, range is inclusive on both ends
    #all;
  }
  token : TokenIdentifier;
};

//Private/internal add function for archive

type Token_archive = actor {
  add : shared (request : TransferRequest) -> TransactionId; // function traps in case of any errors
  transactions : query (request : TransactionsRequest) -> async Result<[Transaction], CommonError>;
};
