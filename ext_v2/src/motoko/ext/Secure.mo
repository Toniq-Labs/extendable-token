/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
import ExtCommon "./Common";
module ExtSecure = {
  public type Service = actor {
    extensions_secure: () -> async [ExtCore.Extension];
    
    balance_secure: (request : ExtCore.BalanceRequest) -> async ExtCore.BalanceResponse;

    metadata_secure: (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCommon.Metadata, ExtCore.CommonError>;
    
    supply_secure: (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
  };
};