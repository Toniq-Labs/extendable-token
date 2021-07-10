# EXT Standard
## The extendable token standard

This token standard provides a ERC1155/multi-token-like approach with extensions that can add additional functionality based on the purpose of the token. EXT Standard allows for the following features:
1. Multiple tokens (which can be a mix, e.g. fungible and non-fungible) within a single canister. This provides better computation/gas savings and can reduce complexities.
2. Bulit-in transfer notifications for more streamlined usage (e.g. similar to `transferAndCall`).
3. Supports both native `AccountIdentifier`s (64 long hex strings) and `Principal`s. EXT integrates well with both address styles making it easier for end users to interact with.
4. Extendable standard with a method to query a token's capabilities to aid in deciding how to communicate with it (better integration with 3rd party tools).
5. A unique `TokenIdentifier` is generated for each token with a canister (e.g. cnvzt-kikor-uwiaa-aaaaa-b4aah-eaqca-aaaaa-a) which is constructed using the canister ID and the token index within the canister. The canister ID can also be used which would point to the 0 index token (perfect if you have a single token like the [erc20 example](examples/erc20.mo))
6. WIP: Building a new core entrypoint named `exchange` to incorporate exchange mechanism directly into our core token standard

Here are some of the initial extensions we are working on:

* allowance - ERC20 like allowances
* archive - Transaction archive
* batch - Batch transfer/balance functions
* common - Some common token methods (metadata, supply)
* fee - A way to provide a standard fee
* ledger - ICP Ledger-like interface
* operator - Operator's for spending tokens
* secure - Add's update calls for common queries (more secure)
* subscribe - Provide interface for notification subscription

You can view more details [here](EXTENSIONS.md).

**Please comment, submit PRs, publish your own extensions and collaborate with us to build this standard.**

## Examples

We have a number of examples that you can use in the `examples` dirextory - all of these work with the EXT interface and can be added to a supporting wallet like Stoic:

* [ERC20](examples/erc20.md) - an ERC20-like standard that is very basic
* [ERC721](examples/erc721.md) - as per the above, except for NFTs specifically
* [Standard](examples/standard.md) - our standard single-token implementation with notifications
* [Advanced](examples/advanced.md) - our advanced multi-token implementation

## Rationale
Tokens can be used in a wide variety of circumstances, from cryptocurrency ledgers to in-game assets and more. These tokens can serve different purposes and therefore need to allow for a wide variety of functionalities. On the other hand, 3rd party tools that need to integrate with tokens would benefit from a standardized interface.

EXT Standard promotes modular development of tokens using extensions and a common core. Token developers can developer their tokens based on their exact use case, and 3rd party developers can build tools around these tokens using the standardized interfaces.

This repo contains our core standard and a number of initial extensions. We have added a full motoko library of these modules, and have provided some [examples](examples). We are also developing a basic JS library to easily integrate EXT with your applications.

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
### Native ICP Ledger types
```
type AccountIdentifier = Text;
type SubAccount = [Nat8];
```
Basic support for ICP Ledger `AccountIdentifier`s (64 long hex addresses) and `SubAccount`s (an index for a Principal).

### User
```
type User = {
  #address : AccountIdentifier;
  #principal : Principal;
}
```
EXT supports both native `AccountIdentifier`s (64 long hex addresses) and `Principal`s. EXT contains methods to check equality and generate a hash of a User. We advise storing balances against the AccountIdentifier as a Principal can be easily converted to one (using the default 0 index).

### Balance
```
type Balance = Nat;
```
Balance refers to an amount of a particular `TokenIdentifier`. For the cases of non-fungible tokens, this would be `0` or `1`.

### TokenIdentifier
```
// \x0Atid" + canisterId + 32 bit index
type TokenIdentifier  = Text;
```
The `TokenIdentifier` is a unique id for a particular token and reflects the canister where the token exists as well as the index within the tokens container. The TokenIdentifier is similar to a `Principal` and is a representation of the canister's ID, the index of the token within the canister, and a domain seperator.

### TokenIndex
```
type TokenIndex = Nat32;
```
This allows for 2\*\*32 unique tokens within a single canister (over 4 billion). This represents an individual token's index within a given canister.

### Extension
```
type Extension = Text;
```
Extensions are simply text fields, e.g. "batch", "common" and "archive".

### Memo
```
type Memo : Blob;
```
Represents a "payment" memo/data which can be attached to a transaction. We hope that we can utilize native serialization/deserialization to allow for more advanced data to be stored in this way.

### NotifyService
```
type NotifyCallback = shared (TokenIdentifier, User, Balance, Memo) -> async ?Balance;
type NotifyService = actor { tokenTransferNotification : NotifyCallback) -> async ?Balance)};
//e.g. (tokenId, from, amount, memo)
```
This is the public call that a canister must contain to receive a transfer notification. The amount returned is the balance actually accepted. If a transaction request has `notify` set to true but the receiver does not have the correct NotifyCallback then the tx is cancelled.

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
  subaccount : ?SubAccount;
};
type TransferResponse = Result<Balance, {
  #Unauthorized: AccountIdentifier;
  #InsufficientBalance;
  #Rejected; //Rejected by canister
  #InvalidToken: TokenIdentifier;
  #CannotNotify: AccountIdentifier;
  #Other : Text;
}>;

transfer: shared (request : TransferRequest) -> async TransferResponse;
```
This function attempts to transfer an `amount` of `token` between two users, `from` and `to`, with an optional `memo` (which is additional data specific to the transaction).

If `notify` is `true`, the canister will attempt to notify the recipient of the transaction (for which a response must be returned). This gives the recipient the power to reject a transaction if they wish. The recipient can also choose to only accept a partial transfer of tokens. Any rejected tokens are refunded to the sender.
