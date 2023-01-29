defmodule Protohackers.UDPServer do

  use GenServer

  use Protohackers.Constants

  def start_link([]=_opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  defstruct store: %{}

  @impl true
  def init(:no_state) do
    {:ok, %__MODULE__{}}
  end


end
