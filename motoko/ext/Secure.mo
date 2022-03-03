/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
import ExtCommon "./Common";
module ExtSecure = {
  public type Service = actor {
    ext_extensions_secure: () -> async [ExtCore.Extension];
    
    ext_balance_secure: (request : ExtCore.BalanceRequest) -> async ExtCore.BalanceResponse;

    ext_metadata_secure: (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCommon.Metadata, ExtCore.CommonError>;
    
    ext_supply_secure: (token : ExtCore.TokenIdentifier) -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
  };
};