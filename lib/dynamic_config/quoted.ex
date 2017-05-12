defmodule DynamicConfig.Quoted do
  @moduledoc """
  DynamicConfig.Quoted

  A quoted expression invoker

  ```
  config :my_app, :my_key, {DynamicConfig.Env, quote(do: whatever)}
  ```
  """

  @behaviour DynamicConfig

  def get_config(quoted_expression) do
    {result, _ } = Code.eval_quoted(quoted_expression)
    result
  end
end