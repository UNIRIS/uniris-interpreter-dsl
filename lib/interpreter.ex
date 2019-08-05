defmodule Interpreter do
  def execute(code) do
    {:ok, ast} = Interpreter.Parser.parse(code)
    {:ok, contract} = build_contract(ast)

    q = quote do
      defmodule Contract do

        unquote contract.globals
          |> Enum.map(fn {key, val} ->
            "@#{Atom.to_string(key)} #{inspect val}"
          end)
          |> Enum.map(fn global ->
            {:ok, quoted} = Code.string_to_quoted(global)
            quoted
          end)

        def execute_action do
          res = unquote contract.actions
          {:ok, res}
        end

      end
    end

    {{:module, contract, _code, _methods}, []} = Code.eval_quoted(q)
    contract.execute_action
  end

  defp build_contract({:actions, _, [[do: {:__block__, _, elems} = actions]]})
       when is_list(elems),
       do: {:ok, %{actions: actions, globals: []}}

  defp build_contract({:actions, _, [[do: elems]]}) when is_tuple(elems),
    do: {:ok, %{actions: elems, globals: []}}

  defp build_contract({:__block__, [], elems}) do
    contract =
      Enum.reduce(elems, %{triggers: [], conditions: [], actions: [], globals: []}, fn (e, contract) ->
        case e do
          {:@, _, [{token, _, [value]}]} ->
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

          {:actions, _, [[do: {:__block__, _, elems} = actions]]} when is_tuple(elems) ->
            Map.put(contract, :actions, actions)

          {:actions, _, [[do: elems]]} when is_tuple(elems) ->
            Map.put(contract, :actions, elems)
        end
      end)

    {:ok, contract}
  end
end
