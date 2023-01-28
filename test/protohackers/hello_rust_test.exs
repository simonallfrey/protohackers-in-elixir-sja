defmodule Protohackers.HelloRust.Test do
  use ExUnit.Case, async: true
  use Protohackers.Constants

  alias Protohackers.HelloRust

  # alias Protohackers.PricesServer.DB

  test "Rust says hello" do
    assert HelloRust.greet() == "Hello from Rust :-)"
  end


  test "Rust adds numbers" do
    assert HelloRust.add(2,2) == 4
  end


end
