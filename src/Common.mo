/**

 */
import Result "mo:base/Result";

import ExtCore "./Core";
module ExtCommon = {
  public type Metadata = {
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
  
  public type Service = actor {
    metadata: query (token : ExtCore.TokenIdentifier) -> async Result.Result<Metadata, ExtCore.CommonError>;

    supply: query (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
  };
};