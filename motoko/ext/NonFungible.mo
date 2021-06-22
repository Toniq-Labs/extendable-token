/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
module ExtNonFungible = {
  public type Service = actor {
    bearer: query (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.AccountIdentifier, ExtCore.CommonError>;
  };
};
