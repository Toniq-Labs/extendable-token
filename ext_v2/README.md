## ext-v2-token

Here is a quick guide for deploying ext-v2-token standard on Internet Computer.

# 1. Setup and local deployment

- yarn install
- dfx start 
- dfx deploy --argument '(principal "your-minting-principal")'
- dfx ledger fabricate-cycles --all

Congrats! Now you've deployed backend canister locally and topped it up with some cycles. Take note of your canister ID.

# 2. Minting locally

- open *mint_script.js*, you will need to edit some variables
- *isLocal* switches between local and ic networks, should be set to true for local deployment
- *minterSeed* enter your principal seed phrase here (the one you deployed canister with in dfx deploy)
- *canisterIdLocal* enter your local canister id here 
- set up paths to your images and thumbnails ( *basePath*, *assetPathBase*, *thumbsPathBase* )
- run *node src/mint_script.js*


After minting locally, and going to your canister id, for example -> http://127.0.0.1:8000/?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai&index=0 your asset may not display properly. 

This is expected behavior as its referencing wrong url due to how local canisters are set up. If you go to developer tools -> elements in your browser, you will see this targeted url. Take note of asset canister id and index. If you open a new tab in browser and go to something like: http://127.0.0.1:8000/?canisterId=qvhpv-4qaaa-aaaaa-aaagq-cai&index=0 with your asset canister id, it should take you to correct asset.

Given that thumbnails are saved on collection canister, this should work: http://127.0.0.1:8000/?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai&index=0&type=thumbnail

# 3. Minting on IC

Now that you tested local deployment, you can proceed with minting on IC.

- dfx deploy --network ic --argument '(principal "your-minting-principal")'
- open *mint_script.js* again
- set *isLocal* to false
- set *canisterIdIC* to your IC deployed canister
- run *node src/mint_script.js*

Congratulations, your NFT's should now be deployed on IC network!





