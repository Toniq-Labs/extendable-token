# 🦖 Cap Motoko Library examples

The examples serve to provide information on how to use the Motoko Library, mainly in your local replica environment.

Use the documentation here to understand how to run the separate services which are required in your local development environment.

Deploying to Mainnet, shouldn't be any different, although the version of [Cap](https://github/com/psychedelic/cap) might be diferent from the version you run locally, so keep track of releases. If interested in finding more about deploying the examples to the Mainnet, [read here](#-deploying-the-examples-to-mainnet).

## 📒 Table of Contents 
- [How to run the examples?](#-how-to-run-the-examples)
- [How to use the test use-cases?](#-how-to-use-the-test-use-cases)


# 🤔 How to run the examples?

**TLDR;** Deploy the example to mainnet and use an actor to interact with it, either via [DFX CLI](https://sdk.dfinity.org/docs/developers-guide/cli-reference.html) or your [Agentjs](https://github.com/dfinity/agent-js).

If planning to run the examples in your local environment and not the mainnet network, then the main [Cap repo](https://github.com/Psychedelic/cap) should be cloned and deployed to your local replica!

Alternatively, the Cap Service handling can be borrowed from the [Cap Explorer](https://github.com/Psychedelic/cap-explorer), which is documented and is easy to grasp...

Once the `Cap router` is running in your local, copy the Router id; for our reading we'll name it `<Router ID>` to keep it easy to follow!

## 1. Set Up the Example Repository

When ready, open the directory for one of our examples e.g. the `/cap-motoko-library/examples/insert` and deploy the example to your local replica network, as follows:

```sh
dfx deploy cap-motoko-example --argument "(opt \"<Router ID>\")"
```

Obs: Notice that the `<Router ID>` is the Canister Id of the deployed local replica `ic-history-router` of [Cap Service](https://github.com/psychedelic/cap). We pass the `<Router ID>` to override the default Mainnet Router Canister id.

Make sure you execute the command in the correct directory, where a `dfx.json` exists describing the canister `cap-motoko-example`, otherwise it'll fail.

💡 When deploying, the `cap-motoko-example` is pulling a particular version of the [Cap Motoko Library](https://github.com/Psychedelic/cap-motoko-library) via the [Vessel Package Manager](https://github.com/dfinity/vessel/releases) which is described in the main README of the [Cap Motoko Library](https://github.com/Psychedelic/cap-motoko-library) repository. For example, you'll find the field `version` in the additions setup in the `package-set.dhall`, you can have another tag or a commit hash.

Now that we have deployed the `cap-motoko-example` we can find the Canister id in the output. So, from now on, we'll use `<Application Token Contract ID>` to refer to the `cap-motoko-example` to keep it easy to follow!

Here's an example of how the output should look like:

```sh
Deploying: cap-motoko-example
All canisters have already been created.
Building canisters...
Installing canisters...
Creating UI canister on the local network.
The UI canister on the "local" network is "<xxxxx>"
Installing code for canister cap-motoko-example, with canister_id "<Application Token Contract ID>"
Deployed canisters.
```
## 2. Deploy a Root History Canister in CAP

Copy the `<Application Token Contract ID>` because you are going to use it to send requests via the DFX CLI!

Now, we need to push our example source code to Cap! For that we have a `handshake` process that creates a new Root canister for us, with the right controller.

For our example, we're going to use the [DFX CLI]() to call a method in our example application actor, called `init`

```sh
dfx canister call <Application Token Contract ID> init "()"
```

It should take a bit, and once completed you'll find the output it similar to:

```sh
()
```

Where `()` is the returned value, if we did NOT get any errors during the process handling!

💡 When following the `cap-motoko-example` code structure in your own project, there is no need to call `init` after canister upgrades as the Root History Canister ID is persisted in stable memory.
## 3. Test the History by Making a Call to Insert an Event

From then on we can simple use the remaining methods available, such as `insert`. This means that we do the initialisation only once and NOT everytime we need to make a Cap call.

To complete, we execute the `insert` to push some data to our Root bucket for our `<Application Token Contract ID>` example application.

```sh
dfx canister call <Application Token Contract ID> insert "()"
```

Here's how it looks:

```sh
(variant { ok = 0 : nat64 })
```

The `(variant { ok = 0 : nat64 })` is a wrapped response of the expected returned value, the transaction id as `nat64` (starts at zero), as we can verify by looking at the [Candid](https://github.com/Psychedelic/cap/blob/main/candid/root.did#L57) for Cap Root. It's wrapped by our example `insert` method.

👋 That's it! You can now use the Cap Motoko Library in your local replica and the same knowledge can be applied to deploy to the [mainnet](#-deploying-the-examples-to-mainnet)!

# 🚀 Deploying the examples to mainnet

## 1. Deploy to mainnet

We start by deploying to the Mainnet by using the flag `--network ic`, and omit the constructor argument which is used locally to override the Mainnet Router ID. By setting `null`, we cause the constructor to use the Router ID Mainnet.

```sh
dfx deploy --network ic --argument "(null)"
```

The output should show:

```sh
Creating canister "cap-motoko-example"...
Installing code for canister cap-motoko-example, with canister_id <Application Token Contract Id>
Deployed canisters.
```

Copy the `<Application Token Contract Id>`, as it's needed for initialisation.

## 2. Initialize CAP in Your Mainnet Canister

The initialisation is the process that calls the Cap `handshake` endpoint:

```sh
dfx canister --network ic call <Application Token Contract Id> init "()"
```

It should take a bit, and once completed you'll find the output it similar to:

```sh
()
```

## 3. Call a Method and Insert Data

From then on we can simple use the remaining methods available, such as `insert`. The same principals we found in the local replica apply here, so we only need to call the initialisation once.

To complete, we execute the `insert` to push some data to our Root bucket for our `<Application Token Contract ID>` example application.

```sh
dfx canister --network ic call <Application Token Contract ID> insert "()"
```

Here's how the output looks (e.g. if you request a new `insert`, then the ok number will increase, as that's the wrapped transaction id):

```sh
(variant { ok = 0 : nat64 })
```

## 4. Verify the transactions in the Root bucket

First, we call the Router `get_token_contract_root_bucket`, that'll provide us the history canister or Root canister:

```sh
dfx canister --network ic call <Router ID> get_token_contract_root_bucket "( record { witness = (false:bool); canister = principal \"<Application Token Contract ID>\" } )"
```

We then call the `<Root ID>` `get_transactions` to retrieve all the transactions:

```sh
dfx canister --network ic call <Root ID> get_transactions "( record { witness = (false:bool) } )"
```

Here's how the output looks like for two transactions in the history:

```js
(
  record {
    1_113_806_378 = vec {
      record {
        1_291_635_725 = 1_641_904_752_498 : nat64;
        2_688_582_695 = "transfer";
        2_874_596_546 = vec {
          record { "key"; variant { 936_573_133 = "value" } };
        };
        3_068_679_307 = principal "6vj5p-imd5n-7gtwg-fskuc-bvuqy-65j54-xxdqw-gxikv-rkw4u-ocrmb-dqe";
      };
      record {
        1_291_635_725 = 1_641_904_807_109 : nat64;
        2_688_582_695 = "transfer";
        2_874_596_546 = vec {
          record { "key"; variant { 936_573_133 = "value" } };
        };
        3_068_679_307 = principal "6vj5p-imd5n-7gtwg-fskuc-bvuqy-65j54-xxdqw-gxikv-rkw4u-ocrmb-dqe";
      };
    };
    1_246_878_287 = 0 : nat32;
    1_668_342_201 = null;
  },
)
```

👋 Well done! You've succesfully deployed a Canister to the mainnet, inserted some event data and retrieved the event transactions!

# 💍 How to use the test use-cases?

Provided some scripts to run a few process, for your convinence.

The tests are available along the example directory. For example, for the `/examples/insert` there's a `/examples/insert/tests` directory.

Make sure that you have first deployed your Application, initialise a Token contract with Cap and inserted some data. Check the `cap-motoko-library` insert example first!

To run the `upgrade` test example, jump into the directory and execute the command:

```sh
./canister-upgrade.sh <Router ID> <Application Token Contract Id>
```

There are some basic assertions on the tests, but the result responses should be checked manually too. The assertion is basic and simply checks if there are any differences between the before and after upgrade state for a particular root canister method e.g. get_transactions.
For example, if you'd like to test the `canister upgrade` for the example application, make sure you verify the initial state or response to keep track of any differences.
