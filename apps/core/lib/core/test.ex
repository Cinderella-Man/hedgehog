defmodule Core.Test do

  defmodule PubSub do
    @type t :: atom
    @type topic :: binary
    @type message :: term

    @callback subscribe(t, topic) :: :ok | {:error, term}
    @callback broadcast(t, topic, message) :: :ok | {:error, term}
  end

  defmodule Logger do
    @type message :: binary

    @callback info(message) :: :ok
  end

end
