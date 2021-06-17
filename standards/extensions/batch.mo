//Allow for batch calls
type BatchError = {
  #Error : Text;
};
type Token_allowance = actor {
  balance_batch: query (request : [BalanceRequest]) -> async Result<[BalanceResponse], BatchError>;
      
  transfer_batch: shared (request : [TransferRequest]) -> async Result<[TransferResponse], BatchError>;
};