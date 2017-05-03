

defmodule DynamicConfigQuotedTest do
  use ExUnit.Case
  doctest DynamicConfig.Quoted

  def some_func(arg) do
    arg * 2
  end


  setup do
    Application.put_env(:dynamic_config, :string, {DynamicConfig.Quoted, quote(do: "test")})
    Application.put_env(:dynamic_config, :basic_expression, {DynamicConfig.Quoted, quote(do: 1 + 2)})
    Application.put_env(:dynamic_config, :function_call, {DynamicConfig.Quoted, quote(do: DynamicConfigQuotedTest.some_func(3))})
  end

  test "read config without preprocessing" do
    # quoted strings resolve to strings
    assert {DynamicConfig.Quoted, "test"} == Application.get_env(:dynamic_config, :string)

    # more complex quoted expressions have their own syntax
    assert {DynamicConfig.Quoted, {
        {:., [], [{:__aliases__, [alias: false], [:DynamicConfigQuotedTest]}, :some_func]},
            [], [3]}
        } == Application.get_env(:dynamic_config, :function_call)

    # some operator stuff which i don't want to resolve for the purpose of this test...
    assert {DynamicConfig.Quoted, quote(do: 1 + 2)} == Application.get_env(:dynamic_config, :basic_expression)
  end

  test "read config based on quote resolution" do
    DynamicConfig.Service.dynamically_update_config

    # "test"
    assert "test" == Application.get_env(:dynamic_config, :string)

    # 1 + 2 = 3
    assert 3 == Application.get_env(:dynamic_config, :basic_expression)

    # 3 *2 = 6
    assert 6 == Application.get_env(:dynamic_config, :function_call)
  end

end
