defmodule Naive.LeaderBehaviour do

  alias Naive.Trader

  @type event_type :: atom
  @callback notify(event_type, %Trader.State{}) :: :ok

end
