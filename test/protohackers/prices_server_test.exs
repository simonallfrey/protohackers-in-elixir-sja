defmodule Protohackers.PricesServer.Test do
  use ExUnit.Case, async: true
  use Protohackers.Constants

  # alias Protohackers.PricesServer.DB

  test "handles queries" do
    port_opts = [
      mode: :binary,
      active: false,
    ]
    {:ok, socket} = :gen_tcp.connect(~c"localhost",@prices_port, port_opts)
    :gen_tcp.send(socket, <<?I, 1000::32-signed-big, 1::32-signed-big>>)
    :gen_tcp.send(socket, <<?I, 2000::32-signed-big, 2::32-signed-big>>)
    :gen_tcp.send(socket, <<?I, 3000::32-signed-big, 3::32-signed-big>>)


    :gen_tcp.send(socket, <<?Q, 1000::32-signed-big, 3000::32-signed-big>>)
    assert :gen_tcp.recv(socket, 4, @timeout) == {:ok, <<2::32-signed-big>>}
  end

  test "handles parallel  queries" do
    port_opts = [
      mode: :binary,
      active: false,
    ]
    {:ok, socket1} = :gen_tcp.connect(~c"localhost",@prices_port, port_opts)
    {:ok, socket2} = :gen_tcp.connect(~c"localhost",@prices_port, port_opts)
    {:ok, socket3} = :gen_tcp.connect(~c"localhost",@prices_port, port_opts)
    {:ok, socket4} = :gen_tcp.connect(~c"localhost",@prices_port, port_opts)
    :gen_tcp.send(socket1, <<?I, 1000::32-signed-big, 1::32-signed-big>>)
    :gen_tcp.send(socket2, <<?I, 2000::32-signed-big, 2::32-signed-big>>)
    :gen_tcp.send(socket3, <<?I, 2000::32-signed-big, 3::32-signed-big>>)
    :gen_tcp.send(socket4, <<?I, 2000::32-signed-big, 4::32-signed-big>>)

    :gen_tcp.send(socket1, <<?Q, 1000::32-signed-big, 3000::32-signed-big>>)
    assert :gen_tcp.recv(socket1, 4, @timeout) == {:ok, <<1::32-signed-big>>}

    :gen_tcp.send(socket2, <<?Q, 1000::32-signed-big, 3000::32-signed-big>>)
    assert :gen_tcp.recv(socket2, 4, @timeout) == {:ok, <<2::32-signed-big>>}

    :gen_tcp.send(socket3, <<?Q, 1000::32-signed-big, 3000::32-signed-big>>)
    assert :gen_tcp.recv(socket3, 4, @timeout) == {:ok, <<3::32-signed-big>>}

    :gen_tcp.send(socket4, <<?Q, 1000::32-signed-big, 3000::32-signed-big>>)
    assert :gen_tcp.recv(socket4, 4, @timeout) == {:ok, <<4::32-signed-big>>}
  end

end
