#!/bin/bash

printf "[TEST] 🤖 Canister upgrade\n\n"

# Takes a single argument and calls the get_transactions of token contract canister
# $1 - token contract canister id
function get_transaction {
  response=$(dfx canister call "$1" get_transactions "( record { witness = (false:bool) } )")
  echo "$response";
}

CANISTER_ID_CAP_SERVICE=$1
CANISTER_ID_CAP_MOTOKO_INSERT_EXAMPLE=$2

GET_TOKEN_CONTRACT_RESPONSE=$(dfx canister call "$CANISTER_ID_CAP_SERVICE" get_token_contract_root_bucket "(record { canister=(principal \"$CANISTER_ID_CAP_MOTOKO_INSERT_EXAMPLE\"); witness=(false:bool)})")
TOKEN_CONTRACT=$(echo "$GET_TOKEN_CONTRACT_RESPONSE" | pcre2grep -o1 'principal "(.*?)"')

TRANSACTION_STATE_BEFORE_UPGRADE=$(get_transaction "$TOKEN_CONTRACT")

dfx canister install --all --mode upgrade

printf "\n\n"

printf "[TEST] 🤖 Token contract root, get_transactions result\n\n"

TRANSACTION_STATE_AFTER_UPGRADE=$(dfx canister call "$TOKEN_CONTRACT" get_transactions "( record { witness = (false:bool) } )")

HAS_DIFF=$(diff  <(echo "$TRANSACTION_STATE_BEFORE_UPGRADE" ) <(echo "$TRANSACTION_STATE_AFTER_UPGRADE"))

if [[ -z $HAS_DIFF ]];
then
  printf "[TEST] 🎉 Transaction state persists before/after upgrade!"
else
  printf "[TEST] 🐛 Transaction state does not seem to persist in before/after upgrade!"
fi;