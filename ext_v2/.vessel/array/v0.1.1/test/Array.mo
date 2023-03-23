import Nat "mo:base/Nat";

import Array "../src/Array";

let xs : [Nat] = [1, 2, 3];
for (x in xs.vals()) {
    assert(Array.contains<Nat>(xs, x, Nat.equal));
    assert(not Array.contains<Nat>(xs, x + 3, Nat.equal));
};

assert(Array.drop<Nat>(xs, 0) == xs);
assert(Array.drop<Nat>(xs, 1) == [2, 3]);
assert(Array.drop<Nat>(xs, 2) == [3]);
assert(Array.drop<Nat>(xs, 3) == []);
assert(Array.drop<Nat>(xs, 9) == []);

assert(Array.take<Nat>(xs, 0) == []);
assert(Array.take<Nat>(xs, 1) == [1]);
assert(Array.take<Nat>(xs, 2) == [1, 2]);
assert(Array.take<Nat>(xs, 3) == xs);
assert(Array.take<Nat>(xs, 9) == xs);

assert(Array.split<Nat>(xs, 0) == (xs, []));
assert(Array.split<Nat>(xs, 1) == ([1], [2, 3]));
assert(Array.split<Nat>(xs, 2) == ([1, 2], [3]));
assert(Array.split<Nat>(xs, 3) == ([], xs));
assert(Array.split<Nat>(xs, 9) == ([], xs));
