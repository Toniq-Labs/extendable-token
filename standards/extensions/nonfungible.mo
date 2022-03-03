//NFT
type MintRequest = {
  to : User;
  metadata : ?Blob;
};
type Token_nonfungible = actor {
  ext_bearer: shared query (token : TokenIdentifier) -> async Result<AccountIdentifier, CommonError>;

  ext_mintNFT: shared (request : MintRequest) -> async ();
};
