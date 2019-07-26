defmodule Interpreter do
  def execute(code) do
    with {:ok, ast} <- Interpreter.Parser.parse(code),
         {:ok, contract} <- build_contract(ast),
         {res, _} <- Code.eval_quoted(contract.actions, contract.globals) do
      {:ok, res}
    else
      {:error, _} = e ->
        e
    end
  end

  defp build_contract({:actions, _, [[do: {:__block__, _, elems}]]}) when is_list(elems),
    do: {:ok, %{actions: elems, globals: []}}

  defp build_contract({:actions, _, [[do: elems]]}) when is_tuple(elems),
    do: {:ok, %{actions: elems, globals: []}}

  defp build_contract({:__block__, [], elems}) do
    contract =
      Enum.reduce(elems, %{triggers: [], conditions: [], actions: [], globals: []}, fn e,
                                                                                       contract ->
        case e do
          {:=, _, [{token, _, nil}, value]} ->
            Map.put(contract, :globals, Keyword.put(contract.globals, token, value))

          {:trigger, _, [props]} ->
            trigger_type = Keyword.keys(props) |> List.first()

            Map.put(
              contract,
              :triggers,
              contract.triggers ++
                [%{type: trigger_type, value: Keyword.get(props, trigger_type)}]
            )

          {:condition, _, [props]} ->
            condition_type = Keyword.keys(props) |> List.first()

            Map.put(
              contract,
              :conditions,
              contract.conditions ++
                [%{type: condition_type, value: Keyword.get(props, condition_type)}]
            )

          {:actions, _, [[do: {:__block__, _, elems}]]} when is_tuple(elems) ->
            Map.put(contract, :actions, elems)

          {:actions, _, [[do: elems]]} when is_tuple(elems) ->
            Map.put(contract, :actions, elems)
        end
      end)

    {:ok, contract}
  end
end
