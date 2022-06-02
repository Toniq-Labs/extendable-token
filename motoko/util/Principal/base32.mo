import Array "mo:base/Array";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";

import Util "util";

module Base32 {
    private let encodeStd = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    private func encodeMap() : [Nat8] {
        Array.map<Char,Nat8>(
            Iter.toArray(Text.toIter(encodeStd)),
            func (c : Char) : Nat8 {
                Util.nat32ToNat8(Char.toNat32(c));
            },
        );
    };

    private func encodeLen(n : Nat) : Nat {
        (n * 8 + 4) / 5;
    };

    public func encode(data : [Nat8]) : [Nat8] {
        if (data.size() == 0) { return []; };

        let enc = encodeMap();
        var src = data;
        var dst : [Nat8] = [];
        while (src.size() > 0) {
            var b = Array.init<Nat8>(8, 0);
            let s = src.size();
            if (s >= 5) {
                b[7] := src[4] & 0x1F;
			    b[6] := src[4] >> 5;
            };
            if (s >= 4) {
                b[6] |= (src[3] << 3) & 0x1F;
			    b[5] := (src[3] >> 2) & 0x1F;
			    b[4] := src[3] >> 7;
            };
            if (s >= 3) {
                b[4] |= (src[2] << 1) & 0x1F;
			    b[3] := (src[2] >> 4) & 0x1F;
            };
            if (s >= 2) {
                b[3] |= (src[1] << 4) & 0x1F;
			    b[2] := (src[1] >> 1) & 0x1F;
			    b[1] := (src[1] >> 6) & 0x1F;
            };
            if (s >= 1) {
                b[1] |= (src[0] << 2) & 0x1F;
                b[0] := src[0] >> 3;
            };

            let bEnc = Array.map<Nat8,Nat8>(
                Array.filter<Nat8>(
                    Array.freeze(b),
                    func (n : Nat8) : Bool {
                        n < 32;
                    },
                ),
                func(n : Nat8) : Nat8 {
                    enc[Nat8.toNat(n & 31)];
                },
            );

            src := Util.drop(src, 5);
            dst := Array.append(dst, bEnc);
        };
        Util.take(dst, encodeLen(data.size()));
    }
};
