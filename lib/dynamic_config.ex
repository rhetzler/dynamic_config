defmodule DynamicConfig do
  use DynamicConfig.BootPhase, skip_service_bootstrap: true, boot_modules: Application.get_env(:dynamic_config, :boot_modules)

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
  to set callbacks. For backwards compatibility with libraries which do not or will not use such a mechanism,
  a boot-time mechanism can update the configuration manifest which such libraries read from.

  See the project's README.md for installation details with your app.

  A dynamic configuration can take on any of the following three forms:

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

  def start(_type, _args) do
    DynamicConfig.Supervisor.start_link
  end

  def get_env(app, key) do
    DynamicConfig.Service.get_env(app, key)
  end
end
