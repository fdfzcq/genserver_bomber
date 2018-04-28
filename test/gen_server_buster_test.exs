defmodule GenServerBusterTest do
  use ExUnit.Case
  doctest GenServerBuster

  test "greets the world" do
    assert GenServerBuster.hello() == :world
  end
end
