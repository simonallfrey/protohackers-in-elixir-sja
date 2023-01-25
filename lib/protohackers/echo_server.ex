defmodule Protohackers.EchoServer do
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
      active: false,       #everything is blocking and explicit
      reuseaddr: true,
      exit_on_close: false, #so we can keep writing on socket when client closes
      buffer: @buffer_size
    ]

    case :gen_tcp.listen(@echo_port, listen_options) do
      {:ok, listen_socket} ->
        dbg(:inet.getopts(listen_socket, [:buffer]))
        #  [lib/protohackers/prime_server.ex:32: Protohackers.PrimeServer.init/1]
        #  :inet.getopts(listen_socket, [:buffer]) #=> {:ok, [buffer: 1460]}
        Logger.info("Running on #{node()}")
        Logger.info("Starting echo server on port #{@echo_port}")
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
    case recv_until_closed(socket, _buffer="", _buffer_size = 0) do
      {:ok, data} ->
        Logger.debug("Sending")
        :gen_tcp.send(socket, data)
      {:error, reason} ->
        Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end


  defp recv_until_closed(socket, buffer, buffer_size) do
    r = :gen_tcp.recv(socket,0, @timeout)
    Logger.debug("Received: #{inspect(r)}")
    case r do
      {:ok, data} when buffer_size + byte_size(data) > @buffer_size ->
        {:error, :buffer_overflow}
      {:ok, data} ->
        Logger.debug("data: #{data}")
        recv_until_closed(socket, [buffer, data], buffer_size + byte_size(data))
      {:error, :closed} ->
        Logger.debug("Receive closed")
        {:ok, buffer}
      {:error, reason} -> {:error, reason}
    end
  end
end
