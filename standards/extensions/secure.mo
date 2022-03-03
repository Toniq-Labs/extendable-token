//Secure - replaces queries
type Token_secure = actor {
  ext_extensions_secure : shared () -> async [Extension];
  
  ext_metadata_secure: shared (token : TokenIdentifier) -> async Result<Metadata, CommonError>;

  ext_supply_secure: shared (token : TokenIdentifier) -> async Result<Balance, CommonError>;
  
  ext_balance_secure: shared (request : BalanceRequest) -> async BalanceResponse;
};
