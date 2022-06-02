import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import ExtCommon "../ext/Common";
import ExtCore "../ext/Core";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Util "../util/Util";

module ExtWearable = 
{
    type TokenIndex  = ExtCore.TokenIndex;
    type TokenIdentifier = ExtCore.TokenIdentifier;
    type Metadata = ExtCommon.Metadata;
    type Time = Time.Time;
    type Listing = {
    seller : Principal;
    price : Nat64;
    locked : ?Time;
  };

    public func equip(
        _puppy : TokenIndex,
        _wearable : TokenIndex,
        _tokenListings : HashMap.HashMap<TokenIndex, Listing>,
        _tokenMetadata:HashMap.HashMap<TokenIndex, Metadata>,
        _tokenWearables : HashMap.HashMap<TokenIndex, [TokenIndex]> 
        ) : Result.Result<(), Text>
    {

        let wearableArray : ?[TokenIndex] = _tokenWearables.get(_puppy);
        switch(wearableArray)
        {
            case(?wearableArray)
            {
                let w = Util.ArrayUtil.push(wearableArray, _wearable);
                _tokenWearables.put(_puppy, w);
                return #ok();
            };
            case(_)
            {
                return #err("No wearable list exists")
            };
        };
        // wearableList
    };

 

}