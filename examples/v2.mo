import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Int8 "mo:base/Int8";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Random "mo:base/Random";
import Array "mo:base/Array";
import Option "mo:base/Option";
import AID "../motoko/util/AccountIdentifier";
import ExtCore "../motoko/ext/Core";
import ExtCommon "../motoko/ext/Common";
import ExtAllowance "../motoko/ext/Allowance";
import ExtNonFungible "../motoko/ext/NonFungible";

import Int64 "mo:base/Int64";
import List "mo:base/List";
import Encoding "mo:encoding/Binary";
//Cap
import Cap "mo:cap/Cap";
import Queue "../motoko/util/Queue";
import EXTAsset "extAsset";

actor class EXTNFT(init_owner: Principal) = this {
  
  // EXT Types
  type EXTAssetService = EXTAsset.EXTAsset;
  type Order = {#less; #equal; #greater};
  type Time = Time.Time;
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type TokenIndex  = ExtCore.TokenIndex ;
  type Extension = ExtCore.Extension;
  type CommonError = ExtCore.CommonError;
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  type AllowanceRequest = ExtAllowance.AllowanceRequest;
  type ApproveRequest = ExtAllowance.ApproveRequest;
  type MetadataLegacy = ExtCommon.Metadata;
  type NotifyService = ExtCore.NotifyService;
  type MintingRequest = {
    to : AccountIdentifier;
    asset : Nat32;
  };
  
  type MetadataValue = (Text , {
    #text : Text;
    #blob : Blob;
    #nat : Nat;
    #nat8: Nat8;
  });
  type MetadataContainer = {
      #data : [MetadataValue];
      #blob : Blob;
      #json : Text;
  };
  type Metadata = {
    #fungible : {
      name : Text;
      symbol : Text;
      decimals : Nat8;
      metadata: ?MetadataContainer;
    };
    #nonfungible : {
      name : Text;
      asset : Text;
      thumbnail : Text;
      metadata: ?MetadataContainer;
    };
  };
  
  //Marketplace
  type Transaction = {
    token : TokenIndex;
    seller : AccountIdentifier;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };
  type Listing = {
    seller : Principal;
    price : Nat64;
    locked : ?Time;
  };
  type ListRequest = {
    token : TokenIdentifier;
    from_subaccount : ?SubAccount;
    price : ?Nat64;
  };
  
  //LEDGER
  type AccountBalanceArgs = { account : AccountIdentifier };
  type ICPTs = { e8s : Nat64 };
  type SendArgs = {
    memo: Nat64;
    amount: ICPTs;
    fee: ICPTs;
    from_subaccount: ?SubAccount;
    to: AccountIdentifier;
    created_at_time: ?Time;
  };
  
  //Cap
  type CapDetailValue = {
    #I64 : Int64;
    #U64 : Nat64;
    #Vec : [CapDetailValue];
    #Slice : [Nat8];
    #Text : Text;
    #True;
    #False;
    #Float : Float;
    #Principal : Principal;
  };
  type CapEvent = {
    time : Nat64;
    operation : Text;
    details : [(Text, CapDetailValue)];
    caller : Principal;
  };
  type CapIndefiniteEvent = {
    operation : Text;
    details : [(Text, CapDetailValue)];
    caller : Principal;
  };
  
  //Sale
  type PaymentType = {
    #sale : Nat64;
    #nft : TokenIndex;
    #nfts : [TokenIndex];
  };
  type Payment = {
    purchase : PaymentType;
    amount : Nat64;
    subaccount : SubAccount;
    payer : AccountIdentifier;
    expires : Time;
  };
  
  //EXTv2 Asset Handling
  type AssetHandle = Text;
  type AssetId = Nat32;
  type ChunkId = Nat32;
  type AssetType = {
    #canister : {
      id : AssetId;
      canister : Text;
    };
    #direct : [ChunkId];
    #other : Text;
  };
  type Asset = {
    ctype : Text;
    filename : Text;
    atype : AssetType;
  };
  
  //HTTP
  type HeaderField = (Text, Text);
  type HttpResponse = {
    status_code: Nat16;
    headers: [HeaderField];
    body: Blob;
    streaming_strategy: ?HttpStreamingStrategy;
  };
  type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
  };
  type HttpStreamingCallbackToken =  {
    content_encoding: Text;
    index: Nat;
    key: Text;
    sha256: ?Blob;
  };
  type HttpStreamingStrategy = {
    #Callback: {
        callback: query (HttpStreamingCallbackToken) -> async (HttpStreamingCallbackResponse);
        token: HttpStreamingCallbackToken;
    };
  };
  type HttpStreamingCallbackResponse = {
    body: Blob;
    token: ?HttpStreamingCallbackToken;
  };
 
  //Stable State
  private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/nonfungible"];
  private stable var data_disbursementQueueState : [(TokenIndex, AccountIdentifier, SubAccount, Nat64)] = [];
  private stable var data_capEventsQueueState : [CapIndefiniteEvent] = [];
  private stable var data_registryTableState : [(TokenIndex, AccountIdentifier)] = [];
  private stable var data_ownersTableState : [(AccountIdentifier, [TokenIndex])] = [];
	private stable var data_assetsTableState : [(AssetHandle, Asset)] = [];
	private stable var data_assetCanistersTableState : [(Principal, Nat)] = [];
	private stable var data_chunksTableState : [(ChunkId, Blob)] = [];
	private stable var data_tokenMetadataTableState : [(TokenIndex, Metadata)] = [];
	private stable var data_tokenListingTableState : [(TokenIndex, Listing)] = [];
  private stable var data_paymentSettlementsTableState : [(AccountIdentifier, Payment)] = [];
  private stable var data_internalRunHeartbeat : Bool = true;
  private stable var data_supply : Balance  = 0;
	private stable var data_transactions : [Transaction] = [];
  private stable var data_internalNextTokenId : TokenIndex  = 0;
  private stable var data_internalNextChunkId : ChunkId  = 0;
  private stable var data_internalNextSubAccount : Nat = 0;
  private stable var data_storedChunkSize : Nat = 0;

  
  //CAP
  private stable var cap_rootBucketId : ?Text = null;
  
  //CONFIG
  private stable var config_owner : Principal  = init_owner;
  private stable var config_admin : Principal  = config_owner;
  private stable var config_royalty_address : AccountIdentifier = AID.fromPrincipal(config_owner, null);
  private stable var config_royalty_fee : Nat64  = 3000;
  private stable var config_collection_name : Text  = "[PLEASE CHANGE]";
  private stable var config_collection_data : Text  = "{}";
  private stable var config_marketplace_open : Time  = 0;
  
  private stable var config_canCreateAssetCanister : Bool  = true;

  //Non-stable
  //Queues
  var _disbursements : Queue.Queue<(TokenIndex, AccountIdentifier, SubAccount, Nat64)> = Queue.fromArray(data_disbursementQueueState);
  var _capEvents : Queue.Queue<CapIndefiniteEvent> = Queue.fromArray(data_capEventsQueueState);
  //Tables
  var _registry : HashMap.HashMap<TokenIndex, AccountIdentifier> = HashMap.fromIter(data_registryTableState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
	var _owners : HashMap.HashMap<AccountIdentifier, [TokenIndex]> = HashMap.fromIter(data_ownersTableState.vals(), 0, AID.equal, AID.hash);
	var _assets : HashMap.HashMap<AssetHandle, Asset> = HashMap.fromIter(data_assetsTableState.vals(), 0, AID.equal, AID.hash);
	var _chunks : HashMap.HashMap<ChunkId, Blob> = HashMap.fromIter(data_chunksTableState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  var _assetCanisters : HashMap.HashMap<Principal, Nat> = HashMap.fromIter(data_assetCanistersTableState.vals(), 0, Principal.equal, Principal.hash);
  var _tokenMetadata : HashMap.HashMap<TokenIndex, Metadata> = HashMap.fromIter(data_tokenMetadataTableState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  var _tokenListing : HashMap.HashMap<TokenIndex, Listing> = HashMap.fromIter(data_tokenListingTableState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  var _paymentSettlements : HashMap.HashMap<AccountIdentifier, Payment> = HashMap.fromIter(data_paymentSettlementsTableState.vals(), 0, AID.equal, AID.hash);
  
  //Variables
  let ASSET_CANISTER_CYCLES_TOPUP : Nat = 5_000_000_000_000;
  let ASSET_CANISTER_MIN_CYCLES : Nat = 1_000_000_000_000;
  let MAX_CHUNK_STORAGE : Nat = 800000000;//800MB
  let ENTREPOT_MARKETPLACE_FEES_ADDRESS : AccountIdentifier = "c7e461041c0c5800a56b64bb7cefc247abc0bbbb99bd46ff71c64e92d9f5c2f9";
  let ENTREPOT_MARKETPLACE_FEES_AMOUNT : Nat64 = 1000;
  let HTTP_NOT_FOUND : HttpResponse = {status_code = 404; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
  let HTTP_BAD_REQUEST : HttpResponse = {status_code = 400; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
    
  //Services
  let ExternalService_Cap = Cap.Cap(?"lj532-6iaaa-aaaah-qcc7a-cai", cap_rootBucketId);
  let ExternalService_ICPLedger = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : actor { 
    send_dfx : shared SendArgs -> async Nat64;
    account_balance_dfx : shared query AccountBalanceArgs -> async ICPTs; 
  };
  
  //SYSTEM
  system func preupgrade() {
    data_registryTableState := Iter.toArray(_registry.entries());
    data_tokenMetadataTableState := Iter.toArray(_tokenMetadata.entries());
    data_ownersTableState := Iter.toArray(_owners.entries());
    data_tokenListingTableState := Iter.toArray(_tokenListing.entries());
    data_assetsTableState := Iter.toArray(_assets.entries());
    data_assetCanistersTableState := Iter.toArray(_assetCanisters.entries());
    data_paymentSettlementsTableState := Iter.toArray(_paymentSettlements.entries());
    data_disbursementQueueState := Queue.toArray(_disbursements);
    data_capEventsQueueState := Queue.toArray(_capEvents);
    
  };
  system func postupgrade() {
    data_registryTableState := [];
    data_tokenMetadataTableState := [];
    data_ownersTableState := [];
    data_tokenListingTableState := [];
    data_assetsTableState := [];
    data_assetCanistersTableState := [];
    data_paymentSettlementsTableState := [];
    data_disbursementQueueState := [];
    data_capEventsQueueState := [];
  };
  //Heartbeat: Removed for now, consumes too many cycles
  // system func heartbeat() : async () {
    // await heartbeat_external();
  // };
  
  //Heartbeat
  public shared(msg) func heartbeat_external() : async () {
    if (data_internalRunHeartbeat == true){
      try{
        await heartbeat_paymentSettlements();
        await heartbeat_disbursements();
        await heartbeat_capEvents();
        await heartbeat_assetCanisters();
      } catch(e){
        data_internalRunHeartbeat := false;
      };
    };
  };
  public shared(msg) func heartbeat_assetCanisters() : async () {
    if (Cycles.balance() < ASSET_CANISTER_CYCLES_TOPUP) return ();
    for((a,s) in _assetCanisters.entries()){
      var acService : EXTAssetService = actor(Principal.toText(a));
      var cycles : Nat = await acService.availableCycles();
      if (cycles < ASSET_CANISTER_MIN_CYCLES) {
        Cycles.add(ASSET_CANISTER_CYCLES_TOPUP);
        await acService.acceptCycles();        
      };
      if (Cycles.balance() < ASSET_CANISTER_CYCLES_TOPUP) return ();
    };
  };
  public shared(msg) func heartbeat_disbursements() : async () {
    while(Queue.size(_disbursements) > 0 and data_internalRunHeartbeat){
      var last = Queue.next(_disbursements);
      switch(last.0){
        case(?d) {
          _disbursements := last.1;
          try {
            var bh = await ExternalService_ICPLedger.send_dfx({
              memo = 0;
              amount = { e8s = d.3 };
              fee = { e8s = 10000 };
              from_subaccount = ?d.2;
              to = d.1;
              created_at_time = null;
            });
          } catch (e) {
            _disbursements := Queue.add(d, _disbursements);
          };
        };
        case(_) {};
      };
    };
  };
  public shared(msg) func heartbeat_paymentSettlements() : async () {
    for((paymentAddress, settlement) in _expiredPaymentSettlements().vals()){
      switch(settlement.purchase) {
        case(#nft t) ignore(ext_marketplaceSettle(paymentAddress));
        case(_) {};
      };
    };
  };
  public shared(msg) func heartbeat_capEvents() : async () {
    while(Queue.size(_capEvents) > 0 and data_internalRunHeartbeat){
      var last = Queue.next(_capEvents);
      switch(last.0){
        case(?event) {
          _capEvents := last.1;
          try {
            ignore await ExternalService_Cap.insert(event);
          } catch (e) {
            _capEvents := Queue.add(event, _capEvents);
          };
        };
        case(_) {};
      };
    };
  };
  public query func heartbeat_pending() : async [(Text,Nat)] {
    [
    ("Disbursements", Queue.size(_disbursements)),
    ("CAP Events", Queue.size(_capEvents)),
    ("Expired Payment Settlements", _expiredPaymentSettlements().size())
    ];
  };
  public query func heartbeat_isRunning() : async Bool {
    data_internalRunHeartbeat;
  };
  public shared(msg) func heartbeat_stop() : async () {
    assert(_isAdmin(msg.caller));
    data_internalRunHeartbeat := false;
  };
  public shared(msg) func heartbeat_start() : async () {
    assert(_isAdmin(msg.caller));
    data_internalRunHeartbeat := true;
  };
  public query func ext_assetFits(internal : Bool, size : Nat) : async Bool {
    if (internal) {
      if ((data_storedChunkSize+size) < MAX_CHUNK_STORAGE) {
        return true;
      } else {
        return false;
      };
    } else {
      Option.isSome(_getFreeAssetCanister(size));
    };
  };
  public query func ext_assetExists(assetHandle : AssetHandle) : async Bool {
    Option.isSome(_assets.get(assetHandle));
  };
  public shared(msg) func ext_assetAdd(assetHandle : AssetHandle, ctype : Text, filename : Text, atype : AssetType, size : Nat) : async () {
    await _ext_internal_assetAdd(msg.caller, assetHandle, ctype, filename, atype, size);
  };
  public shared(msg) func ext_assetStream(assetHandle : AssetHandle, chunk : Blob, first : Bool) : async Bool {
    assert(_isAdmin(msg.caller));
    let size = Blob.toArray(chunk).size();
    switch(_assets.get(assetHandle)) {
      case(?asset) {
        switch(asset.atype){
          case(#direct existingChunks){
            assert((data_storedChunkSize+size) < MAX_CHUNK_STORAGE);
            let chunkId = data_internalNextChunkId;
            data_internalNextChunkId+=1;
            _chunks.put(chunkId, chunk);
            var newChunks : [Nat32] = [chunkId];
            if (first == true) {
              _deleteChunksForAssetHandle(assetHandle);
            } else {
              newChunks := Array.append(existingChunks, newChunks);
            };             
            data_storedChunkSize += size;
            _assets.put(assetHandle, {
              ctype = asset.ctype;
              filename = asset.filename;
              atype = #direct(newChunks);
            });
          };
          case(#canister d) {
            //Forward to external canister
            switch(_assetCanisters.get(Principal.fromText(d.canister))){
              case(?currentSize) {
                let acService : EXTAssetService = actor(d.canister);
                _assetCanisters.put(Principal.fromText(d.canister), currentSize+size);
                return await acService.streamAsset(d.id, chunk, first);
              };
              case(_){};
            };
          };
          case(_){};
        };
      };
      case(_) return false;
    };
    return true;
  };
  
  //TODO DB query
  //transactions, registry 
  // public query func ext_select(type : DataType, sort : ?DataSortFunction, filter : ?DataFilterFunction) : (DataTypeResponse, Pagination){
    
  // }
  //EXT Standard
  //Management
  public shared(msg) func ext_setOwner(p: Principal) : async () {
    assert(_isOwner(msg.caller));
    config_owner := p;
  };
  public shared(msg) func ext_setAdmin(p: Principal) : async () {
    assert(_isOwner(msg.caller) or _isAdmin(msg.caller));
    config_admin := p;
  };
  public shared(msg) func ext_setRoyalty(address : AccountIdentifier, fee : Nat64) : async () {
    assert(_isAdmin(msg.caller));
    config_royalty_address := address;
    config_royalty_fee := fee;
  };
  public shared(msg) func ext_addAssetCanister() : async () {
    assert(_isAdmin(msg.caller));
    await _createAssetCanister();
  };
  public shared(msg) func ext_setCollectionMetadata(name : Text, metadata : Text) : async () {
    assert(_isAdmin(msg.caller));
    config_collection_name := name;
    config_collection_data := metadata;
  };
  public shared(msg) func ext_setMarketplaceOpen(mpo : Time) : async () {
    assert(_isAdmin(msg.caller));
    config_marketplace_open := mpo;
  };
  
  public query func ext_admin() : async Principal {
    config_admin;
  };
  public query func ext_extensions() : async [Extension] {
    EXTENSIONS;
  };
  public query func ext_balance(request : BalanceRequest) : async BalanceResponse {
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    let aid = ExtCore.User.toAID(request.user);
    switch (_registry.get(token)) {
      case (?token_owner) {
				if (AID.equal(aid, token_owner) == true) {
					return #ok(1);
				} else {					
					return #ok(0);
				};
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
	public query func ext_bearer(token : TokenIdentifier) : async Result.Result<AccountIdentifier, CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_getBearer(tokenind)) {
      case (?token_owner) {
				return #ok(token_owner);
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
	};
  public query func extdata_supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(data_supply);
  };
  public query func ext_metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    _ext_internalMetadata(token);
  };
  public query func ext_expired() : async [(AccountIdentifier, SubAccount)] {
    data_expiredPayments;
  };
  public query func ext_payments() : async [(AccountIdentifier, Payment)] {
    Iter.toArray(_paymentSettlements.entries());
  };
  public shared(msg) func ext_removeAdmin() : async () {
    assert(_isOwner(msg.caller) or _isAdmin(msg.caller));
    config_admin := config_owner;
  };
  public shared(msg) func ext_transfer(request: TransferRequest) : async TransferResponse {
    await _ext_internal_transfer(msg.caller, request);
  };
  public shared(msg) func ext_mint(request : [(AccountIdentifier, Metadata)]) : async [TokenIndex] {
    assert(_isAdmin(msg.caller));
    var ret : [TokenIndex] = [];
    for(r in request.vals()){
      _tokenMetadata.put(data_internalNextTokenId, r.1);
      _transferTokenToUser(data_internalNextTokenId, r.0);
      data_supply := data_supply + 1;
      ret := Array.append(ret, [data_internalNextTokenId]);
      data_internalNextTokenId := data_internalNextTokenId + 1;
    };
    ret;
  };
  
  //Marketplace
  public shared(msg) func ext_marketplaceList(request: ListRequest) : async Result.Result<(), CommonError> {
    await _ext_internal_marketplaceList(msg.caller, request);
  };
  public shared(msg) func ext_marketplacePurchase(tokenid : TokenIdentifier, price : Nat64, buyer : AccountIdentifier) : async Result.Result<(AccountIdentifier, Nat64), CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(tokenid, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(tokenid));
		};
		let token = ExtCore.TokenIdentifier.getIndex(tokenid);
		switch(_tokenListing.get(token)) {
			case (?listing) {
        if (listing.price != price) {
          return #err(#Other("Price has changed!"));
        } else {
          return #ok(_ext_addPayment(#nft(token), price, buyer), price);
        };
			};
			case (_) {
				return #err(#Other("No listing!"));				
			};
		};
  };
  public shared(msg) func ext_marketplaceSettle(paymentaddress : AccountIdentifier) : async Result.Result<(), CommonError> {
    switch(await _ext_checkPayment(paymentaddress)) {
      case(?(settlement, response)){
        switch(response){
          case(#ok ledgerResponse) {
            switch(settlement.purchase){
              case(#nft token) {
                switch(_tokenListing.get(token)) {
                  case (?listing) {
                    if (settlement.amount >= listing.price) {
                      switch (_registry.get(token)) {
                        case (?token_owner) {
                          var bal : Nat64 = settlement.amount - (10000 * Nat64.fromNat(_marketplaceFees().size() + 1));
                          var rem = bal;
                          for(f in _marketplaceFees().vals()){
                            var _fee : Nat64 = bal * f.1 / 100000;
                            _addDisbursement((token, f.0, settlement.subaccount, _fee));
                            rem := rem -  _fee : Nat64;
                          };
                          _addDisbursement((token, token_owner, settlement.subaccount, rem));
                          _capAddSale(token, token_owner, settlement.payer, settlement.amount);
                          _transferTokenToUser(token, settlement.payer);
                          data_transactions := Array.append(data_transactions, [{
                            token = token;
                            seller = token_owner;
                            price = settlement.amount;
                            buyer = settlement.payer;
                            time = Time.now();
                          }]);
                          _tokenListing.delete(token);
                          _paymentSettlements.delete(paymentaddress);
                          return #ok();
                        };
                        case (_) {};
                      };
                    };
                  };
                  case (_) {};
                };
                //If we are here, that means we need to refund the payment
                //No listing, refund (too slow)	
                _addDisbursement((0, settlement.payer, settlement.subaccount, (ledgerResponse.e8s-10000)));
                _paymentSettlements.delete(paymentaddress);
                return #err(#Other("NFT not for sale"));	
              };
              case(_) return #err(#Other("Not a payment for a single NFT"));
            };
          };
          case(#err e) return #err(#Other(e));
        };
      };
      case(_) return #err(#Other("Nothing to settle"));
    };
  };
  public query func ext_marketplaceListings() : async [(TokenIndex, Listing, Metadata)] {
    _ext_internalMarketplaceListings();
  };
  public query func ext_marketplaceTransactions() : async [Transaction] {
    data_transactions;
  };
  public query func ext_marketplaceStats() : async (Nat64, Nat64, Nat64, Nat64, Nat, Nat, Nat) {
    _ext_internalStats();
  };
  public shared(msg) func ext_capInit() : async () {
    if (Option.isNull(cap_rootBucketId)){
      try {
        cap_rootBucketId := await ExternalService_Cap.handshake(Principal.toText(Principal.fromActor(this)), 1_000_000_000_000);
      } catch e {};
    };
  };
  //HTTP Views
  public query func http_request(request : HttpRequest) : async HttpResponse {
    switch(_getParam(request.url, "tokenid")) {
      case (?tokenid) {
        switch(_getTokenIndex(tokenid)) {
          case (?index) {
            switch(_getParam(request.url, "type")) {
              case(?t) {
                if (t == "thumbnail") {
                  return _ext_httpTokenThumbnail(index);
                };
              };
              case(_) {};
            };
            return _ext_httpToken(index);
          };
          case (_){};
        };
      };
      case (_){};
    };
    switch(_getParam(request.url, "index")) {
      case (?i) {
        let index = _textToNat32(i);
        switch(_getParam(request.url, "type")) {
          case(?t) {
            if (t == "thumbnail") {
              return _ext_httpTokenThumbnail(index);
            };
          };
          case(_) {};
        };
        return _ext_httpToken(index);
      };
      case (_){};
    };
    switch(_getParam(request.url, "asset")) {
      case (?ah) {
        return _ext_httpAsset(ah)
      };
      case (_){};
    };
    return _ext_httpHome();
  };
  public query func http_request_streaming_callback(token : HttpStreamingCallbackToken) : async HttpStreamingCallbackResponse {
    let handle = token.key;
    switch(_assets.get(handle)){
      case(?asset) {
        switch(asset.atype){
          case(#direct chunks) {            
            let res = _streamContent(handle, chunks, token.index);
            return {
              body = res.0;
              token = res.1;
            };
          };
          case(_) return {body = Blob.fromArray([]); token = null};
        };
      };
      case null return {body = Blob.fromArray([]); token = null};
    };
  };
  
  //Internal cycle management - good general case
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };
  
  //Private
  func _createAssetCanister() : async () {
    Cycles.add(ASSET_CANISTER_CYCLES_TOPUP);
    config_canCreateAssetCanister := false;
    try{
      let b = await EXTAsset.EXTAsset();
      config_canCreateAssetCanister := true;
      let newp = Principal.fromActor(b);
      _assetCanisters.put(newp, 0);
    } catch (e) {
      config_canCreateAssetCanister := true;
      assert(false);
    };
  };
  func _getFreeAssetCanister(size : Nat) : ?(Principal, Nat) {
    Array.find<(Principal, Nat)>(Array.sort<(Principal, Nat)>(Iter.toArray(_assetCanisters.entries()), func(a : (Principal, Nat), b : (Principal, Nat)) : Order {
      if (a.1 < b.1) {
        return #less;
      };
      if (a.1 > b.1) {
        return #greater;
      };
      return #equal;
    }), func(a : (Principal, Nat)) : Bool {
      return (a.1+size) < MAX_CHUNK_STORAGE;
    });
  };
  func _marketplaceFees() : [(AccountIdentifier, Nat64)] {
    [
      (config_royalty_address, config_royalty_fee),
      (ENTREPOT_MARKETPLACE_FEES_ADDRESS, ENTREPOT_MARKETPLACE_FEES_AMOUNT),
    ]
  };
  func _ext_httpHome() : HttpResponse {
    var soldValue : Nat = Nat64.toNat(Array.foldLeft<Transaction, Nat64>(data_transactions, 0, func (b : Nat64, a : Transaction) : Nat64 { b + a.price }));
    var avg : Nat = if (data_transactions.size() > 0) {
      soldValue/data_transactions.size();
    } else {
      0;
    };
    return {
      status_code = 200;
      headers = [("content-type", "text/plain")];
      body = Text.encodeUtf8 (
        config_collection_name # "\n" #
        "---\n" #
        "Cycle Balance:                            ~" # debug_show(Cycles.balance()/1000000000000) # "T\n" #
        "Minted NFTs:                              " # debug_show(data_internalNextTokenId) # "\n" #
        "Assets:                                   " # debug_show(_assets.size()) # "\n" #
        "Chunks:                                   " # debug_show(_chunks.size()) # "\n" #
        "Storage:                                  " # debug_show(data_storedChunkSize) # "/" # debug_show(MAX_CHUNK_STORAGE) # "\n" #
        "---\n" #
        "Marketplace Listings:                     " # debug_show(_tokenListing.size()) # "\n" #
        "Sold via Marketplace:                     " # debug_show(data_transactions.size()) # "\n" #
        "Sold via Marketplace in ICP:              " # _displayICP(soldValue) # "\n" #
        "Average Price ICP Via Marketplace:        " # _displayICP(avg) # "\n" #
        "---\n" #
        "Royalty Address:                          " # config_royalty_address # "\n" #
        "Royalty Amount:                           " # debug_show(config_royalty_fee) # "\n" #
        "---\n" #
        "Admin:                                    " # debug_show(config_admin) # "\n" #
        "Owner:                                    " # debug_show(config_owner) # "\n"
      );
      streaming_strategy = null;
    };
  };
  func _ext_httpTokenThumbnail(token : TokenIndex) : HttpResponse {
    switch(_tokenMetadata.get(token)){
      case(?md) {
        switch(md){
          case(#fungible _) HTTP_NOT_FOUND;
          case(#nonfungible nmd) {
            if (nmd.thumbnail == "") return HTTP_NOT_FOUND;
            _ext_httpAsset(nmd.thumbnail);
          };
        };
      };
      case(_) HTTP_NOT_FOUND;
    };
  };
  func _ext_httpToken(token : TokenIndex) : HttpResponse {
    switch(_tokenMetadata.get(token)){
      case(?md) {
        switch(md){
          case(#fungible _) HTTP_NOT_FOUND;
          case(#nonfungible nmd) {
            if (nmd.asset == "") return HTTP_NOT_FOUND;
            _ext_httpAsset(nmd.asset);
          };
        };
      };
      case(_) HTTP_NOT_FOUND;
    };
  };
  func _ext_httpAsset(handle : AssetHandle) : HttpResponse {
    switch(_assets.get(handle)){
      case(?asset){        
        switch(asset.atype) {
          case(#direct chunks) _ext_httpOutputAsset(handle, asset, chunks);
          case(#canister a) _ext_httpExternalDisplay(asset, "https://"#a.canister#".raw.ic0.app/?index="#Nat32.toText(a.id));
          case(#other url) _ext_httpExternalDisplay(asset, url);
        };
      };
      case(_) HTTP_NOT_FOUND;
    };
  };
  func _ext_httpExternalDisplay(asset : Asset, url : Text) : HttpResponse {
    if (Text.startsWith(asset.ctype, #text("image/"))) {
      return {
        status_code = 200;
        headers = [("content-type", "image/svg+xml")];
        body = Text.encodeUtf8 ("<svg width=\"1000\" height=\"1000\" xmlns=\"http://www.w3.org/2000/svg\"><image href=\""#url#"\" width=\"1000\" height=\"1000\"/></svg>");
        streaming_strategy = null;
      };
    };
    return {
      status_code = 200;
      headers = [("content-type", "text/html")];
      body = Text.encodeUtf8 ("<!DOCTYPE html><html><head><meta charset=\"UTF-8\" /><meta http-equiv=\"refresh\" content=\"0; URL="#url#"\" /></head><body></body></html>");
      streaming_strategy = null;
    };
  };
  func _ext_httpOutputAsset(handle : AssetHandle, asset : Asset, chunks : [ChunkId]) : HttpResponse {
    if (chunks.size() > 1 ) {
      let (payload, token) = _streamContent(handle, chunks, 0);
      return {
        status_code = 200;
        headers = [("Content-Type", asset.ctype), ("cache-control", "public, max-age=15552000")];
        body = payload;
        streaming_strategy = ?#Callback({
          token = Option.unwrap(token);
          callback = http_request_streaming_callback;
        });
      };
    } else {
      switch(_chunks.get(chunks[0])) {
        case(?chunk) {          
          return {
            status_code = 200;
            headers = [("content-type", asset.ctype), ("cache-control", "public, max-age=15552000")];
            body = chunk;
            streaming_strategy = null;
          };
        };
        case(_) return HTTP_NOT_FOUND;
      };
    };
  };
  func _streamContent(handle : AssetHandle, chunks : [ChunkId], idx : Nat) : (Blob, ?HttpStreamingCallbackToken) {
    let nextChunkId = chunks[idx];
    let chunkSize = chunks.size();
    let payload = Option.unwrap(_chunks.get(nextChunkId));
    if (idx + 1 == chunkSize) {
        return (payload, null);
    };
    return (payload, ?{
      content_encoding = "gzip";
      index = idx + 1;
      sha256 = null;
      key = handle;
    });
  };
  func _deleteChunksForAssetHandle(assetHandle : AssetHandle) : () {
    switch(_assets.get(assetHandle)) {
      case(?asset) {
        switch(asset.atype){
          case(#direct existingChunks){
            for(cid in existingChunks.vals()){
              switch(_chunks.get(cid)){
                case(?b) {
                  let size = Blob.toArray(b).size();
                  if (data_storedChunkSize > size){                    
                    data_storedChunkSize -= size;
                  } else {
                    data_storedChunkSize := 0;
                  };
                  _chunks.delete(cid);
                };
                case(_) {};
              };
            };
          };
          case(_){};
        };
      };
      case(_){};
    };
  };
  func _ext_checkPayment(paymentaddress : AccountIdentifier) : async ?(Payment, Result.Result<ICPTs, Text>) {
    switch(_paymentSettlements.get(paymentaddress)) {
      case(?settlement){
        let response : ICPTs = await ExternalService_ICPLedger.account_balance_dfx({account = paymentaddress});
        switch(_paymentSettlements.get(paymentaddress)) {
          case(?settlement){
            if (response.e8s >= settlement.amount){
              return ?(settlement, #ok(response));
            } else {
              if (settlement.expires < Time.now()) {
                data_expiredPayments := Array.append(data_expiredPayments, [(settlement.payer, settlement.subaccount)]);
                _paymentSettlements.delete(paymentaddress);
                return ?(settlement, #err("Expired"));
              } else {
                return ?(settlement, #err("Insufficient funds sent"));
              }
            };
          };
          case(_) return null;
        };
      };
      case(_) return null;
    };
  };
  func _ext_addPayment(purchase : PaymentType, amount : Nat64, payer : AccountIdentifier) : AccountIdentifier {
    let subaccount = _getNextSubAccount();
    let paymentAddress : AccountIdentifier = AID.fromPrincipal(Principal.fromActor(this), ?subaccount);
    _paymentSettlements.put(paymentAddress, {
      purchase = purchase;
      amount = amount;
      subaccount = subaccount;
      payer = payer;
      expires = (Time.now() + (2* 60 * 1_000_000_000));
    });
    paymentAddress;
  };
  func _isOwner(p : Principal) : Bool {
    return (p == config_owner);
  };
  func _isAdmin(p : Principal) : Bool {
    return (p == config_admin);
  };
  func _expiredPaymentSettlements() : [(AccountIdentifier, Payment)] {
    Array.filter<(AccountIdentifier, Payment)>(Iter.toArray(_paymentSettlements.entries()), func(a : (AccountIdentifier, Payment)) : Bool { 
      return (a.1.expires < Time.now());
    });
  };
  func _natToSubAccount(n : Nat) : SubAccount {
    let n_byte = func(i : Nat) : Nat8 {
        assert(i < 32);
        let shift : Nat = 8 * (32 - 1 - i);
        Nat8.fromIntWrap(n / 2**shift)
    };
    Array.tabulate<Nat8>(32, n_byte)
  };
  func _getNextSubAccount() : SubAccount {
    var _saOffset = 4294967296;
    data_internalNextSubAccount += 1;
    return _natToSubAccount(_saOffset+data_internalNextSubAccount);
  };
  func _addDisbursement(d : (TokenIndex, AccountIdentifier, SubAccount, Nat64)) : () {
    _disbursements := Queue.add(d, _disbursements);
  };
  func _capAddTransfer(token : TokenIndex, from : AccountIdentifier, to : AccountIdentifier) : () {
    let event : CapIndefiniteEvent = {
      operation = "transfer";
      details = [
        ("to", #Text(to)),
        ("from", #Text(from)),
        ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
        ("balance", #U64(1)),
      ];
      caller = Principal.fromActor(this);
    };
    _capAdd(event);
  };
  func _capAddSale(token : TokenIndex, from : AccountIdentifier, to : AccountIdentifier, amount : Nat64) : () {
    let event : CapIndefiniteEvent = {
      operation = "sale";
      details = [
        ("to", #Text(to)),
        ("from", #Text(from)),
        ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
        ("balance", #U64(1)),
        ("price_decimals", #U64(8)),
        ("price_currency", #Text("ICP")),
        ("price", #U64(amount)),
      ];
      caller = Principal.fromActor(this);
    };
    _capAdd(event);
  };
  func _capAddMint(token : TokenIndex, from : AccountIdentifier, to : AccountIdentifier, amount : ?Nat64) : () {
    let event : CapIndefiniteEvent = switch(amount) {
      case(?a) {
        {
          operation = "mint";
          details = [
            ("to", #Text(to)),
            ("from", #Text(from)),
            ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
            ("balance", #U64(1)),
            ("price_decimals", #U64(8)),
            ("price_currency", #Text("ICP")),
            ("price", #U64(a)),
          ];
          caller = Principal.fromActor(this);
        };
      };
      case(_) {
        {
          operation = "mint";
          details = [
            ("to", #Text(to)),
            ("from", #Text(from)),
            ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
            ("balance", #U64(1)),
          ];
          caller = Principal.fromActor(this);
        };
      };
    };
    _capAdd(event);
  };
  func _capAdd(event : CapIndefiniteEvent) : () {
    _capEvents := Queue.add(event, _capEvents);
  };
  func _getTokenIndex(token : Text) : ?TokenIndex {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
      return null;
    };
    let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    return ?tokenind;
  };
  func _getParam(url : Text, param : Text) : ?Text {
    var _s : Text = url;
    Iter.iterate<Text>(Text.split(_s, #text("/")), func(x, _i) {
      _s := x;
    });
    Iter.iterate<Text>(Text.split(_s, #text("?")), func(x, _i) {
      if (_i == 1) _s := x;
    });
    var t : ?Text = null;
    var found : Bool = false;
    Iter.iterate<Text>(Text.split(_s, #text("&")), func(x, _i) {
      if (found == false) {
        Iter.iterate<Text>(Text.split(x, #text("=")), func(y, _ii) {
          if (_ii == 0) {
            if (Text.equal(y, param)) found := true;
          } else if (found == true) t := ?y;
        });
      };
    });
    return t;
  };
  func _textToNat32(t : Text) : Nat32 {
    var reversed : [Nat32] = [];
    for(c in t.chars()) {
      assert(Char.isDigit(c));
      reversed := Array.append([Char.toNat32(c)-48], reversed);
    };
    var total : Nat32 = 0;
    var place : Nat32  = 1;
    for(v in reversed.vals()) {
      total += (v * place);
      place := place * 10;
    };
    total;
  };
  func _removeTokenFromUser(tindex : TokenIndex) : () {
    let owner : ?AccountIdentifier = _getBearer(tindex);
    _registry.delete(tindex);
    switch(owner){
      case (?o) _removeFromUserTokens(tindex, o);
      case (_) {};
    };
  };
  func _transferTokenToUser(tindex : TokenIndex, receiver : AccountIdentifier) : () {
    let owner : ?AccountIdentifier = _getBearer(tindex);
    _registry.put(tindex, receiver);
    switch(owner){
      case (?o) _removeFromUserTokens(tindex, o);
      case (_) {};
    };
    _addToUserTokens(tindex, receiver);
  };
  func _removeFromUserTokens(tindex : TokenIndex, owner : AccountIdentifier) : () {
    switch(_owners.get(owner)) {
      case(?ownersTokens) _owners.put(owner, Array.filter(ownersTokens, func (a : TokenIndex) : Bool { (a != tindex) }));
      case(_) ();
    };
  };
  func _addToUserTokens(tindex : TokenIndex, receiver : AccountIdentifier) : () {
    let ownersTokensNew : [TokenIndex] = switch(_owners.get(receiver)) {
      case(?ownersTokens) Array.append(ownersTokens, [tindex]);
      case(_) [tindex];
    };
    _owners.put(receiver, ownersTokensNew);
  };
  func _getBearer(tindex : TokenIndex) : ?AccountIdentifier {
    _registry.get(tindex);
  };
  func _displayICP(amt : Nat) : Text {
    debug_show(amt/100000000) # "." # debug_show ((amt%100000000)/1000000) # " ICP";
  };
  func _blobToNat32(b : Blob) : Nat32 {
    var index : Nat32 = 0;
    Array.foldRight<Nat8, Nat32>(Blob.toArray(b), 0, func (u8, accum) {
      index += 1;
      accum + Nat32.fromNat(Nat8.toNat(u8)) << ((index-1) * 8);
    });
  };
  func _convertToLegacyMetadataWithKey(kv :(TokenIndex, Metadata)) : MetadataLegacy {
    _convertToLegacyMetadata(kv.1);
  };
  func _convertToLegacyMetadata(md : Metadata) : MetadataLegacy {
    switch(md){
      case(#nonfungible b) {
        switch(b.metadata){
          case(?c) {
            switch(c){
              case(#blob d) {
                return return #nonfungible({metadata = ?d});
              };
              case(_) return #nonfungible({metadata = null});
            };
          };
          case(_) return #nonfungible({metadata = null});
        };
      };
      case(_) return #nonfungible({metadata = null});
    };
  };
  func _ext_internalStats() : (Nat64, Nat64, Nat64, Nat64, Nat, Nat, Nat) {
    var res : (Nat64, Nat64, Nat64) = Array.foldLeft<Transaction, (Nat64, Nat64, Nat64)>(data_transactions, (0,0,0), func (b : (Nat64, Nat64, Nat64), a : Transaction) : (Nat64, Nat64, Nat64) {
      var total : Nat64 = b.0 + a.price;
      var high : Nat64 = b.1;
      var low : Nat64 = b.2;
      if (high == 0 or a.price > high) high := a.price; 
      if (low == 0 or a.price < low) low := a.price; 
      (total, high, low);
    });
    var floor : Nat64 = 0;
    for (a in _tokenListing.entries()){
      if (floor == 0 or a.1.price < floor) floor := a.1.price;
    };
    (res.0, res.1, res.2, floor, _tokenListing.size(), _registry.size(), data_transactions.size());
  };
  
  func _ext_internalMarketplaceListings() : [(TokenIndex, Listing, Metadata)] {
    var results : [(TokenIndex, Listing, Metadata)] = [];
    for(a in _tokenListing.entries()) {
      results := Array.append(results, [(a.0, a.1, Option.unwrap(_tokenMetadata.get(a.0)))]);
    };
    results;
  };
  func _ext_internalMetadata(token : TokenIdentifier) : Result.Result<Metadata, CommonError> {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_tokenMetadata.get(tokenind)) {
      case (?token_metadata) {
				return #ok(token_metadata);
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
  };
  
  
  //Internal legacy
  func _ext_internal_assetAdd(caller : Principal, assetHandle : AssetHandle, ctype : Text, filename : Text, atype : AssetType, size : Nat) : async () {
    assert(_isAdmin(caller));
    switch(atype){
      case(#direct _) {
        _assets.put(assetHandle, {
          ctype = ctype;
          filename = filename;
          atype = atype;
        });        
      };
      case(#other _) {
        _assets.put(assetHandle, {
          ctype = ctype;
          filename = filename;
          atype = atype;
        });
      };
      case(#canister d) {
        if (d.canister == "") {
          //We need to auto generate an asset canister for this asset
          let t = switch(_getFreeAssetCanister(size)) {
            case(?a) a;
            case(_){
              await _createAssetCanister();
              Option.unwrap(_getFreeAssetCanister(size));
            };
          };
          let acService : EXTAssetService = actor(Principal.toText(t.0));
          let aid : Nat32 = await acService.addAsset(ctype, filename);
          _assets.put(assetHandle, {
            ctype = ctype;
            filename = filename;
            atype = #canister({
              canister = Principal.toText(t.0);
              id = aid;
            });
          });
        } else {
          _assets.put(assetHandle, {
            ctype = ctype;
            filename = filename;
            atype = atype;
          });
        };
      };
    };
  };
  func _ext_internal_marketplaceList(caller : Principal, request: ListRequest) : async Result.Result<(), CommonError> {
    if (Time.now() < config_marketplace_open) {
      if (_saleEnded() == false){
        return #err(#Other("You can not list yet"));
      };
    };
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    let owner = AID.fromPrincipal(caller, request.from_subaccount);
    switch (_registry.get(token)) {
      case (?token_owner) {
				if(AID.equal(owner, token_owner) == false) {
					return #err(#Other("Not authorized"));
				};
        switch(request.price) {
          case(?price) {
            _tokenListing.put(token, {
              seller = caller;
              price = price;
              locked = null;
            });
          };
          case(_) {
            _tokenListing.delete(token);
          };
        };
        return #ok;
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
  func _ext_internal_transfer(caller : Principal, request: TransferRequest) : async TransferResponse {
    if (request.amount != 1) {
			return #err(#Other("Must use amount of 1"));
		};
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    if (Option.isSome(_tokenListing.get(token))) {
			return #err(#Other("This token is currently listed for sale!"));
    };
    let owner = ExtCore.User.toAID(request.from);
    let spender = AID.fromPrincipal(caller, request.subaccount);
    let receiver = ExtCore.User.toAID(request.to);
		if (AID.equal(owner, spender) == false) {
      return #err(#Unauthorized(spender));
    };
    switch (_registry.get(token)) {
      case (?token_owner) {
				if(AID.equal(owner, token_owner) == false) {
					return #err(#Unauthorized(owner));
				};
        if (request.notify) {
          switch(ExtCore.User.toPrincipal(request.to)) {
            case (?canisterId) {
              //Do this to avoid atomicity issue
              _removeTokenFromUser(token);
              let notifier : NotifyService = actor(Principal.toText(canisterId));
              switch(await notifier.tokenTransferNotification(request.token, request.from, request.amount, request.memo)) {
                case (?balance) {
                  if (balance == 1) {
                    _transferTokenToUser(token, receiver);
                    _capAddTransfer(token, owner, receiver);
                    return #ok(request.amount);
                  } else {
                    //Refund
                    _transferTokenToUser(token, owner);
                    return #err(#Rejected);
                  };
                };
                case (_) {
                  //Refund
                  _transferTokenToUser(token, owner);
                  return #err(#Rejected);
                };
              };
            };
            case (_) {
              return #err(#CannotNotify(receiver));
            }
          };
        } else {
          _transferTokenToUser(token, receiver);
          _capAddTransfer(token, owner, receiver);
          return #ok(request.amount);
        };
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
  //Legacy
  public query func failedSales() : async [(AccountIdentifier, SubAccount)] {
    data_expiredPayments;
  };
  public shared(msg) func setMinter(minter : Principal) : async () {
    assert(_isOwner(msg.caller) or _isAdmin(msg.caller));
    config_admin := minter;
  };
  public shared(msg) func addThumbnail(handle : AssetHandle, data : Blob) : async () {
    await _ext_internal_assetAdd(msg.caller, handle, "image/png", handle, #direct([]) : AssetType, 0);
    ignore(await ext_assetStream(handle, data, true));
  };
  public shared(msg) func addAsset(handle : AssetHandle, id : Nat32, ctype : Text, name : Text, canister : Text) : async () {
    await _ext_internal_assetAdd(msg.caller, handle, ctype, name, #canister({
      id = id;
      canister = canister;
    }) : AssetType, 0);
  };
  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    await _ext_internal_transfer(msg.caller, request);
  };
  public shared(msg) func lock(tokenid : TokenIdentifier, price : Nat64, address : AccountIdentifier, _subaccountNOTUSED : SubAccount) : async Result.Result<AccountIdentifier, CommonError> {
    switch(await ext_marketplacePurchase(tokenid, price, address)){
      case(#ok p) return #ok(p.0);
      case(#err e) return #err(e);
    };
  };
  public shared(msg) func settle(tokenid : TokenIdentifier) : async Result.Result<(), CommonError> {
    switch(Array.find(Iter.toArray(_paymentSettlements.entries()), func(a : (AccountIdentifier, Payment)) : Bool {
      switch(a.1.purchase){
        case(#nft t) {
          return (t == ExtCore.TokenIdentifier.getIndex(tokenid));
        };
        case(_){};
      };
      return false;
    })){
      case(?a) {
        return await ext_marketplaceSettle(a.0);
      };
      case(_){};
    };
    return #ok;
  };
  public shared(msg) func list(request: ListRequest) : async Result.Result<(), CommonError> {
    await _ext_internal_marketplaceList(msg.caller, request);
  };
  public query func getMinter() : async Principal {
    config_admin;
  };
  public query func extensions() : async [Extension] {
    EXTENSIONS;
  };
  public query func balance(request : BalanceRequest) : async BalanceResponse {
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    let aid = ExtCore.User.toAID(request.user);
    switch (_registry.get(token)) {
      case (?token_owner) {
				if (AID.equal(aid, token_owner) == true) {
					return #ok(1);
				} else {					
					return #ok(0);
				};
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
  public query func bearer(token : TokenIdentifier) : async Result.Result<AccountIdentifier, CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_getBearer(tokenind)) {
      case (?token_owner) {
				return #ok(token_owner);
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
  };
  public query func supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(data_supply);
  };
  public query func getRegistry() : async [(TokenIndex, AccountIdentifier)] {
    Iter.toArray(_registry.entries());
  };
  public query func getMetadata() : async [(TokenIndex, MetadataLegacy)] {
    Iter.toArray(HashMap.map<TokenIndex, Metadata, MetadataLegacy>(_tokenMetadata, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash, func (a : (TokenIndex, Metadata)) : MetadataLegacy {
      _convertToLegacyMetadata(a.1);
    }).entries());
  };
  public query func getTokens() : async [(TokenIndex, MetadataLegacy)] {
    Iter.toArray(HashMap.map<TokenIndex, Metadata, MetadataLegacy>(_tokenMetadata, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash, func (a : (TokenIndex, Metadata)) : MetadataLegacy {
      #nonfungible({metadata = null})
    }).entries());
  };
  public query func tokens(aid : AccountIdentifier) : async Result.Result<[TokenIndex], CommonError> {
    switch(_owners.get(aid)) {
      case(?tokens) return #ok(tokens);
      case(_) return #err(#Other("No tokens"));
    };
  };
  public query func tokens_ext(aid : AccountIdentifier) : async Result.Result<[(TokenIndex, ?Listing, ?Blob)], CommonError> {
    switch(_owners.get(aid)) {
      case(?tokens) {
        var resp : [(TokenIndex, ?Listing, ?Blob)] = [];
        for (a in tokens.vals()){
          resp := Array.append(resp, [(a, _tokenListing.get(a), null)]);
        };
        return #ok(resp);
      };
      case(_) return #err(#Other("No tokens"));
    };
  };
  public query func metadata(token : TokenIdentifier) : async Result.Result<MetadataLegacy, CommonError> {
    switch(_ext_internalMetadata(token)){
      case(#ok a) {
        #ok(_convertToLegacyMetadata(a));
      };
      case(#err e) return #err(e);
    };
  };
  public query func details(token : TokenIdentifier) : async Result.Result<(AccountIdentifier, ?Listing), CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_getBearer(tokenind)) {
      case (?token_owner) {
				return #ok((token_owner, _tokenListing.get(tokenind)));
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
	};
  public query func transactions() : async [Transaction] {
    data_transactions;
  };
  public query func settlements() : async [(TokenIndex, AccountIdentifier, Nat64)] {
    return [];//No more settlements
  };
  public query func listings() : async [(TokenIndex, Listing, MetadataLegacy)] {
    Array.map<(TokenIndex, Listing, Metadata),(TokenIndex, Listing, MetadataLegacy)>(_ext_internalMarketplaceListings(), func(a : (TokenIndex, Listing, Metadata)) : (TokenIndex, Listing, MetadataLegacy) {
      (a.0, a.1, _convertToLegacyMetadata(a.2));
    });
  };
  public query(msg) func allSettlements() : async [(TokenIndex, {
    seller : Principal;
    price : Nat64;
    subaccount : SubAccount;
    buyer : AccountIdentifier;
  })] {
    [];
  };
  public query func stats() : async (Nat64, Nat64, Nat64, Nat64, Nat, Nat, Nat) {
    _ext_internalStats();
  };
  public shared(msg) func adminKillHeartbeat() : async () {
    await heartbeat_stop();
  };
  public shared(msg) func adminStartHeartbeat() : async () {
    await heartbeat_start();
  };
  public query func isHeartbeatRunning() : async Bool {
    data_internalRunHeartbeat;
  };
}
