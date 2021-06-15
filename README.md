# EXT Standard - Core (ext-core)
## The extendable token standard

Find below the standard ext-core interface for an extendable token built on the Internet Computer. This token standard provides a ERC1155/multi-token-like approach with extensions that can add additional functionality based on the purpose of the token.

Our EXT standard allows for the following features:
1. Multiple tokens (which can be a mix, e.g. fungible and non-fungible) within a single canister. This provides better computation/gas savings and can reduce complexities. Developers can still create a single canister per token as well.
2. Notifications are built in - similar to `transferAndCall` allowing for better streamlined usage (e.g. doesn't require allow + transferFrom to send to an exchange).
3. Standard supports both native addresses (64 long hex) and principals. Developer's can choose to reject supporting one style and return an error.
4. Extendable standard with a core query call (extensions) to determine how to work with a particular canister.

## Rationale
Tokens can be used in a wide variety of circumstances, from cryptocurrency ledgers to in-game assets and more. These tokens can serve different purposes and therefore need to allow for a wide variety of functionalities. On the otherhand, 3rd party tools that need to integrate with tokens would benefit from a standardized interface.

Our Extended Token promotes modular development of tokens using extensions and a common base/core. This provides developers with a more streamlined approach regarding the token ecosystem. Token developers can extend their tokens based on their exact use case, and 3rd party developers can build tools around these tokens using the standarized interfaces. `ext-core` allows tools and canisters to query the token canister to determine what extensions are supported providing a way for tools to determine how they communicate with token canisters.

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

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```

### User
```
type User = Principal;
```
