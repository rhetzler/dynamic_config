defmodule DynamicConfig.Env do
  @moduledoc """
  DynamicConfig.Env

  An environment variable reader intended to be a drop-in replacement for REPLACE_OS_VARS

  instead of
  ```
  config :my_app, :my_key, "${MY_VAR}"
  ```
  and booting with:
  ```
  REPLACE_OS_VARS=true /path/to/my/app
  ```

  simply make sure DynamicConfig is configured with your app and use:
  ```
  config :my_app, :my_key, {DynamicConfig.Env, :MY_VAR}
  ```
  """

  @behaviour DynamicConfig

  def get_config(var_name) do
    System.get_env("#{var_name}")
  end
end