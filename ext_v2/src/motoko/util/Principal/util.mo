import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";

module Util {
    public func nat8ToNat32(n : Nat8) : Nat32 {
        Nat32.fromNat(Nat8.toNat(n));
    };

    public func nat32ToNat8(n : Nat32) : Nat8 {
        Nat8.fromNat(Nat32.toNat(n) % 256);
    };

    public func nat32ToNat8Array(n : Nat32) : [Nat8] {
        [
            nat32ToNat8(n >> 24),
            nat32ToNat8(n >> 16),
            nat32ToNat8(n >> 8),
            nat32ToNat8(n),
        ];
    };

    public func drop<A>(xs : [A], n : Nat) : [A] {
        var ys : [A] = [];
        for (i in xs.keys()) {
            if (i >= n) {
                ys := Array.append(ys, [xs[i]])
            };
        };
        ys;
    };

    public func take<A>(xs : [A], n : Nat) : [A] {
        var ys = Array.init<A>(n, xs[0]);
        for (i in ys.keys()) {
            ys[i] := xs[i];
        };
        Array.freeze(ys);
    };
};
