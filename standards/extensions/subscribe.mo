//Subscribe - support a subscription model for notifications
type Callback = shared (TokenIdentifier, User, Balance, ?Memo) -> async ?Balance;

type Token_subscribe = actor {
  subscribe: shared (callback : Callback) -> ();

  unsubscribe : shared () -> ();
};