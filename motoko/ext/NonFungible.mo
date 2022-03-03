/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
module ExtNonFungible = {
  public type MintRequest = {
    to : ExtCore.User;
    metadata : ?Blob;
  };
  public type Service = actor {
    ext_bearer: query (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError>;

    ext_mintNFT: shared (request : MintRequest) -> async ();
  };
};
