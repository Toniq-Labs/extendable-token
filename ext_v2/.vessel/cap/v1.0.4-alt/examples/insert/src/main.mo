import Principal "mo:base/Principal";
import Cap "mo:cap/Cap";
import Root "mo:cap/Root";
import Router "mo:cap/Router";
import Result "mo:base/Result";
import Types "mo:cap/Types";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

shared actor class InsertExample (
    overrideRouterCanister : ?Text
) = Self {
    type DetailValue = Root.DetailValue;
    type Event = Root.Event;
    type IndefiniteEvent = Root.IndefiniteEvent;

    // Start a local replica network
    // deploy the Cap Service in your local replica network
    // and copy the local replica router id
    // Example:
    //   dfx start --clean
    //   dfx deploy ic-history-router
    //   dfx deploy cap-motoko-example --argument "(opt \"<The Local Replica Router Id>\")"
    // References:
    // The Cap repo is located at https://github.com/Psychedelic/cap
    // see the releases https://github.com/Psychedelic/cap/tags
    let routerId = Option.get(overrideRouterCanister, Router.mainnet_id);

    // Create a stable variable to persist the Root Canister ID during upgrades.
    // This way the init() method doesn't need to be called after canister upgrades.
    private stable var rootBucketId : ?Text = null;

    // If the local replica router is not set
    // then the mainnet id is used "lj532-6iaaa-aaaah-qcc7a-cai" 
    // and because the expected argument is an optional we pass as ?xxx
    // We also pass in the rootBucketId. If the init() method has been called before,
    // the rootBucketId variable contains the principal for this canisters root bucket,
    // otherwise it's null.
    let cap = Cap.Cap(?routerId, rootBucketId);

    // The number of cycles to use when initialising
    // the handshake process which creates a new canister
    // and install the bucket code into cap service
    // Obs: The minimum would appear to be somewhere around 200B,
    // but set to 1T based on rckprtr's experience with Cap in rust
    // as community contributor @jorgenbuilder experienced
    let creationCycles : Nat = 1_000_000_000_000;

    public func id() : async Principal {
        return Principal.fromActor(Self);
    };

    public func init() : async Result.Result<(), Text> {
        // Your application canister token contract id
        // e.g. execute the command dfx canister id cap-motoko-example
        // in the cap-motoko-library/examples directory
        // after you have deployed the cap-motoko-example
        let pid = await id();
        let tokenContractId = Principal.toText(pid);

        // As a demo, the parameters are computed here
        // but could be declared in the function signature
        // and pass when executing the request
        try {
            rootBucketId := await cap.handshake(
                tokenContractId,
                creationCycles
            );

            return #ok();
        } catch e {
            throw e;
        };
    };

    public shared (msg) func insert() : async Result.Result<Nat64, Types.InsertTransactionError> {
        let event : IndefiniteEvent = {
            operation = "transfer";
            details = [("key", #Text "value")];
            caller = msg.caller;
        };

        let transactionId = await cap.insert(event);

        return transactionId;
    };
};
