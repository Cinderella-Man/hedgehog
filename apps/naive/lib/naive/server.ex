defmodule Naive.Server do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}}
  end
end