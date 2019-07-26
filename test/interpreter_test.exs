defmodule InterpreterTest do
  use ExUnit.Case, async: true

  test "execute contract with one action" do
    code = """
      actions do
        2+2
      end
    """

    assert {:ok, 4} = Interpreter.execute(code)
  end

  test "execute contract with triggers" do
    code = """
      trigger datetime: 05501051515
      actions do
        2+2
      end
    """

    assert {:ok, 4} = Interpreter.execute(code)
  end

  test "execute contract with conditions" do
    code = """
      condition response: true
      actions do
        2+2
      end
    """

    assert {:ok, 4} = Interpreter.execute(code)
  end

  test "execute contract with variable assignation" do
    code = """
      actions do
        a = "hello"
        a
      end
    """

    assert {:ok, "hello"} = Interpreter.execute(code)
  end
end
