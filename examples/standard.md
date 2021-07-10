# Standard single-token deployment guide
This Standard token example is similar to the ERC20 token, except we add the tx notifications.

## Deploy locally and test
The following deploys a test token (Me Token/MET) and mints the entire supply to the provided principal. We then follow with some basic tests:
```
dfx deploy standard --argument="(\"Me Token\", \"MET\", 3, 100000000:nat, principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\")"

//Get canister ID
dfx canister id standard

//Supply
dfx canister call standard supply "(\"\")"

//Metadata
dfx canister call standard metadata "(\"\")"

//Balance - can query using the principal or address
dfx canister call standard balance "(record { user = (variant { \"principal\" = principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\" }); token = \"\" } )"
dfx canister call standard balance "(record { user = (variant { address = \"86d374abf9b9c532108cc15a7a9e6d21ac6dddd8d34b5babaf7e6244e6d1a638\" }); token = \"\" } )"
```
## Deploy live and load into Stoic
To deploy live, you would follow the same as above except you should:
1. Set the network to ic - i.e. `--network ic`
2. Set cycles when creating the canister

The following will deploy live with 2T cycles (please ensure you have enough cycles)
```
dfx deploy --network ic standard --with-cycles 2000000000000 --argument="(\"Toniq Token\", \"NIQ\", 6, 100_000_000_000_000:nat, principal \"sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe\")"

//Get canister ID
dfx canister --network ic id standard
```

**You can then take the canister ID and load it directly into Stoic:**

![a4a883a8-a7fd-466e-8707-14de79ae87fa](https://user-images.githubusercontent.com/13844325/122918390-3105c300-d3b3-11eb-8a9d-26048999f678.png)
