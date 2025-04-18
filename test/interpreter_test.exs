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

  test "execute if condition" do
    code = """
      actions do
        if true do
          "hello"
        end
      end
    """

    assert {:ok, "hello"} = Interpreter.execute(code)
  end

  test "execute if else condition" do
    code = """
      actions do
        if false do
          "hello"
        else
          "hi"
        end
      end
    """

    assert {:ok, "hi"} = Interpreter.execute(code)
  end

  test "execute in operator" do
    code = """

    actions do
      a = "b"
      if a in ["a", "b"] do
        "hello"
      end
    end
    """

    assert {:ok, "hello"} = Interpreter.execute(code)
  end

  test "execute global" do
    code = """
      @hello "123"
      actions do
        @hello
      end
    """

    assert {:ok, "123"} = Interpreter.execute(code)
  end
end
