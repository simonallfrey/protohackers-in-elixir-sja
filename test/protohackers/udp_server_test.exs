defmodule Protohackers.UDPServerTest do
  use ExUnit.Case, async: true

  use Protohackers.Constants

  @tag disabled: true
  test "fail" do
    assert "world is flat" == true
  end

  test "insert and retrieve requests" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false, recbuf: 1000])

    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @udp_port, "foo=1")
    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @udp_port, "foo")
    assert {:ok, {_address, _port, "foo=1"}} = :gen_udp.recv(socket, 0)

    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @udp_port, "foo=2")
    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @udp_port, "foo")
    assert {:ok, {_address, _port, "foo=2"}} = :gen_udp.recv(socket, 0)
  end

  test "version" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false, recbuf: 1000])

    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @udp_port, "version=foo")
    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @udp_port, "version")

    assert {:ok, {_address, _port, "version=Protohackers in Elixir 1.0"}} =
             :gen_udp.recv(socket, 0)
  end
end
