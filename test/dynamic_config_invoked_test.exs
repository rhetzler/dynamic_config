

defmodule DynamicConfigInvokedTest do
  use ExUnit.Case
  doctest DynamicConfig.Invoked

  def invokable do
    "result"
  end

  def invokable(arg) do
    arg * 3
  end

  def invokable(arg1,arg2,arg3) do
    arg1 + arg2 + arg3
  end

  setup do
    Application.put_env(:dynamic_config, :func, {DynamicConfig.Invoked, &DynamicConfigInvokedTest.invokable/0})
    Application.put_env(:dynamic_config, :func_with_arg, {DynamicConfig.Invoked, { &DynamicConfigInvokedTest.invokable/1, 4}})
    Application.put_env(:dynamic_config, :func_with_multiple_args, {DynamicConfig.Invoked, { &DynamicConfigInvokedTest.invokable/3, 4, 5, 6}})
  end

  test "read config without preprocessing" do
    # quoted strings resolve to strings
    assert {DynamicConfig.Invoked, &DynamicConfigInvokedTest.invokable/0} == Application.get_env(:dynamic_config, :func)

    assert {DynamicConfig.Invoked, {&DynamicConfigInvokedTest.invokable/1, 4}} == Application.get_env(:dynamic_config, :func_with_arg)

    assert {DynamicConfig.Invoked, {&DynamicConfigInvokedTest.invokable/3, 4, 5, 6}} == Application.get_env(:dynamic_config, :func_with_multiple_args)
  end

  test "read config based on invoked resolution" do
    DynamicConfig.dynamically_update_config()

    # "result"
    assert "result" == Application.get_env(:dynamic_config, :func)

    # 4 * 3 = 12
    assert 12 == Application.get_env(:dynamic_config, :func_with_arg)

    # 4 + 5 + 6 = 15
    assert 15 == Application.get_env(:dynamic_config, :func_with_multiple_args)
  end

end
