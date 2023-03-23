import List "mo:base/List";
//Based on https://github.com/o0x/motoko-queue/blob/master/src/Queue.mo
//Change enqueue/deqeue to add/next
module {
    type List<T> = List.List<T>;

    public type Queue<T> = (List<T>, List<T>);

    public func nil<T>() : Queue<T> { 
      (List.nil<T>(), List.nil<T>());
    };

    public func isEmpty<T>(q: Queue<T>) : Bool {
      switch (q) {
          case ((null, null)) true;
          case ( _ )          false;
      };
    };

    public func size<T>(q: Queue<T>) :  Nat {
      List.size(q.0) + List.size(q.1);
    };
    
    public func add<T>(v: T, q:Queue<T>) : Queue<T> {
      (?(v, q.0), q.1 );
    };

    public func next<T>(q:Queue<T>) : (?T, Queue<T>) {
      switch (q.1) {
        case (?(h, t)) {
          return ( ?h, (q.0, t) );
        };
        case null {
          switch (q.0) {
            case (?(h, t)) {
                let swapped = ( List.nil<T>(), List.reverse<T>(q.0) );
                return next<T>(swapped);
            };
            case null {
                return ( null, q );
            };
          };
        };
      };
    };
    
    //Additions
    public func fromArray<T>(a:[T]) : Queue<T> {
      (List.nil<T>(), List.fromArray<T>(a))
    };
    public func toArray<T>(q:Queue<T>) : [T] {
      List.toArray<T>(List.append<T>(q.1, List.reverse<T>(q.0)));
    };
};