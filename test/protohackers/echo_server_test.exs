defmodule Protohackers.EchoServerTest do
  use ExUnit.Case, async: true
  use Protohackers.Constants
  require Logger

  test "echos anything back" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
    assert :gen_tcp.send(socket, "foo") == :ok
    assert :gen_tcp.send(socket, "bar") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, @timeout) == {:ok, "foobar"}
  end

  @tag :capture_log
  test "echo_server has at most max buffer size" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
    payload = :binary.copy(".", @buffer_size + 1)
    assert :gen_tcp.send(socket, payload) == :ok
    # :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0) == {:error, :closed}
  end

  @tag :capture_log
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
    # dbg(:inet.getopts(socket, [:buffer]))
    # dbg(@buffer_size)
    payload = :binary.copy(".", @buffer_size)
    assert :gen_tcp.send(socket, payload) == :ok
    :gen_tcp.shutdown(socket, :write)
    assert do_recv(socket, _buffer="") == {:ok, payload}
  end

  @tag :capture_log
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
    # dbg(:inet.getopts(socket, [:buffer]))
    # dbg(@buffer_size)
    payload = :binary.copy(".", @buffer_size)
    assert :gen_tcp.send(socket, payload) == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, @buffer_size, @timeout) == {:ok, payload}
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

  @tag timeout: :infinity
  @tag disabled: true
  test "true buffer sizes" do
    payload_size = 612992+1
    payload = :binary.copy("8", payload_size)
    file = File.open!('recbuf.csv',[:write,:utf8])
    for buffer_size <- 1024..612992//100 do
      port_options = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false,
      packet: :raw,
      sndbuf: buffer_size,  # max from /proc/sys/net/core/wmem_max = 212992
      recbuf: buffer_size,  # max from /proc/sys/net/core/rmem_max = 212992
      buffer: payload_size,
      ]
      {:ok,ls} = :gen_tcp.listen(7000, port_options)
      {:ok,cs} = :gen_tcp.connect(~c"localhost", 7000, port_options)
      {:ok,ss} = :gen_tcp.accept(ls)
      assert :gen_tcp.send(cs, payload) == :ok
      :gen_tcp.shutdown(cs, :write)
      {:ok, [recbuf: rb]} = :inet.getopts(ss, [:recbuf])
      {:ok, received} = :gen_tcp.recv(ss, _length=0, @timeout)
      bsr = byte_size(received)
      # dbg({buffer_size,bsr,bsr/buffer_size})
      IO.puts(file,"#{buffer_size},#{div(rb,2)},#{bsr}")
      :gen_tcp.recv(ss, payload_size-bsr, @timeout)
      for s <- [ls,cs,ss], do: :gen_tcp.close(s)
    end
    File.close(file)
  end

  @tag disabled: true
  test "gen_tcp behaves as advertised" do
    # for payload_size <- (1024*240)..(1024*241)//1 do
    for payload_size <- 245790..245801//1 do
        port_options = [
        inet_backend: :inet,
        mode: :binary,
        active: false,       #everything is blocking and explicit
        reuseaddr: true,
        exit_on_close: false, #so we can keep writing on socket when client closes
        packet: :raw,
        sndbuf: 212980,  # max from /proc/sys/net/core/wmem_max
        recbuf: 212980,  # max from /proc/sys/net/core/rmem_max
        buffer: payload_size,
        ]
        {:ok,ls} = :gen_tcp.listen(7000, port_options)
        {:ok,cs} = :gen_tcp.connect(~c"localhost", 7000, port_options)
        {:ok,ss} = :gen_tcp.accept(ls)
        # the next 2 max out at 0x68000 (425984)
        # which is 2 x
        # /proc/sys/net/core/{w,r}mem_max = 212992
        # see: man tcp
        # if not maxed they are 2x the vaule set in :gen_tcp.listen see:
        # https://erlang.org/pipermail/erlang-questions/2011-August/060851.html
        dbg(:inet.getopts(ss, [:recbuf]))
        dbg(:inet.getopts(ss, [:sndbuf]))
        dbg(payload_size)
        dbg(:inet.getopts(ss, [:buffer]))
        dbg(:inet.getopts(ss, [:packet]))
        # :timer.sleep(20_000)
        # following reports double the length of recbuf.
        {:ok, [recbuf: rb]} = :inet.getopts(ss, [:recbuf])
        dbg(div(rb,2))
        # dbg(IEx.Info.info(rb))
        # dbg(inspect(rb))
        payload = :binary.copy("8", payload_size)
        dbg(byte_size(payload))
        dbg(payload_size)
        # put payload in list to use iodata
        # assert :gen_tcp.send(cs, [payload]) == :ok
        assert :gen_tcp.send(cs, payload) == :ok
        :gen_tcp.shutdown(cs, :write)
        # with _length = 0 we get at most recbuf bytes
        assert :gen_tcp.recv(ss, _length=0, @timeout) == {:ok, payload}
        # with _length specified we get that number of bytes (independent of recbuf)
        # assert :gen_tcp.recv(ss, _length = payload_size, @timeout) == {:ok, payload}
        # assert do_recv(ss,_buffer="") == {:ok, payload}
        for s <- [ls,cs,ss], do: :gen_tcp.close(s)
    end
  end

  @tag disabled: true
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
