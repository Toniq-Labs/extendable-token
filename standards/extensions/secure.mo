//Secure - removes queries
type Token_secure = actor {
  extensions : shared () -> async [Extension];
  
  metadata_secure: shared (token : TokenIdentifier) -> async Result<Metadata, CommonError>;

  supply_secure: shared (token : TokenIdentifier) -> async Result<Balance, CommonError>;
  
  balance_secure: shared (request : BalanceRequest) -> async BalanceResponse;
};