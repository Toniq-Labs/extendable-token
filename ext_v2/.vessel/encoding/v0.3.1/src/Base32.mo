import Array "mo:base/Array";
import Array_ "mo:array/Array";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Debug "mo:base/Debug";

module Base32 {
    private let encodeStd = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    private let encodeMap : [Nat8] = [
        65, 66, 67, 68, 69, 70, 71, 72,
        73, 74, 75, 76, 77, 78, 79, 80,
        81, 82, 83, 84, 85, 86, 87, 88,
        89, 90, 50, 51, 52, 53, 54, 55,
    ];

    // public func encodeMap() : [Nat8] {
    //     Array.map<Char, Nat8>(
    //         Iter.toArray(encodeStd.chars()),
    //         func (c : Char) : Nat8 {
    //             Nat8.fromNat(Nat32.toNat(Char.toNat32(c)));
    //         },
    //     );
    // };

    private func encodeLen(n : Nat) : Nat {
        (n * 8 + 4) / 5;
    };

    public func encode(data : [Nat8]) : [Nat8] {
        if (data.size() == 0) { return []; };

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
                    encodeMap[Nat8.toNat(n & 31)];
                },
            );

            src := Array_.drop(src, 5);
            dst := Array.append(dst, bEnc);
        };
        Array_.take(dst, encodeLen(data.size()));
    };

    private let decodeMap : [Nat8] = [
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255,  26,  27,  28,  29,  30,  31, 255, 255, 255, 255, 255, 255, 255, 255,
        255,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  12, 13,  14,
         15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 255, 255, 255, 255, 255, 
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    ];

    // public func decodeMap() : [Nat8] {
    //     let map = Array.init<Nat8>(256, 0xFF);
    //     for (i in encodeMap.keys()) {
    //         map[Nat8.toNat(encodeMap[i])] := Nat8.fromNat(i);
    //     };
    //     Array.freeze(map);
    // };

    private func decodeLen(n : Nat) : Nat {
        n * 5 / 8;
    };

    public func decode(data : [Nat8]) : Result.Result<[Nat8], Text> {
        if (data.size() == 0) { return #ok([]); };

        var off = 0;
        var src = data;
        var dst = Array.init<Nat8>(decodeLen(data.size()), 0);
        while (src.size() > 0) {
            var b = Array.init<Nat8>(8, 0);
            var len = 8;
            label l for (i in Iter.range(0, 7)) {
                if (src.size() == 0) {
                    len := i; break l;
                };
                let s = src[0];
                src := Array_.drop(src, 1);
                b[i] := decodeMap[Nat8.toNat(s)];
                if (b[i] == 0xFF) return #err("corrupt input");
            };
            if (len == 8) {
                dst[off+4] := b[6] << 5 | b[7];
            };
            if (len == 8 or len == 7) {
                dst[off+3] := b[4] << 7 | b[5] << 2 | b[6] >> 3;
            };
            if (len == 8 or len == 7 or len == 5) {
                dst[off+2] := b[3] << 4 | b[4] >> 1;
            };
            if (len == 8 or len == 7 or len == 5 or len == 4) {
                dst[off+1] := b[1] << 6 | b[2] << 1 | b[3] >> 4;
            };
            if (len == 8 or len == 7 or len == 5 or len == 4 or len == 2) {
                dst[off+0] := b[0] << 3 | b[1] >> 2;
            };
            off += 5;
        };
        #ok(Array.freeze(dst));
    };
};
