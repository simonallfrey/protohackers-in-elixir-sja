defmodule Protohackers.EchoServerTest do
  use ExUnit.Case
  use Protohackers.Constants

  test "echos anything back" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
    assert :gen_tcp.send(socket, "foo") == :ok
    assert :gen_tcp.send(socket, "bar") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, @timeout) == {:ok, "foobar"}
  end

  test "echo_server has max buffer size" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
    assert :gen_tcp.send(socket, :binary.copy("f", @limit + 1)) == :ok
    # :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0) == {:error, :closed}
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

end
