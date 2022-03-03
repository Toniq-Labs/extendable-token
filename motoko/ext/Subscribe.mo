/**

 */
import ExtCore "./Core";
module ExtSubscribe = {

  public type ValidActor = actor {
    ext_subscribe: shared (callback : ExtCore.NotifyCallback) -> ();
    ext_unsubscribe : shared () -> ();
  };
};