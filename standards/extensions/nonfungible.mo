//NFT
type Token_nonfungible = actor {
  owner: shared query (token : TokenIdentifier) -> async Result<AccountIdentifier, CommonError>;
};
