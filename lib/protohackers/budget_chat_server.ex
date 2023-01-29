defmodule Protohackers.BudgetChatServer do
  use GenServer

  require Logger


  use Protohackers.Constants

  def start_link([]=_opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  # reference ets table in our server
  defstruct [:listen_socket, :supervisor, :ets]

  @impl true
  def init(:no_state) do

    {:ok, supervisor} = Task.Supervisor.start_link(max_children: @max_children)

    # all processes can use this ets table (in memory key/val database)
    ets = :ets.new(__MODULE__, [:public])



    listen_options = [
      mode: :binary,
      # everything is blocking and explicit
      active: false,
      # grab port if in use
      reuseaddr: true,
      #so we can keep writing on socket when client closes
      exit_on_close: false,
      # https://www.erlang.org/doc/man/inet.html#setopts-2
      packet: :line,
      buffer: @buffer_size
    ]

    # dbg(Logger.)

    case :gen_tcp.listen(@chat_port, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting budget chat server on port #{@chat_port}")
        state = %__MODULE__{listen_socket: listen_socket, supervisor: supervisor, ets: ets}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn ->
          handle_connection(socket, state.ets)
        end)

        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end


  def handle_connection(socket,ets) do
    :ok = :gen_tcp.send(socket, "What's your username?\n")

    # with packet: :line, _length should be ignored.
    # user has 5 minutes to respond.
    case :gen_tcp.recv(socket, _length=0, _timeout=300_000) do
      {:ok, line} ->
        username = String.trim(line)

        if username =~ ~r/^[[:alnum:]]+$/ do
          Logger.debug("Username: #{username} connected")
          # all_users = :ets.match(ets, {:_, :"$1"})
          # # returns [[username1],[usersname2],....]
          # :ok = :gen_tcp.send(socket,"* The room contains: #{Enum.join(all_users,", ")}\n")
          all_users = :ets.match(ets, :"$1")
          # returns [[socket1,username1],[socket2,usersname2],....]
          usernames = Enum.map_join(all_users, ", ", fn [{_socket, username}] -> username end)
          :ets.insert(ets, {socket,username})
          Enum.each(all_users, fn [{s,_u}] ->
            #Any process can send to a socket, but only the socket owning process can receive
            :gen_tcp.send(s, "* #{username} has entered the chat\n")
          end)
          :ok = :gen_tcp.send(socket,"* The room contains: #{usernames}\n")
          handle_chat_session(socket, ets, username)
        else
          :ok = :gen_tcp.send(socket, "Invalid username\n")
          :gen_tcp.close(socket)
        end

      {:error, _reason} ->
        :gen_tcp.close(socket)
        :ok
    end
  end

  defp handle_chat_session(socket, ets, username) do
    case :gen_tcp.recv(socket, _length=0, _timeout=300_000) do
      {:ok, message} ->
        if message != "" do
          message = String.trim(message)
          all_sockets = :ets.match(ets,{:"$1",:_})
          #note unpacking s from list of lists
          for [s] <- all_sockets, s != socket do
            # note we do not match on :ok this avoid concurrency problems, if
            # e.g. users leave or join between the :ets.match and the
            # :gen_tcp.send
            :gen_tcp.send(s, "[#{username}] #{message}\n")
          end
        end
        handle_chat_session(socket, ets, username)

      {:error, _reason} ->
          all_sockets = :ets.match(ets,{:"$1",:_})
          for [s] <- all_sockets, s != socket do
            :gen_tcp.send(s, "* #{username} left\n")
          end
          _ = :gen_tcp.close(socket)
          # delete the ets record using the key, which here is socket (the first
          # element of the tuple)
          #
          # This is a potential problem. If this process crashes, the shared resource
          # (the ets table) becomes corrupted, never shedding this entry.
          #
          # The ets table should be maintained by an overseer process which monitors
          # the spawned processes.
          :ets.delete(ets,socket)


    end
  end
end
