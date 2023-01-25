defmodule Protohackers.EchoServerTest do
  use ExUnit.Case
  use Protohackers.Constants
  require Logger

  test "echos anything back" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
    assert :gen_tcp.send(socket, "foo") == :ok
    assert :gen_tcp.send(socket, "bar") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, @timeout) == {:ok, "foobar"}
  end

  test "echo_server has at most max buffer size" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
    payload = :binary.copy(".", @buffer_size + 1)
    assert :gen_tcp.send(socket, payload) == :ok
    # :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0) == {:error, :closed}
  end

  test "echo_server has at least max buffer size recursive" do
    {:ok,socket} =
      :gen_tcp.connect(
        ~c"localhost",
        @echo_port,
        [
          mode: :binary,
          active: false,
        ]
      )
    dbg(:inet.getopts(socket, [:buffer]))
    dbg(@buffer_size)
    payload = :binary.copy(".", @buffer_size)
    assert :gen_tcp.send(socket, payload) == :ok
    :gen_tcp.shutdown(socket, :write)
    assert do_recv(socket, _buffer="") == {:ok, payload}
  end

  test "echo_server has at least max buffer size non-recursive" do
    {:ok,socket} =
      :gen_tcp.connect(
        ~c"localhost",
        @echo_port,
        [
          mode: :binary,
          active: false,
          buffer: @buffer_size
        ]
      )
    dbg(:inet.getopts(socket, [:buffer]))
    dbg(@buffer_size)
    payload = :binary.copy(".", @buffer_size)
    assert :gen_tcp.send(socket, payload) == :ok
    :gen_tcp.shutdown(socket, :write)
    # This grabs the whole payload, although by docs is not guaranteed to do so
    assert :gen_tcp.recv(socket, 0, @timeout) == {:ok, payload}
  end

  test "handles multiple concurrent connections" do
    tasks =
     for x <- 1..5 do
       Task.async(fn ->
        {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
        assert :gen_tcp.send(socket, "foo#{x}") == :ok
        assert :gen_tcp.send(socket, "bar#{x}") == :ok
        :gen_tcp.shutdown(socket, :write)
        assert :gen_tcp.recv(socket, 0, @timeout) == {:ok, "foo#{x}bar#{x}"}
       end)
     end

    Enum.each(tasks, &Task.await/1)
  end

  test "gen_tcp behaves as advertised" do
    for payload_size <- (1024*99)..(1024*110)//1 do
    # for payload_size <- 81381..81382//1 do
        port_options = [
        mode: :binary,
        active: false,       #everything is blocking and explicit
        reuseaddr: true,
        exit_on_close: false, #so we can keep writing on socket when client closes
        packet: :raw,
        recbuf: 1024*100,
        buffer: 1024*100
        ]
        {:ok,ls} = :gen_tcp.listen(7000, port_options)
        {:ok,cs} = :gen_tcp.connect(~c"localhost", 7000, port_options)
        {:ok,ss} = :gen_tcp.accept(ls)
        # dbg(:inet.getopts(ss, [:buffer]))
        dbg(:inet.getopts(ss, [:packet]))
        # following reports double the length of recbuf.
        {:ok, [recbuf: rb]} = :inet.getopts(ss, [:recbuf])
        # dbg(IEx.Info.info(rb))
        # dbg(inspect(rb))
        dbg(rb/payload_size)
        payload = :binary.copy("8", payload_size)
        # put payload in list to use iodata
        assert :gen_tcp.send(cs, [payload]) == :ok
        # assert :gen_tcp.send(cs, payload) == :ok
        :gen_tcp.shutdown(cs, :write)
        # with _length = 0 we get at most recbuf bytes
        # assert :gen_tcp.recv(ss, _length=0, @timeout) == {:ok, payload}
        # with _length specified we get that number of bytes (independent of recbuf)
        # assert :gen_tcp.recv(ss, _length = payload_size, @timeout) == {:ok, payload}
        # assert do_recv(ss,_buffer="") == {:ok, payload}
        for s <- [ls,cs,ss], do: :gen_tcp.close(s)
    end
  end

  test "gen_tcp behaves as advertised 2" do
    # auto conversion of iodata to binary
    for buffer_size <- [10] do
    # for buffer_size <- 0..(1024*100)//1024 do
        port_options = [
        mode: :binary,
        active: false,       #everything is blocking and explicit
        # reuseaddr: true,
        exit_on_close: false, #so we can keep writing on socket when client closes
        buffer: buffer_size
        ]
        {:ok,ls} = :gen_tcp.listen(@echo_port+10, port_options)
        {:ok,cs} = :gen_tcp.connect(~c"localhost", @echo_port+10, port_options)
        {:ok,ss} = :gen_tcp.accept(ls)
        # dbg(:inet.getopts(socket, [:buffer]))
        payload = :binary.copy("7", buffer_size)
        assert :gen_tcp.send(cs, payload) == :ok
        :gen_tcp.shutdown(cs, :write)
        assert {:ok, iodata} = do_recv_iodata(ss,_buffer="")
        dbg(iodata)
        assert :gen_tcp.send(ss,iodata) == :ok
        # This receives all the data, because it is sent as iodata?
        assert :gen_tcp.recv(cs, 0, @timeout) == {:ok, payload}
        for s <- [ls,cs,ss], do: :gen_tcp.close(s)
    end
  end

  def do_recv_iodata(socket, buffer) do
    case :gen_tcp.recv(socket,0,@timeout) do
      {:ok, data} -> do_recv_iodata(socket, [buffer,data])
      {:error, :closed} -> {:ok, buffer}
      other -> other
    end
  end

  def do_recv(socket, buffer) do
    case :gen_tcp.recv(socket,0,@timeout) do
      {:ok, data} -> do_recv(socket, buffer<>data)
      {:error, :closed} -> {:ok, buffer}
      other -> other
    end
  end

end
