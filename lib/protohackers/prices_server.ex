defmodule Protohackers.PricesServer do
  use GenServer

  require Logger

  alias Protohackers.PricesServer.DB

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

    case :gen_tcp.listen(@prices_port, listen_options) do
      {:ok, listen_socket} ->
        # dbg(:inet.getopts(listen_socket, [:buffer]))
        #  [lib/protohackers/prime_server.ex:32: Protohackers.PrimeServer.init/1]
        #  :inet.getopts(listen_socket, [:buffer]) #=> {:ok, [buffer: 1460]}
        Logger.info("Running on #{node()}")
        Logger.info("Starting prices server on port #{@prices_port}")
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
    case handle_requests(socket, DB.new()) do
      :ok -> :ok
      {:error, reason} -> Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end


  defp handle_requests(socket, db) do
    case :gen_tcp.recv(socket, 9, @timeout) do
      {:ok, data} when byte_size(data) == 9 ->
        case handle_request(data,db) do
          {nil, db} ->
            handle_requests(socket, db)

          {response,db} ->
            :gen_tcp.send(socket,response)
            handle_requests(socket, db)

          :error ->
            {:error,:invalid_request}
        end

      {:error, :timeout} ->
        handle_requests(socket,db)

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end


  defp handle_request(<<?I, timestamp::32-signed-big, price::32-signed-big>>, db) do
    {nil, DB.add(db,timestamp,price)}
  end

  defp handle_request(<<?Q, from::32-signed-big, to::32-signed-big>>, db) do
    average = DB.query(db,from,to)
    {<<average::32-signed-big>>, db}
  end

  defp handle_request(_other, _db) do
    :error
  end
end
