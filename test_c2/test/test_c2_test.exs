defmodule TestC2Test do
  use ExUnit.Case
  doctest TestC2

  test "greets the world" do
    assert TestC2.hello() == :world
  end
end
