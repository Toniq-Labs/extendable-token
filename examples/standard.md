# ERC20-token deployment guide
This ERC20 token example is just one of many ways a token canister can be developed and still conform to EXT standards. Note the following for this example:

- No notifications - these can be added in future. The `notify` field is ignored
- All TokenIDs are ignored, but must be present (you can use any text field e.g. "")
- You can use the canister id as the token id (note for using with Stoic)
- No memo's - this can be added in future with notifications. The `memo` field is ignored
- No erc20 `transferFrom` - you can use the `transfer` call and change the `from` address

## Deploy locally and test
The following deploys a test token (Me Token/MET) and mints the entire supply to the provided principal. We then follow with some basic tests:
```
dfx canister create ext_erc20
dfx build ext_erc20
dfx canister install ext_erc20 --argument="(\"Me Token\", \"MET\", 3, 100000000:nat, principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\")"

//Get canister ID
dfx canister id ext_erc20

//Supply
dfx canister call ext_erc20 supply "(\"\")"

//Metadata
dfx canister call ext_erc20 metadata "(\"\")"

//Balance - can query using the principal or address
dfx canister call ext_erc20 balance "(record { user = (variant { \"principal\" = principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\" }); token = \"\" } )"
dfx canister call ext_erc20 balance "(record { user = (variant { address = \"86d374abf9b9c532108cc15a7a9e6d21ac6dddd8d34b5babaf7e6244e6d1a638\" }); token = \"\" } )"
```
## Deploy live and load into Stoic
To deploy live, you would follow the same as above except you should:
1. Set the network to ic - i.e. `--network ic`
2. Set cycles when creating the canister

The following will deploy live with 2T cycles (please ensure you have enough cycles)
```
dfx canister --network ic create ext_erc20 --with-cycles 2000000000000
dfx build --network ic ext_erc20
dfx canister --network ic install ext_erc20 --argument="(\"Toniq Token\", \"NIQ\", 6, 100_000_000_000_000:nat, principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\")"

//Get canister ID
dfx canister --network ic id ext_erc20
```

**You can then take the canister ID and load it directly into Stoic:**

![a4a883a8-a7fd-466e-8707-14de79ae87fa](https://user-images.githubusercontent.com/13844325/122918390-3105c300-d3b3-11eb-8a9d-26048999f678.png)
