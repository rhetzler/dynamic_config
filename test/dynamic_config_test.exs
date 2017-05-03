
defmodule NullaryConfig do
  @behaviour DynamicConfig
  def get_config(_) do
    [boot_time: Time.utc_now()]
  end
end

defmodule UnaryConfig do
  @behaviour DynamicConfig
  def get_config(val) do
    [service_url: System.get_env("#{val}_PORT")]
  end
end


defmodule DynamicConfigTest do
  use ExUnit.Case
  doctest DynamicConfig

  setup do
    Application.put_env(:dynamic_config, :foo, :bar)
    Application.put_env(:dynamic_config, :my_single, NullaryConfig)
    Application.put_env(:dynamic_config, :my_tuple, {UnaryConfig, :NEW})
    Application.put_env(:dynamic_config, :my_other_tuple, {UnaryConfig, :OLD})
  end

  # control
  test "read static config" do
    assert :bar == Application.get_env(:dynamic_config, :foo)
  end

  test "read config without preprocessing" do
    assert NullaryConfig == Application.get_env(:dynamic_config, :my_single)
    assert {UnaryConfig, :NEW} == Application.get_env(:dynamic_config, :my_tuple)
    assert {UnaryConfig, :OLD} == Application.get_env(:dynamic_config, :my_other_tuple)
  end

  test "read nullary config with preprocessing" do
    DynamicConfig.dynamically_update_config()
    assert [boot_time: %Time{}] = Application.get_env(:dynamic_config, :my_single)
  end

  test "read unary config with preprocessing" do
    new = "tcp://new:4000"
    old = "tcp://old:4000"
    System.put_env("NEW_PORT", new)
    System.put_env("OLD_PORT", old)
    DynamicConfig.dynamically_update_config()
    assert [service_url: ^new] = Application.get_env(:dynamic_config, :my_tuple)
    assert [service_url: ^old] = Application.get_env(:dynamic_config, :my_other_tuple)
  end

end
