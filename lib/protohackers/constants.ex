defmodule Protohackers.Constants do
  defmacro __using__(_) do
    quote do
      @echo_port 5001
      @prime_port 5002
      @timeout 10_000
      @limit _100_kb = 1024 * 100
      @buffer_size _100_kb = 1024 * 100
      @max_children 100
    end
  end
end
