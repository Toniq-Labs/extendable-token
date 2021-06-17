/**

 */
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
//TODO pull in better
import AID "../util/AccountIdentifier";
import Hex "../util/Hex";
import CRC32 "../util/CRC32";

module ExtCore = {
  public type AccountIdentifier = AID.AccountIdentifier;
  public type SubAccount = AID.SubAccount;
  public type User = {
    #address : AccountIdentifier; //No notification
    #principal : Principal; //defaults to sub account 0
  };
  public type Balance = Nat;
  public type TokenIdentifier  = Text;
  public type TokenIndex = Nat32;
  public type Extension = Text;
  public type Memo = Blob;
  public type NotifyService = actor { tokenTransferNotification : shared (TokenIdentifier, User, Balance, Memo) -> async ?Balance};
  public type CommonError = {
    #InvalidToken: TokenIdentifier;
    #Other : Text;
  };
  public type BalanceRequest = { 
    user : User; 
    token: TokenIdentifier;
  };
  public type BalanceResponse = Result.Result<Balance, CommonError>;

  public type TransferRequest = {
    from : User;
    to : User;
    token : TokenIdentifier;
    amount : Balance;
    memo : Memo;
    notify : Bool;
    subaccount : ?SubAccount;
  };
  public type TransferResponse = Result.Result<Balance, {
    #Unauthorized: AccountIdentifier;
    #InsufficientBalance;
    #Rejected; //Rejected by canister
    #InvalidToken: TokenIdentifier;
    #CannotNotify: AccountIdentifier;
    #Other : Text;
  }>;
  module TokenIdentifier = {
    private let tds : [Nat8] = [10, 116, 105, 100]; //b"\x0Atid"
    
    let equal = Text.equal;
    let hash = Text.hash;
    
    func fromText(t : Text, i : TokenIndex) : TokenIdentifier {
      return fromPrincipal(Principal.fromText(t), i);
    };
    func fromPrincipal(p : Principal, i : TokenIndex) : TokenIdentifier {
      return fromBlob(Principal.toBlob(p), i);
    };
    func fromBlob(b : Blob, i : TokenIndex) : TokenIdentifier {
      return fromBytes(Blob.toArray(b), i);
    };
    func fromBytes(c : [Nat8], i : TokenIndex) : TokenIdentifier {
      let bytes : [Nat8] = Array.append(Array.append(tds, c), nat32tobytes(i));
      let crc : [Nat8] = CRC32.crc32(bytes);
      return Hex.encode(Array.append(crc, bytes));
    };
    //Coz can't get principal directly, we can compare the bytes
    func isPrincipal(tid : TokenIdentifier, p : Principal) : Bool {
      let d = decode(tid);
      return Blob.equal(Blob.fromArray(d.0), Principal.toBlob(p));
    };
    func getIndex(tid : TokenIdentifier) : TokenIndex {
      let d = decode(tid);
      d.1;
    };
    func decode(tid : TokenIdentifier) : ([Nat8], TokenIndex) {
      let bytes = Hex.decode(tid);
      var index : Nat8 = 0;
      var len : Nat8 = 0;
      var ti : [Nat8] = [];
      var ca : [Nat8] = [];
      for (b in bytes.vals()) {
        index += 1;
        if (index == 10) {
          len := b;
        } else if (index > 10) {
          if (index <= (10 + len)) {
            ti := Array.append(ti, [b]);
          } else {
            ca := Array.append(ca, [b]);
          };
        };
      };
      //Can't get principal from bytes?
      return (ca, bytestonat32(ti));
    };
    
    private func bytestonat32(b : [Nat8]) : Nat32 {
      var index : Nat8 = 0;
      Array.foldRight<Nat8, Nat32>(b, 0, func (u8, accum) {
        index += 1;
        accum + Nat32.fromNat( Nat8.toNat( u8 << ( (index-1) * 8) ));
      });
    };
    private func nat32tobytes(n : Nat32) : [Nat8] {
      if (n < 256) {
        return [1, Nat8.fromNat(Nat32.toNat(n))];
      } else if (n < 65536) {
        return [
          2,
          Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)), 
          Nat8.fromNat(Nat32.toNat((n) & 0xFF))
        ];
      } else if (n < 16777216) {
        return [
          3,
          Nat8.fromNat(Nat32.toNat((n >> 16) & 0xFF)), 
          Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)), 
          Nat8.fromNat(Nat32.toNat((n) & 0xFF))
        ];
      } else {
        return [
          4,
          Nat8.fromNat(Nat32.toNat((n >> 24) & 0xFF)), 
          Nat8.fromNat(Nat32.toNat((n >> 16) & 0xFF)), 
          Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)), 
          Nat8.fromNat(Nat32.toNat((n) & 0xFF))
        ];
      };
    };
  };
  
  module User = {
    func equal(x : User, y : User) : Bool {
      let _x = switch(x) {
        case (#address address) address;
        case (#principal principal) {
          AID.fromPrincipal(principal, null);
        };
      };
      let _y = switch(y) {
        case (#address address) address;
        case (#principal principal) {
          AID.fromPrincipal(principal, null);
        };
      };
      return AID.equal(_x, _y);
    };
    func hash(x : User) : Hash.Hash {
      let _x = switch(x) {
        case (#address address) address;
        case (#principal principal) {
          AID.fromPrincipal(principal, null);
        };
      };
      return AID.hash(_x);
    };
  };
};