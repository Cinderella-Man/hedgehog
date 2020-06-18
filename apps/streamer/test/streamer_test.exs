defmodule StreamerTest do
  use ExUnit.Case
  doctest Streamer

  test "greets the world" do
    assert Streamer.hello() == :world
  end
end
