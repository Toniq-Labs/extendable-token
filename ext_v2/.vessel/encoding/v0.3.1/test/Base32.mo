import Array "mo:base/Array";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";

import Base32 "../src/Base32";

import Debug "mo:base/Debug";

func arrayToText(xs : [Nat8]) : Text {
    Text.fromIter(Iter.fromArray(
        Array.map<Nat8, Char>(
            xs,
            func (n : Nat8) : Char {
                Char.fromNat32(Nat32.fromNat(Nat8.toNat(n)))
            },
        ),
    ));
};

func textToArray(t : Text) : [Nat8] {
    Array.map<Char, Nat8>(
        Iter.toArray(t.chars()),
        func (c : Char) : Nat8 {
            Nat8.fromNat(Nat32.toNat(Char.toNat32(c)));
        },
    );
};

assert (
    Base32.encode([102, 111, 111, 0, 98, 97, 114]) 
    == [77, 90, 88, 87, 54, 65, 68, 67, 77, 70, 90, 65]
); // "foo bar"

assert (
    Base32.decode([77, 90, 88, 87, 54, 65, 68, 67, 77, 70, 90, 65]) 
    == #ok([102, 111, 111, 0, 98, 97, 114])
); // "foo bar"

for ((text, encoded) in [
    ("", ""),
    ("f", "MY"),
    ("fo", "MZXQ"),
    ("foo", "MZXW6"),
    ("foo bar", "MZXW6IDCMFZA")
].vals()) {
    let e = Base32.encode(textToArray(text));
    assert(arrayToText(e) == encoded);
    switch (Base32.decode(e)) {
        case (#err(_)) { assert(false); };
        case (#ok(d)) { assert(arrayToText(d) == text); };
    };
};
