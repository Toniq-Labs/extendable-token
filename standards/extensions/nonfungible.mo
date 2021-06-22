//NFT
type Token_nonfungible = actor {
  bearer: shared query (token : TokenIdentifier) -> async Result<AccountIdentifier, CommonError>;
};
