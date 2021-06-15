# EXT Standard - Core (ext-core) - the extendable token standard

Find below the standard ext-core interface for an extendable token built on the Internet Computer. This token standard provides a ERC1155/multi-token-like approach with extensions that can add additional functionality based on the purpose of the token.

## Rationale
Tokens can be used in a wide variety of circumstances, from cryptocurrencies ledgers to in game assets and more. These tokens can serve different purposes and therefore need to allow for a wide variety of functionality. On the otherhand, 3rd party tools that need to integrate with tokens would benefit from a standardised interface.

Our Extended Token promotes modular development of tokens using standardised extensions (as well as our standardised core), providing developers with a more streamlined approach to development of the token ecosystem. We start with our base token standard `ext-core`, which can be extended using any of our standardised extensions.

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
