defmodule DynamicConfig do
  @callback get_config(any) :: any

  @moduledoc """
  DynamicConfig

  The compiled & static nature of config.exs / mix.config is hostile to cloud-native configuration schemes,
  where the application is expected to get it's configuration from the environment it runs in, rather than
  at compile time.

  Distillery's REPLACE_OS_VARS parameter and it's predecessors (RELX_REPLACE_OS_VARS) make some attempt
  to serve the need, but it is inherently limited to what is available in the execution runtime's ENV
  variables, is OS-specific, and uses OS tools to make local edits to a compiled file (mix.config)

  One solution put forth is to have library developers provide on_init hooks. This pushes a concern which
  really ought to be handled by the framework as a burden to library developers who may or may not choose
  to implement some boilerplate. This is not ideal.

  An ideal solution perhaps might be to have adoption of some sort of dynamic config mechanism which
  allows for dynamic fetch. Perhaps such a thing could wrap Application but otherwise provide the ability
  to set callbacks.

  The initial implementation provides an idempotent DynamicConfig.dynamically_update_config() which is
  suitable for one-time use during boot, to "mutate" the config to the values needed for runtime. After
  the first invocation, the DynamicConfig annotations in the configuration will be replaced by their
  resolved values and thus cannot be re-evaluated.

  Boot-time configuration (makes use of boot phases) - this depends on your boot order, and whether the
  configs you're trying to affect are loaded before your app's boot or after (application vs included_application)

  in mix.exs:
  ```
  defp deps do
    [ {:dynamic_config, "~> 0.1.0" } ]
  end

  # if you already have start_phases, add to the list rather than replacing, of course.
  def application do
    [
       ...
       start_phases: [dynamic_config: []]
       ...
    ]
  end
  ```

  in your application module (ie, lib/my_app.ex)
  ```
  defmodule MyApp do
    use Application

    ...

    def start_phase(:dynamic_config, _, _) do
      DynamicConfig.dynamically_update_config()
    end
  end
  ```

  a dynamic configuration can take on any of the following three forms:

  ```
  config :my_app, :my_key1, MyDynamicConfigModule

  config :my_app, :my_key2, {MyDynamicConfigModule, args}

  config :my_app, :my_key3, key1: value1,
    key2: value2,
    dynamic_config: MyDynamicConfigModule
  ```

  In all cases, we expect a module with the DynamicConfig behaviour (ie, implements get_config/1)

  The first form assumes no arguments are necessary and will pass nil as the argument
  The second form, passes in a (single) "any" value as specified by args. this can be a map, keyword list, string, or whatever you want

  The third form is not recommended but is included to support configs that mix environment concerns with compile-time concerns
  (cough, Ecto), such as compile-time loading of adapter libraries. In the third case, the whole keyword list is passed in to args.

  """

  @doc """
  Dynamically update the configuration. suitable for use at boot time

  ## Examples

      iex> DynamicConfig.dynamically_update_config()
      :ok

  """
  def dynamically_update_config() do
    Enum.each Application.loaded_applications(), fn {app, _, _} ->
        Enum.each Application.get_all_env(app), fn {k, v} ->
            case maybe_get_dynamic_config(v) do
                {:ok, new_config} ->
                    Application.put_env(app, k, new_config)
                :static ->
                    :noop
            end
        end
    end
    :ok
  end

  defp maybe_get_dynamic_config({mod, args}) when is_atom(mod) do
    if :erlang.function_exported(mod, :get_config, 1) do
        {:ok, mod.get_config(args)}
    else
        :static
    end
  end

  # just in case we're Ecto and mix legit compile-time configs with dynamic configs,
  # add the option to specify keyword list key `dynamic_config` to point to the module
  # the existing keyword list will be passed in as the argument
  defp maybe_get_dynamic_config(keywords) when is_list(keywords) do
    if Keyword.keyword?(keywords) do
      if Keyword.has_key?(keywords, :dynamic_config) do
        {:ok, keywords[:dynamic_config].get_config(keywords)}
      else
        :static
      end
    else
      :static
    end
  end

  defp maybe_get_dynamic_config(mod) when is_atom(mod) do
    if :erlang.function_exported(mod, :get_config, 1) do
        {:ok, mod.get_config(nil)}
    else
        :static
    end
  end

  defp maybe_get_dynamic_config(_) do
    :static
  end


  def start(_type, _args) do
    if Application.get_env(:dynamic_config, :reconfig_on_boot) do
      dynamically_update_config()
    end
  end
end
