defmodule NaiveTest do
  use ExUnit.Case
  doctest Naive

  test "greets the world" do
    assert Naive.hello() == :world
  end
end
