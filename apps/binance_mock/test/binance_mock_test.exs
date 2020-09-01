defmodule BinanceMockTest do
  use ExUnit.Case
  doctest BinanceMock

  test "greets the world" do
    assert BinanceMock.hello() == :world
  end
end
