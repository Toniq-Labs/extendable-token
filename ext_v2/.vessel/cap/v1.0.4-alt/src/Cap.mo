/// Cap library
///
/// Minimal working example:
///
/// ```motoko
/// import Cap "mo:cap/Cap";
///
/// let cap = CapMotokoLibrary.Cap(?localReplicaRouterId);
/// let tokenContractId = "rdmx6-jaaaa-aaaaa-aaadq-cai";
///
/// public func init() : async () {
///     // As a demo, the parameters are hard-typed here
///     // but could be declared in the function signature
///     // and pass when executing the request
///     let handshake = await cap.handshake(
///       localReplicaRouterId,
///       tokenContractId,
///       creationCycles
///     );
/// };
/// ```

import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import IC "IC";
import Root "Root";
import Router "Router";
import Types "Types";

module {
    public class Cap(
        overrideRouterId    : ?Text,
        provideRootBucketId : ?Text,
    ) {
        var rootBucket: ?Text = provideRootBucketId;

        let routerId = Option.get(overrideRouterId, Router.mainnet_id);
        let ic: IC.ICActor = actor("aaaaa-aa");
        let router: Router.Self = actor(routerId);

        // Retrieves a transaction from the root bucket.
        public func getTransaction(
            id: Nat64,
        ) : async Result.Result<Root.Event, Types.GetTransactionError> {
            let root = switch(rootBucket) {
                case (?r) r;
                case _ {
                    throw Error.reject("Cannot call `getTransaction` with no root bucket.");
                };
            };
            let rb: Root.Self = actor(root);

            try {
                switch(await rb.get_transaction({ id=id; witness=false; })) {
                    case (#Found(event, witness)) {
                        switch(event) {
                            case (null) {
                                #err(#invalidTransaction)
                            };
                            case (?event) {
                                #ok(event)
                            }
                        }
                    };
                    case (#Delegate(_, _)) {
                        #err(#unsupportedResponse)
                    }
                }
            } catch e {
                throw Error.reject(
                    "Error getting transaction (" #
                    Nat64.toText(id) # "): " #
                    Error.message(e)
                );
            };
        };
        
        // Migrate an array of events to the root bucket.
        public func migrate(
            events: [Root.Event],
        ) : async Result.Result<(), Types.InsertTransactionError> {
            let root = switch(rootBucket) {
                case(?r) { r };
                case(_) {
                    throw Error.reject("Cannot call `migrate` with no root bucket.");
                };
            };
            let rb: Root.Self = actor(root);

            try {
                #ok(await rb.migrate(events));
            } catch e {
                throw Error.reject("Error migrating events: " # Error.message(e));
            };
        };
        
        // Adds an event to the root bucket.
        public func insert(
            event: Root.IndefiniteEvent,
        ) : async Result.Result<Nat64, Types.InsertTransactionError> {
            let root = switch(rootBucket) {
                case(?r) { r };
                case(_) {
                    throw Error.reject("Cannot call `insert` with no root bucket.");
                };
            };
            let rb: Root.Self = actor(root);

            try {
                #ok(await rb.insert(event));
            } catch e {
                throw Error.reject("Error inserting event: " # Error.message(e));
            };
        };

        // Attempts to retrieve an existing root bucket for a given token contract.
        private func _getRootBucket (
            tokenContractId : Text,
        ) : async ?Text {
            try {
                let { canister } = await router.get_token_contract_root_bucket({
                    canister = Principal.fromText(tokenContractId);
                    witness  = false;
                });
                switch (canister) {
                    case (?c) ?Principal.toText(c);
                    case _ null;
                };
            } catch e {
                throw Error.reject("Error querying router: " # Error.message(e));
            };
        };

        // Get or create a root bucket canister for the given token contract.
        // Return the rootBucket so it can be stored in stable memory in the 
        // calling canister to be persisted during upgrades
        public func handshake(
            tokenContractId : Text,
            creationCycles  : Nat,
        ): async ?Text {
            switch(await _getRootBucket(tokenContractId)) {
                case (?canister) {
                    // If we already have a root bucket, store the principal in memory.
                    rootBucket := ?canister;
                    return rootBucket;
                };
                case null {
                    // We do not have a root bucket. Ask the router to make one.
                    let settings: IC.CanisterSettings = {
                        controllers = ?[Principal.fromText(routerId)];
                        compute_allocation = null;
                        memory_allocation = null;
                        freezing_threshold = null;
                    };
                    let params: IC.CreateCanisterParams = {
                        settings = ?settings
                    };
                    Cycles.add(creationCycles);

                    // Ask the IC to create a canister.
                    var canister : ?Principal = null;
                    try {
                        let { canister_id } = await ic.create_canister(params);
                        canister := ?canister_id;
                    } catch e {
                        throw Error.reject("Error creating canister: " # Error.message(e));
                    };

                    // Ask the router to install root code into our new canister.
                    switch (canister) {
                        case (?c) {
                            try {
                                await router.install_bucket_code(c);
                            } catch e {
                                throw Error.reject("Error installing code: " # Error.message(e));
                            };
                        };
                        case null {
                            // Debug.print("Canister cannot be null after canister creation.");
                            Prelude.unreachable();
                        };
                    };

                    // Retrieve root bucket principal after creation.
                    switch (await _getRootBucket(tokenContractId)) {
                        case (?c) {
                            // Store the new root bucket principal in memory.
                            rootBucket := ?c;
                            return rootBucket;
                        };
                        case _ {
                            // Debug.print("Root bucket cannot be null after root bucket creation.");
                            Prelude.unreachable();
                        };
                    };
                };
            };
        };
    };
}
