defmodule AicTest do
  use ExUnit.Case
  doctest Aic

  test "greets the world" do
    assert Aic.hello() == :world
  end
end
