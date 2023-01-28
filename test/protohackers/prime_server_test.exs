defmodule Protohackers.PrimeServerTest do
  use ExUnit.Case, async: true
  use Protohackers.Constants

  test "echos back JSON" do
    {:ok,socket} = :gen_tcp.connect(~c"localhost", @prime_port, mode: :binary, active: false)
    payload = %{method: "isPrime", number: 7}
    :gen_tcp.send(socket, Jason.encode!(payload) <> "\n")
    assert {:ok, data} = :gen_tcp.recv(socket, 0, @prime_port)
    assert String.ends_with?(data, "\n")
    assert Jason.decode!(data) == %{"method" => "isPrime", "prime" => true}
    payload = %{method: "isPrime", number: 6}
    :gen_tcp.send(socket, Jason.encode!(payload) <> "\n")
    assert {:ok, data} = :gen_tcp.recv(socket, 0, @prime_port)
    assert String.ends_with?(data, "\n")
    assert Jason.decode!(data) == %{"method" => "isPrime", "prime" => false}
  end

  # test "echo_server has max buffer size" do
  #   {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
  #   assert :gen_tcp.send(socket, :binary.copy("f", @limit + 1)) == :ok
  #   # :gen_tcp.shutdown(socket, :write)
  #   assert :gen_tcp.recv(socket, 0) == {:error, :closed}
  # end

  # test "handles multiple concurrent connections" do
  #   tasks =
  #    for x <- 1..5 do
  #      Task.async(fn ->
  #       {:ok,socket} = :gen_tcp.connect(~c"localhost", @echo_port, [mode: :binary, active: false])
  #       assert :gen_tcp.send(socket, "foo#{x}") == :ok
  #       assert :gen_tcp.send(socket, "bar#{x}") == :ok
  #       :gen_tcp.shutdown(socket, :write)
  #       assert :gen_tcp.recv(socket, 0, @timeout) == {:ok, "foo#{x}bar#{x}"}
  #      end)
  #    end

  #   Enum.each(tasks, &Task.await/1)
  # end

end
