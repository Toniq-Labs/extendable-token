import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";

import Util "util";

module CRC32 {
    // Returns the CRC-32 checksum of data using the IEEE polynomial.
    // @pre: data.size() < 16
    public func checksum(data : [Nat8]) : Nat32 {
        slicingUpdate(0, slicingTable(), data);
    };

    private func simpleUpdate(crc : Nat32, table: [Nat32], data : [Nat8]) : Nat32 {
        var u = ^crc;
        for (v in data.vals()) {
            u := table[Nat8.toNat(Util.nat32ToNat8(u) ^ v)] ^ (u >> 8)
        };
        ^u;
    };

    private func slicingUpdate(crc : Nat32, table: [[Nat32]], data : [Nat8]) : Nat32 {
        if (data.size() == 0 ) { return crc;    };
        //if (data.size() >= 16) { assert(false); }; // Not supported.
        simpleUpdate(crc, table[0], data);
    };

    let IEEE : Nat32 = 0xedb88320;
    
    private func simpleTable() : [var Nat32] {
        let t = Array.init<Nat32>(256, 0);
        for (i in Iter.range(0, 255)) {
            var crc = Nat32.fromNat(i);
            for (_ in Iter.range(0, 7)) {
                if ((crc & 1) == 1) {
                    crc := (crc >> 1) ^ IEEE;
                } else {
                    crc >>= 1;
                };
            };
            t[i] := crc;
        };
        t;
    };

    private func slicingTable() : [[Nat32]] {
        var t = Array.init<[var Nat32]>(8, Array.init<Nat32>(256, 0));
        t[0] := simpleTable();
        for (i in Iter.range(0, 255)) {
            var crc = t[0][i];
            for (j in Iter.range(1, 7)) {
                crc := t[0][Nat32.toNat(crc & 0xFF)] ^ (crc >> 8);
                t[j][i] := crc;
            };
        };
        Array.tabulate(t.size(), func (i : Nat) : [Nat32] {
            Array.freeze(t[i]);
        });
    };
};
