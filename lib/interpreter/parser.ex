defmodule Interpreter.Parser do
  @origin_families [:biometric]

  def parse(code) do
    with code <- String.trim(code),
         {:ok, ast} <- Code.string_to_quoted(code),
         {filter_ast, {:ok, _}} <- Macro.prewalk(ast, {:ok, :root}, &filter_ast/2) do
      {:ok, filter_ast}
    else
      {:error, _} = e ->
        e

      {_, {:error, :syntax} = e} ->
        e
    end
  end

  defp filter_ast({:actions, _, [[do: _]]} = node, {:ok, :root}) do
    {node, {:ok, :actions}}
  end

  defp filter_ast({:__block__, _, _} = node, {:ok, scope} = acc)
       when scope in [:actions, :root] do
    {node, acc}
  end

  defp filter_ast({:trigger, _, [[datetime: datetime]]} = node, {:ok, :root} = acc)
       when is_number(datetime) do
    if datetime > DateTime.to_unix(DateTime.utc_now()) do
      {node, acc}
    else
      {node, {:error, :syntax}}
    end
  end

  defp filter_ast({:condition, _, [[origin_family: family]]} = node, {:ok, :root} = acc)
       when family in @origin_families do
    {node, acc}
  end

  defp filter_ast({:condition, _, [[post_paid_fee: address]]} = node, {:ok, :root} = acc)
       when is_binary(address) do
    if String.match?(address, ~r/^[A-Fa-f0-9]{64}$/) do
      {node, acc}
    else
      {node, {:error, :syntax}}
    end
  end

  defp filter_ast({:condition, _, [[response: _]]} = node, {:ok, _} = acc), do: {node, acc}
  defp filter_ast({:condition, _, [[inherit: _]]} = node, {:ok, _} = acc), do: {node, acc}

  defp filter_ast({:+, _, _} = node, {:ok, scope} = acc) when scope in [:actions],
    do: {node, acc}

  defp filter_ast({:-, _, _} = node, {:ok, scope} = acc) when scope in [:actions],
    do: {node, acc}

  defp filter_ast({:/, _, _} = node, {:ok, scope} = acc) when scope in [:actions],
    do: {node, acc}

  defp filter_ast({:*, _, _} = node, {:ok, scope} = acc) when scope in [:actions],
    do: {node, acc}

  defp filter_ast(true, {:ok, _} = acc), do: {true, acc}
  defp filter_ast(false, {:ok, _} = acc), do: {true, acc}
  defp filter_ast(number, {:ok, _} = acc) when is_number(number), do: {number, acc}
  defp filter_ast(string, {:ok, _} = acc) when is_binary(string), do: {string, acc}
  defp filter_ast([_] = node, {:ok, _} = acc), do: {node, acc}
  defp filter_ast({:do, _} = node, {:ok, _} = acc), do: {node, acc}
  defp filter_ast(key, {:ok, _} = acc) when is_atom(key), do: {key, acc}
  defp filter_ast({key, _} = node, {:ok, _} = acc) when is_atom(key), do: {node, acc}

  defp filter_ast({:=, _, _} = node, {:ok, scope} = acc) when scope in [:root, :actions],
    do: {node, acc}

  defp filter_ast({var, _, nil} = node, {:ok, scope} = acc)
       when is_atom(var)
       when scope in [:root, :actions],
       do: {node, acc}

  defp filter_ast({fn_id, _, [_]} = node, {:ok, :actions} = acc) when is_atom(fn_id),
    do: {node, acc}

  defp filter_ast(node, {:ok, _}) do
    {node, {:error, :syntax}}
  end

  defp filter_ast(node, {:error, _} = e), do: {node, e}
end
