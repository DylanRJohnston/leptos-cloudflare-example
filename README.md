# Leptos + Cloudflare Pages

This is a "Hello World" style repo showing how to successfully integrate Leptos SSR with Cloudflare Pages. Cloudflare Pages has the advantage over worker sites in that static asset retrieval, such as a the client wasm bundle or css, is free.


### Routing

To determine what it routed to static assets in Cloudflare Pages vs the Worker functions there is the `_routes.json` file which controls basic pattern matching of routes. e.g.

```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": ["/pkg/*"]
}
```

The exclude clause overrides the include clause and so this routes file will route all requests not starting with `/pkg` to the Cloudflare Worker where Leptos and Axum can use SSR.

### SSR
Server Side Rendering is handled via Cloudflare Workers, Leptos, and Axum. Support for Axum was added recently to the `workers-rs` repository and so intermediate libraries like `cloudflare-axum` and `leptos-cloudflare` are no longer required.

The configuration of Leptos and Axum looks fairly normal with the exception that instead of binding the router to a port we invoke it once with the Request passed into the Cloudflare Worker e.g.

```rs
#[event(fetch)]
pub async fn fetch(
    req: HttpRequest,
    _env: Env,
    _ctx: Context,
) -> Result<axum::http::Response<axum::body::Body>> {
    let leptos_options = LeptosOptions::builder()
        .output_name("index")
        .site_pkg_dir("pkg")
        .build();

    // Automatic registration of server_fns doesn't work in WASM
    register_explicit::<GenerateRandomNumber>();

    let mut router = Router::new()
        .leptos_routes(&leptos_options, generate_route_list(HelloWorld), HelloWorld)
        .with_state(leptos_options);

    Ok(router.call(req).await?)
}
```

I haven't had much chance to play around with it, but it might also be possible to render out static routes and Leptos Islands into static files served by Cloudflare Pages for free instead of requiring an invocation of the Cloudflare Worker which counts towards your bill.

### Hydration
The client and server wasm bundles are built separately and then transformed with `wasm-bindgen`. The client bundle is placed inside `site/pkg` where Cloudflare Pages serves it to the client for free.

### Building
Building is achieved by building the client and server wasm separately, and then using `wasm-bindgen` to generate the JS compatible bindings. The server requires a small shim which is detailed below.

```sh
cargo build --release --bin server --no-default-features --target wasm32-unknown-unknown --features ssr
cargo build --release --bin client --no-default-features --target wasm32-unknown-unknown --features hydrate

wasm-bindgen target/wasm32-unknown-unknown/release/server.wasm --out-name index --no-typescript --target bundler --out-dir site
wasm-bindgen target/wasm32-unknown-unknown/release/client.wasm --out-name index --no-typescript --target web --out-dir site/pkg
```

### Cloudflare Worker Shim
A small JS shim is required to bridge the gap between the JS produced by wasm-bindgen and what is expected by Cloudflare Workers, the shim can be found in `site/_worker.js`. This originally came from the official Cloudflare Documentation but I can't find the source when putting this documentation together anymore.

```js
import * as imports from "./index_bg.js";
export * from "./index_bg.js";
import wkmod from "./index_bg.wasm";
import * as nodemod from "./index_bg.wasm";

if (typeof process !== "undefined" && process.release.name === "node") {
  imports.__wbg_set_wasm(nodemod);
} else {
  const instance = new WebAssembly.Instance(wkmod, {
    "./index_bg.js": imports,
  });
  imports.__wbg_set_wasm(instance.exports); 
}

Error.stackTraceLimit = Infinity;

imports.start?.();

export * as default from "./index_bg.js"
```

### Local Development

Because `cargo leptos` doesn't support this style of server we're left with putting the tools together ourselves, building is fairly simple as documented above, but lacks hot-reloading and other quality of life features. I personally use `entr` to watch for file changes and then re-compile.

Cloudflare pages also supports local development via wrangler.

```sh
wrangler pages dev site
```

Wrangler also allows for easy testing against a real deployment to their cloud, please see their documentation for more details.

### Nix
I've provided a flake.nix which has all the required dependencies to get started, including an overlay for a more recent `wasm-bidngen-cli` if nix is your thing. If not a rough guide to what you'll need is as follows.

* rustc
* cargo
* wrangler
* wasm-bindgen-cli
* entr