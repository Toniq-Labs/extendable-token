//Secure - replaces queries
type Token_secure = actor {
  extensions_secure : shared () -> async [Extension];
  
  metadata_secure: shared (token : TokenIdentifier) -> async Result<Metadata, CommonError>;

  supply_secure: shared (token : TokenIdentifier) -> async Result<Balance, CommonError>;
  
  balance_secure: shared (request : BalanceRequest) -> async BalanceResponse;
};
