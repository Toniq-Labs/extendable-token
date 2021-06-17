  //This actor acts as a minter - send ICP to this canister, notify it, and it will attempt to mint WTC
  //Also demonstrates converting cycles to WTC from within a canister
  //Recommend min to send is 1T cycles worth or 0.03ICP
  
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import AID "./util/AccountIdentifier";

actor WTCMinter {
  type ICPTs = { e8s : Nat64 };
  type SubAccount = [Nat8];
  type AccountIdentifier = Text;
  type Memo = Nat64;
  type BlockHeight = Nat64;
  type TimeStamp = { timestamp_nanos : Nat64 };
  type TransactionNotification = {
    to : Principal;
    to_subaccount : ?SubAccount;
    from : Principal;
    memo : Memo;
    from_subaccount : ?SubAccount;
    amount : ICPTs;
    block_height : BlockHeight;
  };
  type NotifyCanisterArgs = {
    to_subaccount : ?SubAccount;
    from_subaccount : ?SubAccount;
    to_canister : Principal;
    max_fee : ICPTs;
    block_height : BlockHeight;
  };
  type SendArgs = {
    to : AccountIdentifier;
    fee : ICPTs;
    memo : Memo;
    from_subaccount : ?SubAccount;
    created_at_time : ?TimeStamp;
    amount : ICPTs;
  };
  type MintProcess = {
    principal : Principal;
    cyclesAtStart : Nat;
    blockHeight : BlockHeight;
  };
  type User = {
    #address : AccountIdentifier; //No notification
    #principal : Principal; //defaults to sub account 0
  };
  type WTCService = actor { mint : shared ?User -> async() };
  type LedgerService = actor { 
    notify_dfx : shared NotifyCanisterArgs -> async ();
    send_dfx : shared SendArgs -> async BlockHeight;
  };
  type Result = { #Ok; #Err : Text };
  
  private let LEDGER : Text = "ryjl3-tyaaa-aaaaa-aaaba-cai";
  private let CYCLES_MINTER : Text = "rkp4c-7iaaa-aaaaa-aaaca-cai";
  private let WTC_TOKEN : Text = "5ymop-yyaaa-aaaah-qaa4q-cai";
  
  private let MINFEE : ICPTs = { e8s = 10000}; //0.0001ICP
  private let MIN_AMOUNT : Nat64 = 120000; //0.001ICP + 2x fee == 0.0012
  private let MINT_MEMO : Memo = 1347768404; //0.001ICP?
  private let MINT_FEE : Nat = 1_000_000_000; //0.001T?
  
  private stable var _mintProcess : ?MintProcess = null;
  private stable var _transactions : [TransactionNotification] = [];
  private stable var _errors : [Text] = [];
  
  //Transaction Notification from the ledger canister
  public shared(msg) func transaction_notification(tn : TransactionNotification) : async Result {
    _transactions := Array.append(_transactions, [tn]);
    assert(msg.caller == Principal.fromText(LEDGER));
    assert(tn.to == Principal.fromActor(WTCMinter));
    switch(_mintProcess) {
      case (?mp){
        _errors := Array.append(_errors, ["1"]);
        return #Err("Frozen.... you need to notify again...");
      };
      case (_) {
        if(tn.amount.e8s <= MIN_AMOUNT) {
          _errors := Array.append(_errors, ["2"]);
          return #Err("Not enough sent to convert and pay for fees.... no refunds sorry");
        };
        
        //Freeze here, store cycles amount and mint the delta afterwards
        //This means that users buring cycles using the minter have to pay for all computation
        //There is no fee for minting other than those impossed by the ledger canister
        let cyclesAtStart : Nat = Cycles.balance();
        _mintProcess := ?{
          principal = tn.from;
          cyclesAtStart = cyclesAtStart;
          blockHeight = 0;
        };

        let ls : LedgerService = actor(LEDGER);
        let tosub : SubAccount = _cycles_subaccount(tn.to);
        
        //Have to remove the fee from the amount to forward... x 2
        let convertAmount = tn.amount.e8s - (MINFEE.e8s * 2);
        
        //send ICP to minting canister
        let bh : BlockHeight = await ls.send_dfx({
          to = AID.fromText(CYCLES_MINTER, ?tosub);
          fee = MINFEE;
          memo = MINT_MEMO;
          from_subaccount = tn.from_subaccount;
          created_at_time = null;
          amount = { e8s = convertAmount };
        });
        _mintProcess := ?{
          principal = tn.from;
          cyclesAtStart = cyclesAtStart;
          blockHeight = bh;
        };
        //notify minting canister
        await ls.notify_dfx({
          to_subaccount = ?tosub;
          from_subaccount = tn.from_subaccount;
          to_canister = Principal.fromText(CYCLES_MINTER);
          max_fee = MINFEE;
          block_height = bh;
        });
        //If we are here I believe we have succeded?
        if (cyclesAtStart < Cycles.balance()){
          //Get out
          
          _errors := Array.append(_errors, ["3"]);
          return #Err("Cycles exhausted");
        } else {
          let newCycles : Nat = cyclesAtStart - Cycles.balance();
          //Minus fee and forward to WTC canister
          if (newCycles < MINT_FEE) {
            //Quit here - maybe min amount should be higher?
            
            _errors := Array.append(_errors, ["4"]);
            return #Err("Not enough to cover mint fee + computation");
          } else {
            let ws : WTCService = actor(WTC_TOKEN);
            Cycles.add(newCycles - MINT_FEE);
            await ws.mint(?#principal(tn.from)); 
            _mintProcess := null;
            
            _errors := Array.append(_errors, ["5"]);
            return #Ok;
          };
        };
      };
    };
  };
  public query func getErrors() : async [Text] {
    _errors;
  };
  public query func getTns() : async [TransactionNotification] {
    _transactions;
  };
  
  //Internal cycle management
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };

  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };
  
  private func _cycles_subaccount(p : Principal) : SubAccount {
    let pb : [Nat8] = Blob.toArray(Principal.toBlob(p));
    let len : Nat = Iter.size(pb.vals());
    var ret : [Nat8] = Array.append([Nat8.fromNat(len)], pb);
    return ret;
  };
}