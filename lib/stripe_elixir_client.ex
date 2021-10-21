defmodule StripeElixirClient do
  @moduledoc """
  Documentation for `StripeElixirClient`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> StripeElixirClient.hello()
      :world

  """

  path = Path.join(File.cwd!(), "abbreviatedSpec3.sdk.yaml")

  {:ok,
   %{
     "components" => %{
       "schemas" => schemas
     }
   }} = YamlElixir.read_from_file(path)

  for {schema, attributes} <- schemas do
    moduleName = String.to_atom(Macro.camelize(schema))
    # IO.puts(inspect(moduleName))
    # IO.puts(inspect(attributes))

    functionAstList =
      case attributes do
        %{"x-stripeOperations" => x_stripe_operations} ->
          functionAstList =
            Enum.reduce(x_stripe_operations, [], fn %{} = x_stripe_operation, acc ->
              if x_stripe_operation["method_on"] == "service" do
                # IO.puts("**********")
                # IO.puts(x_stripe_operation["method_name"])

                functionContent =
                  quote do
                    def unquote(String.to_atom(x_stripe_operation["method_name"]))(), do: true
                  end

                [functionContent | acc]
              else
                [acc]
              end
            end)

          # IO.puts("functionAstList")
          # IO.puts(inspect(functionAstList))
          functionAstList

        %{} ->
          nil
      end

    Module.create(
      String.to_atom("#{__MODULE__}.#{moduleName}"),
      functionAstList,
      Macro.Env.location(__ENV__)
    )
  end
end
