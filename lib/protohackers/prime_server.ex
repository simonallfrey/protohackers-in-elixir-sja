defmodule Protohackers.PrimeServer do
  use GenServer

  require Logger


  use Protohackers.Constants

  def start_link([]=_opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  defstruct [:listen_socket, :supervisor]

  @impl true
  def init(:no_state) do

    {:ok, supervisor} = Task.Supervisor.start_link(max_children: @max_children)



    listen_options = [
      mode: :binary,
      # everything is blocking and explicit
      active: false,
      reuseaddr: true,
      #so we can keep writing on socket when client closes
      exit_on_close: false,
      # https://www.erlang.org/doc/man/inet.html#setopts-2
      packet: :line,
      buffer: @buffer_size
    ]

    # dbg(Logger.)

    case :gen_tcp.listen(@prime_port, listen_options) do
      {:ok, listen_socket} ->
        # dbg(:inet.getopts(listen_socket, [:buffer]))
        #  [lib/protohackers/prime_server.ex:32: Protohackers.PrimeServer.init/1]
        #  :inet.getopts(listen_socket, [:buffer]) #=> {:ok, [buffer: 1460]}
        Logger.info("Running on #{node()}")
        Logger.info("PID #{inspect(self())}")
        Logger.info("Starting prime server on port #{@prime_port}")
        state = %__MODULE__{listen_socket: listen_socket, supervisor: supervisor}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn -> handle_connection(socket) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  ## Helpers

  defp handle_connection(socket) do
    Logger.debug("Handling connection")
    case echo_lines_until_closed(socket) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end


  defp echo_lines_until_closed(socket) do
    #with packet: :line recv all bytes means until newline
    case :gen_tcp.recv(socket, 0, @timeout) do
      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, %{"method" => "isPrime","number" => number}} when is_number(number) ->
            Logger.debug("Received valid request for number: #{number}")
            response = %{"method" => "isPrime","prime" => true}
            # we have to replace the newline by hand, again as iodata
            # packet: :line only affects receives
            :gen_tcp.send(socket, [Jason.encode!(response), ?\n])
            echo_lines_until_closed(socket)
          other ->
            Logger.debug("Received invalid request: #{inspect(other)}")
            Logger.debug("Responding with : malformed request")
            :gen_tcp.send(socket, "malformed request\n")
            {:error, :invalid_request}
        end
      {:error, :closed} ->
        :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
