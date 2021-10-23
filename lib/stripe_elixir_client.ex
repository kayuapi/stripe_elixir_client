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
  @external_resource Path.join(File.cwd!(), "abbreviatedSpec3.sdk.yaml")
  use Application

  def start(_start_type, _args) do
    Finch.start_link(name: StripeHttpClient)
  end

  path = Path.join(File.cwd!(), "abbreviatedSpec3.sdk.yaml")

  {:ok,
   %{
     "components" => %{
       "schemas" => schemas
     },
     "paths" => paths
   }} = YamlElixir.read_from_file(path)

  # IO.puts(inspect(paths))

  for {schema, attributes} <- schemas do
    moduleName = String.to_atom(Macro.camelize(schema))
    IO.puts(inspect(moduleName))
    # IO.puts(inspect(attributes))

    functionAstList =
      case attributes do
        %{"x-stripeOperations" => x_stripe_operations} ->
          functionAstList =
            Enum.reduce(x_stripe_operations, [], fn %{} = x_stripe_operation, acc ->
              if x_stripe_operation["method_on"] == "service" do
                # IO.puts("**********")
                # IO.puts(x_stripe_operation["method_name"])

                path = x_stripe_operation["path"]
                method_name = x_stripe_operation["method_name"]
                operation = x_stripe_operation["operation"]

                # IO.puts(inspect(path))
                # IO.puts(inspect(method_name))
                # IO.puts(inspect(operation))

                %{
                  ^path => %{
                    ^operation => %{
                      "requestBody" => %{
                        "content" => %{
                          "application/x-www-form-urlencoded" => %{
                            "schema" => %{"properties" => properties}
                          }
                        }
                      }
                    }
                  }
                } = paths

                propertiesList = Map.keys(properties)

                # propertiesListLength = length(propertiesList)

                # functionContentArgs = Macro.generate_arguments(1, __MODULE__)
                functionContentArgs =
                  if length(propertiesList) > 0 do
                    Macro.generate_arguments(1, __MODULE__)
                  else
                    Macro.generate_arguments(0, __MODULE__)
                  end

                functionContent =
                  quote do
                    def unquote(String.to_atom(method_name))(
                          unquote_splicing(functionContentArgs)
                        ) do
                      # api_key = Application.fetch_env!(:stripe_elixir_client, :api_key)
                      case (unquote_splicing(functionContentArgs)) do
                        nil ->
                          Finch.build(
                            unquote(String.to_atom(operation)),
                            "https://api.stripe.com/#{unquote(x_stripe_operation["path"])}",
                            [{"Authorization", "Bearer sk_test_4eC39HqLyjWDarjtT1zdp7dc"}]
                          )

                        _ ->
                          Finch.build(
                            unquote(String.to_atom(operation)),
                            "https://api.stripe.com/#{unquote(x_stripe_operation["path"])}",
                            [{"Authorization", "Bearer sk_test_4eC39HqLyjWDarjtT1zdp7dc"}],
                            URI.encode_query((unquote_splicing(functionContentArgs)))
                          )
                      end
                      |> Finch.request(StripeHttpClient)
                      |> case do
                        {:ok, %Finch.Response{body: body}} -> Jason.decode!(~s(#{body}))
                        {_, nil} -> nil
                      end
                    end
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
