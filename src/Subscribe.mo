/**

 */
import ExtCore "./Core";
module ExtSubscribe = {

  public type ValidActor = actor {
    subscribe: shared (callback : ExtCore.NotifyCallback) -> ();

    unsubscribe : shared () -> ();
  };
};