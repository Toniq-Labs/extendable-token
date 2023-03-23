#!/usr/bin/env bash

set -eo pipefail


echo "Checking Canister.mo compiles"
$(vessel bin)/moc $(vessel sources) ../src/Canister.mo

$(vessel bin)/moc $(vessel sources) -wasi-system-api Test.mo
if wasmtime Test.wasm ; then
    echo "Tests failed to fail"
    exit 1
else
    echo "Tests successfully failed"
    exit 0
fi
