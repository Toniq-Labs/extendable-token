//Common
// Metadata for either fungible of nft - may replace with single Blob
type Metadata = {
  #fungible : {
    name : Text;
    symbol : Text;
    decimals : Nat8;
    metadata : ?Blob;
  };
  #nonfungible : {
    metadata : ?Blob;
  };
};

type Token_common = actor {
  metadata: shared query (token : TokenIdentifier) -> async Result<Metadata, CommonError>;

  supply: shared query (token : TokenIdentifier) -> async Result<Balance, CommonError>;
};