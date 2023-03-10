defmodule Protohackers.Constants do
  defmacro __using__(_) do
    quote do
      @echo_port 5001
      @prime_port 5002
      @prices_port 5003
      @chat_port 5004
      @udp_port 5005
      @timeout 10_000
      # @limit _100_kb = 1024 * 100
      @buffer_size _100_kb = 1024 * 100
      @max_children 100
    end
  end
end
