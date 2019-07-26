defmodule Interpreter.ParserTest do
  use ExUnit.Case, async: true
  doctest Interpreter.Parser

  test "parse arithmetic op outside actions and conditions" do
    code = "2+2"
    assert {:error, :syntax} == Interpreter.Parser.parse(code)

    code = "2-2"
    assert {:error, :syntax} == Interpreter.Parser.parse(code)

    code = "2/2"
    assert {:error, :syntax} == Interpreter.Parser.parse(code)

    code = "2*2"
    assert {:error, :syntax} == Interpreter.Parser.parse(code)
  end

  test "parse empty action block" do
    code = """
      actions do
      end
    """

    assert {:ok, {:actions, [line: 1], [[do: {:__block__, [], []}]]}} ==
             Interpreter.Parser.parse(code)
  end

  test "parse one action" do
    code = """
      actions do
        2+2
      end
    """

    assert {:ok, {:actions, [line: 1], [[do: {:+, [line: 2], [2, 2]}]]}} =
             Interpreter.Parser.parse(code)
  end

  test "parse multiple actions" do
    code = """
      actions do
        2+2
        2+2
      end
    """

    assert {:ok,
            {:actions, [line: 1],
             [[do: {:__block__, [], [{:+, [line: 2], [2, 2]}, {:+, [line: 3], [2, 2]}]}]]}} =
             Interpreter.Parser.parse(code)
  end

  test "parse datetime trigger" do
    code = """
      trigger datetime: 05501051515
    """

    assert {:ok, {:trigger, [line: 1], [[datetime: 5_501_051_515]]}} =
             Interpreter.Parser.parse(code)
  end

  test "parse multiple trigger" do
    code = """
        trigger datetime: 05501051515
        trigger datetime: 05501051515
    """

    assert {:ok,
            {:__block__, [],
             [
               {:trigger, [line: 1], [[datetime: 5_501_051_515]]},
               {:trigger, [line: 2], [[datetime: 5_501_051_515]]}
             ]}} = Interpreter.Parser.parse(code)
  end

  test "parse invalid datetime trigger" do
    code = """
      trigger datetime: "hello"
    """

    assert {:error, :syntax} = Interpreter.Parser.parse(code)
  end

  test "parse unsupported trigger" do
    code = """
      trigger test: 0
    """

    assert {:error, :syntax} = Interpreter.Parser.parse(code)
  end

  test "parse origin_family condition" do
    code = """
      condition origin_family: biometric
    """

    assert {:ok, {:condition, [line: 1], [[origin_family: :biometric]]}} ==
             Interpreter.Parser.parse(code)
  end

  test "parse invalid origin_family condition" do
    code = """
      condition origin_family: :other
    """

    assert {:error, :syntax} = Interpreter.Parser.parse(code)
  end

  test "parse invalid condition" do
    code = """
      condition test: 0
    """

    assert {:error, :syntax} = Interpreter.Parser.parse(code)
  end

  test "parse post_paid_fee condition with valid hash" do
    hash = :crypto.hash(:sha256, "hello") |> Base.encode16(case: :lower)

    code = """
        condition post_paid_fee: "#{hash}"
    """

    assert {:ok,
            {:condition, [line: 1],
             [
               [
                 post_paid_fee: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
               ]
             ]}} ==
             Interpreter.Parser.parse(code)
  end

  test "parse post_paid_fee condition with invalid hash" do
    code = """
      condition post_paid_fee: "hello"
    """

    assert {:error, :syntax} = Interpreter.Parser.parse(code)
  end

  test "parse response condition" do
    code = """
      condition response: false
    """

    assert {:ok, {:condition, [line: 1], [[response: true]]}} ==
             Interpreter.Parser.parse(code)
  end

  test "parse inherit condition" do
    code = """
      condition inherit: true
    """

    assert {:ok, {:condition, [line: 1], [[inherit: true]]}} ==
             Interpreter.Parser.parse(code)
  end

  test "parse multiple conditions" do
    code = """
      condition response: true
      condition inherit: true
    """

    assert {:ok,
            {:__block__, [],
             [
               {:condition, [line: 1], [[response: true]]},
               {:condition, [line: 2], [[inherit: true]]}
             ]}} ==
             Interpreter.Parser.parse(code)
  end

  test "parse multiple triggers, conditions, actions" do
    code = """
      trigger datetime: 5105055060650160
      trigger datetime: 1348458454655658

      condition inherit: true
      condition response: true

      actions do
        a = "new_address"
        send_transaction(a)
      end
    """

    assert {:ok,
            {:__block__, [],
             [
               {:trigger, [line: 1], [[datetime: 5_105_055_060_650_160]]},
               {:trigger, [line: 2], [[datetime: 1_348_458_454_655_658]]},
               {:condition, [line: 4], [[inherit: true]]},
               {:condition, [line: 5], [[response: true]]},
               {:actions, [line: 7],
                [
                  [
                    do:
                      {:__block__, [],
                       [
                         {:=, [line: 8], [{:a, [line: 8], nil}, "new_address"]},
                         {:send_transaction, [line: 9], [{:a, [line: 9], nil}]}
                       ]}
                  ]
                ]}
             ]}} = Interpreter.Parser.parse(code)
  end

  test "parse variable" do
    code = """
      actions do
        a = "153"
      end
    """

    assert {:ok,
            {:actions, [line: 1],
             [
               [
                 do: {:=, [line: 2], [{:a, [line: 2], nil}, "153"]}
               ]
             ]}} == Interpreter.Parser.parse(code)
  end

  test "parse globals" do
    code = """
      address = "fdsfjsdkfjksjfksdjk"
      actions do
        a = @address
      end
    """

    assert {:ok,
            {:__block__, [],
             [
               {:=, [line: 1],
                [
                  {:address, [line: 1], nil},
                  "fdsfjsdkfjksjfksdjk"
                ]},
               {:actions, [line: 2],
                [
                  [
                    do:
                      {:=, [line: 3],
                       [
                         {:a, [line: 3], nil},
                         {:@, [line: 3], [{:address, [line: 3], nil}]}
                       ]}
                  ]
                ]}
             ]}} == Interpreter.Parser.parse(code)
  end
end
