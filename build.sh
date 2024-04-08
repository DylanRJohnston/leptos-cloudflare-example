#!/bin/bash

set -o nounset
set -o pipefail
set -o errexit

cargo build --release --bin server --no-default-features --target wasm32-unknown-unknown --features ssr
cargo build --release --bin client --no-default-features --target wasm32-unknown-unknown --features hydrate

wasm-bindgen target/wasm32-unknown-unknown/release/server.wasm --out-name index --no-typescript --target bundler --out-dir site
wasm-bindgen target/wasm32-unknown-unknown/release/client.wasm --out-name index --no-typescript --target web --out-dir site/pkg
