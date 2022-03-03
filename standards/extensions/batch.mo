//Allow for batch calls
type BatchError = {
  #Error : Text;
};
type Token_allowance = actor {
  ext_balance_batch: query (request : [BalanceRequest]) -> async Result<[BalanceResponse], BatchError>;
      
  ext_transfer_batch: shared (request : [TransferRequest]) -> async Result<[TransferResponse], BatchError>;
};