defmodule Streamer do
  @moduledoc """
  Documentation for `Streamer`.
  """
  alias Streamer.DynamicStreamerSupervisor

  defdelegate start_streaming(symbol), to: DynamicStreamerSupervisor
  defdelegate stop_streaming(symbol), to: DynamicStreamerSupervisor
end
