//Provide a common interface between ICP ledger and ext-core
//This allows for instant support by exchanges
//TODO: work on this

type AccountBalanceArgs = { 
  account : AccountIdentifier;
  token : TokenIdentifier; 
};
type ICPTs = { e8s : Nat64 };
type BlockHeight = Nat64;
type SendArgs = {
  to : AccountIdentifier;
  fee : ICPTs;
  memo : Nat64;
  from_subaccount : ?SubAccount;
  created_at_time : ?{ timestamp_nanos : Nat64 };
  amount : ICPTs;
  token : TokenIdentifier;
};

type Token_ledger = actor actor {
  account_balance_dfx : shared query AccountBalanceArgs -> async ICPTs;
  send_dfx : shared SendArgs -> async BlockHeight;
}