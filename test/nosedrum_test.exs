defmodule NosedrumTest do
  use ExUnit.Case
  doctest Nosedrum

  test "greets the world" do
    assert Nosedrum.hello() == :world
  end
end
