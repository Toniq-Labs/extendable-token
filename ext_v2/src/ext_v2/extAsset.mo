import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Char "mo:base/Char";
import ExtCore "../motoko/ext/Core";

shared(msg) actor class EXTAsset() = this {
  
  public type Asset = {
    ctype : Text;
    filename : Text;
    chunks : [Nat32];
  };
  
  //State work
  private stable var _assetsState : [(Nat32, Asset)] = [];
  private stable var _chunksState : [(Nat32, Blob)] = [];
  private var _assets : HashMap.HashMap<Nat32, Asset> = HashMap.fromIter(_assetsState.vals(), 0, Nat32.equal, ExtCore.TokenIndex.hash);
  private var _chunks : HashMap.HashMap<Nat32, Blob> = HashMap.fromIter(_chunksState.vals(), 0, Nat32.equal, ExtCore.TokenIndex.hash);
  
  private stable var _nextAssetId : Nat32 = 0;
  private stable var _nextChunkId : Nat32 = 0;
  private stable var _owner : Principal  = msg.caller;
  
  system func preupgrade() {
    _assetsState := Iter.toArray(_assets.entries());
    _chunksState := Iter.toArray(_chunks.entries());
  };
  system func postupgrade() {
    _assetsState := [];
    _chunksState := [];
  };
  
  //Stream
  public shared(msg) func setMinter(minter : Principal) : async () {
		assert(msg.caller == _owner);
		_owner := minter;
	};
  public shared(msg) func addAsset(ctype : Text, filename : Text) : async Nat32 {
    assert(msg.caller == _owner);
    let assetId = _nextAssetId;
    _nextAssetId+=1;
    _assets.put(assetId, {
      ctype = ctype;
      filename = filename;
      chunks = [];
    });
    assetId;
  };
  public shared(msg) func streamAsset(assetId : Nat32, chunk : Blob, first : Bool) : async Bool {
    assert(msg.caller == _owner);
    switch(_assets.get(assetId)) {
      case(?asset) {
        let chunkId = _nextChunkId;
        _nextChunkId+=1;
        _chunks.put(chunkId, chunk);
        var newChunks : [Nat32] = [];
        if (first == true) {
          newChunks := [chunkId];
        } else {
          newChunks := Array.append(asset.chunks, [chunkId]);
        };
        _assets.put(assetId, {
          ctype = asset.ctype;
          filename = asset.filename;
          chunks = newChunks;
        });
      };
      case(_) return false;
    };
    return true;
  };
  public query func getAssetChunk(assetId : Nat32, index : Nat) : async ?(Text, Blob, Bool) {
    switch(_assets.get(assetId)) {
      case(?asset) {
        if (asset.chunks.size() > index) {        
          switch(_chunks.get(asset.chunks[index])){
            case(?chunk) {              
              var last : Bool = false;
              if ((index+1) == asset.chunks.size()) {
                last := true;
              };
              return ?(asset.ctype, chunk, last);
            };
            case(_) return null;
          };
        } else {
          return null;
        };
      };
      case(_) return null;
    };
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
  let NOT_FOUND : HttpResponse = {status_code = 404; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
  let BAD_REQUEST : HttpResponse = {status_code = 400; headers = []; body = Blob.fromArray([]); streaming_strategy = null};

  public query func http_request(request : HttpRequest) : async HttpResponse {
    let path = Iter.toArray(Text.tokens(request.url, #text("/")));
    switch(_getParam(request.url, "index")) {
      case (?assetIdText) {
        let assetId = _textToNat32(assetIdText);
        switch(_assets.get(assetId)){
          case(?asset) {
            return _processFile(assetId, asset)
          };
          case (_){};
        };
      };
      case (_){};
    };
    return {
      status_code = 200;
      headers = [("content-type", "text/plain")];
      body = Text.encodeUtf8 (
        "Cycle Balance:                            ~" # debug_show (Cycles.balance()/1000000000000) # "T\n" #
        "Assets:                                   " # debug_show (_assets.size()) # "\n"
      );
      streaming_strategy = null;
    };
  };
  public query func http_request_streaming_callback(token : HttpStreamingCallbackToken) : async HttpStreamingCallbackResponse {
    let assetId = _textToNat32(token.key);
    switch(_assets.get(assetId)){
      case(?asset) {
        let res = _streamContent(assetId, asset, token.index);
        return {
          body = res.0;
          token = res.1;
        };
      };
      case null return {body = Blob.fromArray([]); token = null};
    };
  };
  private func _textToNat32(t : Text) : Nat32 {
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
  private func _getParam(url : Text, param : Text) : ?Text {
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
  private func _processFile(assetId : Nat32, asset : Asset) : HttpResponse {
    if (asset.chunks.size() > 1 ) {
      let (payload, token) = _streamContent(assetId, asset, 0);
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
      return {
        status_code = 200;
        headers = [("content-type", asset.ctype), ("cache-control", "public, max-age=15552000")];
        body = Option.unwrap(_chunks.get(asset.chunks[0]));
        streaming_strategy = null;
      };
    };
  };
  private func _streamContent(id : Nat32, asset : Asset, idx : Nat) : (Blob, ?HttpStreamingCallbackToken) {
    let nextChunkId = asset.chunks[idx];
    let chunks = asset.chunks.size();
    let payload = Option.unwrap(_chunks.get(nextChunkId));
    if (idx + 1 == chunks) {
        return (payload, null);
    };
    return (payload, ?{
      content_encoding = "gzip";
      index = idx + 1;
      sha256 = null;
      key = Nat32.toText(id);
    });
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
}