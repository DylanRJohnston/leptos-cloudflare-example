use axum::Router;
use leptos::{server_fn::axum::register_explicit, LeptosOptions};
use leptos_axum::{generate_route_list, LeptosRoutes};
use tower::Service;
use worker::*;

use leptos_cloudflare_example::app::{GenerateRandomNumber, HelloWorld};

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

pub fn main() {}
