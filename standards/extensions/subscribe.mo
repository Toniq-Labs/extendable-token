//Subscribe - support a subscription model for notifications
type Token_subscribe = actor {
  ext_subscribe: shared (callback : NotifyCallback) -> ();

  ext_unsubscribe : shared () -> ();
};