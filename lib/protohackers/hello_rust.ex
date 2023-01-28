defmodule Protohackers.HelloRust do
  use Rustler, otp_app: :protohackers, crate: "protohackers_hellorust"

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  def greet(), do: :erlang.nif_error(:nif_not_loaded)
end
