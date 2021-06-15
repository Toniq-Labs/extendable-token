//Allow for batch calls
//Do we fail if one fails? hm...
type Token_allowance = actor {
  balance_batch: shared query (request : [BalanceRequest]) -> async [BalanceResponse];
      
  transfer_batch: shared (request : [TransferRequest]) -> async [TransferResponse];
};