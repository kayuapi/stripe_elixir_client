defmodule Stripe do
  @external_resource Path.join(File.cwd!(), "abbreviatedSpec3.sdk.yaml")

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

              path_resource_variables =
                case x_stripe_operation["path_resource_variables"] do
                  nil ->
                    nil

                  _ ->
                    Enum.reduce(x_stripe_operation["path_resource_variables"], [], fn %{} =
                                                                                        path_resource_variable,
                                                                                      acc ->
                      method_parameter = path_resource_variable["method_parameter"]
                      [method_parameter | acc]
                    end)
                end

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

              total_arguments_count =
                case is_nil(path_resource_variables) do
                  true -> 0
                  false -> length(path_resource_variables)
                end

              total_arguments_count =
                total_arguments_count +
                  case length(propertiesList) > 0 do
                    true -> 1
                    false -> 0
                  end

              functionContentArgs = Macro.generate_arguments(total_arguments_count, __MODULE__)

              functionContent =
                quote do
                  def unquote(String.to_atom(method_name))(unquote_splicing(functionContentArgs)) do
                    # api_key = Application.fetch_env!(:stripe_elixir_client, :api_key)

                    functionContentArgs = unquote(functionContentArgs)
                    parameterIndex = Enum.find_index(functionContentArgs, fn x -> is_map(x) end)
                    requestedPath = unquote(x_stripe_operation["path"])

                    case functionContentArgs do
                      [] ->
                        Finch.build(
                          unquote(String.to_atom(operation)),
                          "https://api.stripe.com/#{unquote(x_stripe_operation["path"])}",
                          [{"Authorization", "Bearer sk_test_4eC39HqLyjWDarjtT1zdp7dc"}]
                        )

                      _ ->
                        pathVariableArgs =
                          if is_nil(parameterIndex) do
                            functionContentArgs
                          else
                            Enum.slice(functionContentArgs, 0, parameterIndex)
                          end

                        requestedPath =
                          Enum.reduce(pathVariableArgs, requestedPath, fn path_variable, acc ->
                            Regex.replace(
                              ~r/{(.*?)\}/,
                              acc,
                              to_string(path_variable),
                              global: false
                            )
                          end)

                        # IO.puts(inspect(requestedPath))

                        case parameterIndex do
                          nil ->
                            Finch.build(
                              unquote(String.to_atom(operation)),
                              "https://api.stripe.com/#{requestedPath}",
                              [{"Authorization", "Bearer sk_test_4eC39HqLyjWDarjtT1zdp7dc"}]
                            )

                          _ ->
                            Finch.build(
                              unquote(String.to_atom(operation)),
                              "https://api.stripe.com/#{requestedPath}",
                              [{"Authorization", "Bearer sk_test_4eC39HqLyjWDarjtT1zdp7dc"}],
                              URI.encode_query(Enum.at(functionContentArgs, parameterIndex))
                            )
                        end
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

        Module.create(
          String.to_atom("#{__MODULE__}.#{moduleName}"),
          functionAstList,
          Macro.Env.location(__ENV__)
        )

      %{} ->
        nil
    end
  end
end
