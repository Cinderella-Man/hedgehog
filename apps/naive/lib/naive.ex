defmodule Naive do
  @moduledoc """
  Documentation for `Naive`.
  """
  alias Naive.DynamicSymbolSupervisor

  defdelegate start_trading(symbol), to: DynamicSymbolSupervisor, as: :start_worker
  defdelegate stop_trading(symbol), to: DynamicSymbolSupervisor, as: :stop_worker
  defdelegate shutdown_trading(symbol), to: DynamicSymbolSupervisor
end
