import HashMap "mo:base/HashMap";

import Hex "../src/Hex";

let xs : [Nat8] = [255, 0];
let cs : Text   = "FF00";

assert(Hex.encode(xs) == cs);
switch (Hex.decode(cs)) {
    case (#ok(x))  assert(x == xs);
    case (#err(m)) assert(false);
};

switch (Hex.decode("FF0")) {
    case (#ok(x))  assert(x == [15, 240]);
    case (#err(m)) assert(false);
};

switch (Hex.decode("ff0")) {
    case (#ok(x))  assert(x == [15, 240]);
    case (#err(m)) assert(false);
};

assert(not Hex.valid("GG"));
assert(Hex.equal("FF0", "ff0"));

let m = HashMap.HashMap<Hex.Hex, Nat>(
    0, Hex.equal, Hex.hash,
);

m.put("FF0", 0);
m.put("ff0", 1);

assert(m.get("FF0") == ?1);
