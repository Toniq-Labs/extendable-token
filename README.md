# EXT Standard - Core (ext-core)
## The extendable token standard

This token standard provides a ERC1155/multi-token-like approach with extensions that can add additional functionality based on the purpose of the token. EXT Standard allows for the following features:
1. Multiple tokens (which can be a mix, e.g. fungible and non-fungible) within a single canister. This provides better computation/gas savings and can reduce complexities.
2. `transferAndCall`-like approach for more streamlined usage (e.g. doesn't require allow + transferFrom to send to an exchange).
3. Supports both native addresses (64 long hex) and principals. Developer's can choose to reject one style and return an error if they wish.
4. EXT Standard provides a method to query a tokens capabilities to aid in deciding how to communicate with it.

You can view some of our extensions [here](EXTENSIONS.md).

## Rationale
Tokens can be used in a wide variety of circumstances, from cryptocurrency ledgers to in-game assets and more. These tokens can serve different purposes and therefore need to allow for a wide variety of functionalities. On the otherhand, 3rd party tools that need to integrate with tokens would benefit from a standardized interface.

EXT Standard promotes modular development of tokens using extensions and a common core. Token developers can developer their tokens based on their exact use case, and 3rd party developers can build tools around these tokens using the standarized interfaces.

## Interface Specification
The ext-core standard requires the following public entry points:

```
type Token = actor {
  extensions : shared query () -> async [Extension];
    
  balance: shared query (request : BalanceRequest) -> async BalanceResponse;
      
  transfer: shared (request : TransferRequest) -> async TransferResponse;
};
```

## Types
### Native addresses
```
type AccountIdentifier = Text;
type SubAccount = [Nat8];
```
Basic support for ICP Ledger `AccountIdentifier`'s and `SubAccount`'s.

### User
```
type User = {
  #address : AccountIdentifier;
  #principal : Principal;
}
```
EXT supports both native addresses (64 long hex addresses) and principal's. Developers can choose not to allow `AccountIdentifier`'s by returning an error if one is supplied.

### Balance
```
type Balance = Nat;
```
Balance refers to an amount of a particular `TokenIdentifier`. For the cases of non-fungible tokens, this would be `0` or `1`.

### TokenIdentifier
```
type TokenIdentifier  = {
  canister : Principal;
  index : Nat32;
};
```
The `TokenIdentifier` is a unique id for a particular token and reflects the canister where the token exists as well as the index within the tokens container within the provided canister. If a canister only holds a single token type, then this index would be 0.

We may change this TokenIdentifier into hex/text form for better handling via 3rd party tools.

### Extension
```
type Extension = Text;
```
Extensions are simply text fields, e.g. "batch", "common" and "archive".

### Memo
```
type Memo : Blob;
```
Represents a "payment" memo - data that can be transferred along with a transaction.

### NotifyService
```
type NotifyService = actor { tokenTransferNotification : shared (TokenIdentifier, User, Balance, ?Memo) -> async ?Balance)};
//e.g. (tokenId, from, amount, memo)
```
This is the public call that a canister must contain to receive a transfer notification.

### Common Error
```
type CommonError = {
  #InvalidToken: TokenIdentifier;
  #Other : Text;
};
```
The above represents a common error which can be returned.

## Entry Points

### extensions (query)
```
extensions : shared query () -> async [Extension];
```
Public query that returns an array of `Extension`s that the canister supports.

### balance (query)
```
type BalanceRequest = { 
  user : User; 
  token: TokenIdentifier;
};
type BalanceResponse = Result<Balance, CommonError>;

balance: shared query (request : BalanceRequest) -> async BalanceResponse;
```
Public query that returns the `Balance` of a requested `User`, otherwise an error if it fails.

### transfer
```
type TransferRequest = {
  from : User;
  to : User;
  token : TokenIdentifier;
  amount : Balance;
  memo : ?Memo;
  notify : ?Bool;
};
type TransferResponse = Result<Balance, {
  #Unauthorized;
  #InsufficientBalance;
  #Rejected; //Rejected by canister
  #InvalidToken: TokenIdentifier;
  #CannotNotify: AccountIdentifier;
  #Other : Text;
}>;

transfer: shared (request : TransferRequest) -> async TransferResponse;
```
This function attempts to transfer an `amount` of `token` between two users, `from` and `to` with an optional `memo` (which is additional data specific to the transaction).

If `notify` is `true`, the canister will attempt to notify the recipient of the transaction (for which a response must be returned). This gives the recipient the power to reject a transaction if they wish. The recipient can also choose to only accept a partial transfer of tokens. Any rejected tokens are refunded to the sender.
