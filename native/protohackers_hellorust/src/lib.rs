#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

// https://stackoverflow.com/questions/43079077/proper-way-to-return-a-new-string-in-rust
#[rustler::nif]
fn greet<'lifetime>() -> &'lifetime str {
    "Hello from Rust :-)"
}

rustler::init!("Elixir.Protohackers.HelloRust", [add, greet]);
