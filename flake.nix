{
  inputs = {
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-filter.url = "github:numtide/nix-filter";
  };
  outputs = { nixpkgs, flake-utils, naersk, rust-overlay, nix-filter, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        wasm-bindgen-cli-update = final: prev: {
          wasm-bindgen-cli = prev.wasm-bindgen-cli.override {
            version = "0.2.92";
            hash = "sha256-1VwY8vQy7soKEgbki4LD+v259751kKxSxmo/gqE6yV0=";
            cargoHash = "sha256-aACJ+lYNEU8FFBs158G1/JG8sc6Rq080PeKCMnwdpH0=";
          };
        };

        overlays = [ (import rust-overlay) (wasm-bindgen-cli-update) ];

        pkgs = import nixpkgs { inherit system overlays; };

        toolchain = pkgs.rust-bin.nightly.latest.default.override {
          extensions = [ "rust-src" ];
          targets = [ "wasm32-unknown-unknown" ];
        };

        naersk' = pkgs.callPackage naersk {
          cargo = toolchain;
          rustc = toolchain;
        };
      in {
        devShell = with pkgs;
          mkShell {
            buildInputs = [
              toolchain
              wrangler
              wasm-bindgen-cli
              entr
              cargo-expand
              darwin.apple_sdk.frameworks.AppKit
            ];

            RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
          };
      });
}
