import ExtCore "./Core";
import AID "../util/AccountIdentifier";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Nat32 "mo:base/Nat32";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

module ExtEvent = {
    type Time = Time.Time;
    type AccountIdentifier = AID.AccountIdentifier;
    type User = ExtCore.User;

    public type EventData = {
        #address : AccountIdentifier;
        #address_list : [AccountIdentifier];
        #blob : Blob;
        #numeric : [Nat32];
        #other : Text;
    };
    
    public type Event = {
        name : Text;
        caller : User;
        description : Text;
        timestamp : Time.Time;
        data : ?[EventData]
    };

    public func addEvent( 
        data_eventListState : [Event], 
        e_name : Text,
        e_description : Text, 
        e_caller : User,
        e_data : ?[EventData]) : [Event]
    {
        return Array.append(data_eventListState, [{
            name = e_name;
            caller = e_caller;
            description = e_description;
            timestamp = Time.now();
            data  = e_data;
        }]);
    };


};