defmodule Naive do
  @moduledoc """
  Documentation for `Naive`.
  """
  alias Naive.DynamicSymbolSupervisor

  defdelegate start_trading(symbol), to: DynamicSymbolSupervisor
  defdelegate stop_trading(symbol), to: DynamicSymbolSupervisor
  defdelegate shutdown_trading(symbol), to: DynamicSymbolSupervisor
end
