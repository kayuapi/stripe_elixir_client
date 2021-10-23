defmodule StripeElixirClient do
  @moduledoc """
  Documentation for `StripeElixirClient`.
  """

  @doc """
  StripeElixirClient is a library which consists of 2 parts:
    1. parses Stripe's open API document from https://github.com/stripe/openapi
    2. generates a SDK which wraps around underlying Finch-based HTTP client

  It aims to be easy to use by adhering closely to https://stripe.com/docs/api

  ## Examples

      iex> Stripe.Balance.retrieve()
      :world

  """

  use Application
  import Stripe

  def start(_start_type, _args) do
    # Finch.start_link(name: StripeHttpClient)
    StripeElixirClient.Supervisor.start_link(name: StripeElixirClient.Supervisor)
  end
end
