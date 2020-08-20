defmodule DataWarehouseTest do
  use ExUnit.Case
  doctest DataWarehouse

  test "greets the world" do
    assert DataWarehouse.hello() == :world
  end
end
