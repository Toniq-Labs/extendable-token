import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Prim "mo:⛔"; // Char.toLower();
import Principal "mo:base/Principal";

import Base32 "./base32";
import CRC32 "../CRC32";
import Util "./util"

module {
    public let fromText : (t : Text) -> Principal = Principal.fromText;

    public let toText : (p : Principal) -> Text = Principal.toText;

    public func fromBlob(b : Blob) : Principal {
        let bs  = Blob.toArray(b);
        let b32 = Base32.encode(Array.append<Nat8>(
            CRC32.crc32(bs), 
            bs,
        ));
        var id = "";
        for (i in b32.keys()) {
            let c = Prim.charToLower(Char.fromNat32(Util.nat8ToNat32(b32[i])));
            id #= Char.toText(c);
            if ((i + 1) % 5 == 0 and i + 1 != b32.size()) {
                id #= "-"
            }
        };
        Principal.fromText(id);
    };

    public let toBlob : (p : Principal) -> Blob = Principal.toBlob;
}
