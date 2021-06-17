//Subscribe - support a subscription model for notifications
type Token_subscribe = actor {
  subscribe: shared (callback : NotifyCallback) -> ();

  unsubscribe : shared () -> ();
};