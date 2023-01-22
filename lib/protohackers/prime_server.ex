defmodule Protohackers.PrimeServer do
  use GenServer

  require Logger


  Logger.configure(level: :info)

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
      packet: :line,
      buffer: @buffer_size
    ]

    case :gen_tcp.listen(@prime_port, listen_options) do
      {:ok, listen_socket} ->
        dbg(:inet.getopts(listen_socket, [:buffer]))
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
        # we have to replace the newline by hand, again as iodata
        # packet: :line only affects receives
        Logger.debug("Received data: #{inspect(data)}")
        :gen_tcp.send(socket, [data, ?\n])
        echo_lines_until_closed(socket)
      {:error, :closed} ->
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end
end
