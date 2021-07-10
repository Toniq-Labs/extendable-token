# Advanced multi-token deployment guide
This Advanced token example is similar to the Standard token, except we allow multiple tokens per canister. We have deployed an experiment site where you can deploy your own tokens: [EXT Token Tool](https://k6exx-uqaaa-aaaah-qadba-cai.raw.ic0.app/)

## Deploy locally and test
The following deploys a test token (Me Token/MET) and mints the entire supply to the provided principal. We then follow with some basic tests:
```
dfx deploy advanced --argument="(principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\")"
```
Because we use a custom generated token ID, you would need to encode your own using the canister ID and the index of the created token. As this is not very easy to do using dfx, we are currently building a nodejs based CLI tool which will allow you to do this very easily.

## Deploy live and load into Stoic
To deploy live, you would follow the same as above except you should:
1. Set the network to ic - i.e. `--network ic`
2. Set cycles when creating the canister

The following will deploy live with 2T cycles (please ensure you have enough cycles)
```
dfx deploy --network ic advanced --with-cycles 2000000000000 --argument="(principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\")"

//Get canister ID
dfx canister --network ic id advanced
```
