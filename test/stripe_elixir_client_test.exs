defmodule StripeElixirClientTest do
  use ExUnit.Case
  doctest StripeElixirClient

  test "greets the world" do
    assert StripeElixirClient.hello() == :world
  end
end
