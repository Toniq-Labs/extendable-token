# Extendable Core (ext-core) Token Standard

Find below the standard ext-core interface for an extendable token built on the Internet Computer. This token standard provides a ERC1155/multi-token-like approach with extensions that can add additional functionality based on the purpose of the token.

## Rationale
We believe that IC tokens should have an efficient standard interface at it's core (ext-core), which can be extended in a standardized way to provide developers with a range of common interfaces to meet the needs of their tokens. Some other features include:
1. Transfer notifications via a `NotifyService` - this sends tx details to the receiver
2. 

## Interface Specification
The ic-fungible-token standard requires the following public entry points:

```
type Token = actor {
  extensions : shared query () -> async [Extension];
  
  metadata: shared query (tokenId : TokenId) -> async MetadataResponse;

  supply: shared query (tokenId : TokenId) -> async SupplyResponse;
    
  balance: shared query (request : BalanceRequest) -> async BalanceResponse;
      
  transfer: shared (request : TransferRequest) -> async TransferResponse;
};
```

## Types

### User
```
type User = Principal;
```

### Balance
```
type Balance = Nat;
```

### TokenId
```
type TokenId = Nat32;
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
