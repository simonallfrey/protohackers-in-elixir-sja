defmodule Protohackers.Constants do
  defmacro __using__(_) do
    quote do
      @port 5001
      @timeout 10_000
      @limit _100_kb = 1024 * 100
      @max_children 100
    end
  end
end
