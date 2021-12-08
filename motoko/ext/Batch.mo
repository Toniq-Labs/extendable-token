/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
module ExtBatch = {
  public type BatchError = {
    #Error : Text;
  };

  public type ValidActor = actor {
    ext_balance_batch: query (request : [ExtCore.BalanceRequest]) -> async Result.Result<[ExtCore.BalanceResponse], BatchError>;
        
    ext_transfer_batch: shared (request : [ExtCore.TransferRequest]) -> async Result.Result<[ExtCore.TransferResponse], BatchError>;
  };
};