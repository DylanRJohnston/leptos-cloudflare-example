use leptos::*;
use leptos_meta::provide_meta_context;

#[server]
pub async fn generate_random_number() -> Result<f64, ServerFnError> {
    Ok(js_sys::Math::random())
}

#[component]
pub fn hello_world() -> impl IntoView {
    provide_meta_context();

    let get_random = create_server_action::<GenerateRandomNumber>();
    let on_click = move |_| get_random.dispatch(GenerateRandomNumber {});

    view! {
      <h1>"Hello, World! "{move || get_random.value()}</h1>
      <button on:click=on_click>"Get me a random number"</button>
    }
}
