

defmodule DynamicConfigEnvTest do
  use ExUnit.Case
  doctest DynamicConfig.Env

  setup do
    Application.put_env(:dynamic_config, :user, {DynamicConfig.Env, :USER})
    Application.put_env(:dynamic_config, :current_dir, {DynamicConfig.Env, :PWD})
  end

  test "read config without preprocessing" do
    assert {DynamicConfig.Env, :USER} == Application.get_env(:dynamic_config, :user)
  end

  test "read config based on env vars" do
    DynamicConfig.Service.dynamically_update_config
    assert System.get_env("USER") == Application.get_env(:dynamic_config, :user)
    assert System.get_env("PWD") == Application.get_env(:dynamic_config, :current_dir)
    #IO.puts(System.get_env("USER"))
    #IO.puts(System.get_env("PWD"))
  end

end
