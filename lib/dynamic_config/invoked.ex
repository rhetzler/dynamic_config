defmodule DynamicConfig.Invoked do
  @moduledoc """
  DynamicConfig.Quoted

  A quoted expression invoker

  ```
  config :my_app, :my_key, {DynamicConfig.Env, quote()}
  ```
  """

  @behaviour DynamicConfig

  def get_config(func) when is_function(func,0) do
    func.()
  end

  def get_config({func, arg}) when is_function(func,1) do
    func.(arg)
  end

  # wasn't really intending to add support for more than 1 arg, since anything can be embedded in a tuple
  # adding 2, 3 and 4 args for convenience. Beyond that, write your own handler or embed in a tuple/map

  def get_config({func, arg1, arg2}) when is_function(func,2) do
    func.(arg1, arg2)
  end

  def get_config({func, arg1, arg2, arg3}) when is_function(func,3) do
    func.(arg1, arg2, arg3)
  end

  def get_config({func, arg1, arg2, arg3, arg4}) when is_function(func,4) do
    func.(arg1, arg2, arg3, arg4)
  end
end