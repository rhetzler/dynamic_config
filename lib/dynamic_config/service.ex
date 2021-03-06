
defmodule DynamicConfig.Service do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, :ok}
  end

  def dynamically_update_config do
    GenServer.call(__MODULE__, {:dynamically_update_config, nil})
  end
  def dynamically_update_config(modules) do
    GenServer.call(__MODULE__, {:dynamically_update_config, modules})
  end

  def get_env(app, key) do
    GenServer.call(__MODULE__, {:get_env, app, key})
  end


  # - if no modules passed, pull module list from implicit_modules (see below)
  # - short circuit out an empty list (no update desired)
  # - otherwise, update just the ones specified
  def handle_call({:dynamically_update_config, nil}, _from, :ok) do
    update_app_configs( implicit_modules(Application.get_env(:dynamic_config, :implicit_sources)) )
  end
  def handle_call({:dynamically_update_config, []}, _from, :ok) do
    {:reply, :ok, :ok}
  end
  def handle_call({:dynamically_update_config, modules}, _from, :ok) when is_list(modules) do
    update_app_configs(modules)
  end

  def handle_call({:get_env, app, key}, _from, :ok ) do
    v = Application.get_env(app,key)
    case maybe_get_dynamic_config(v) do
      {:ok, new_config} ->
        {:reply, new_config, :ok}
      {:error, error, _} ->
        raise error
      :static ->
        {:reply, v, :ok}
    end
  end

  # Implicit modules: get modules implicitly associated with project
  #  necessary since Application does not expose a global list of configured modules
  #    (only modules which have been loaded by time of invocation)
  #  - :loaded_applications : Application.loaded_applications
  #  - :project_dependencies : Mix.Project.config[:deps]
  #  - :project_app :
  #    which makes this more difficult
  #
  # list of modules subject to dynamic config, when no explicit list of modules has been provided
  def implicit_modules(sources), do: Enum.flat_map(sources, &modules_from_source/1)

  defp modules_from_source(:loaded_applications), do:  Enum.map(Application.loaded_applications(), &elem(&1,0))  # {module, _, _ }
  defp modules_from_source(:project_dependencies), do: Enum.map(Mix.Project.config[:deps], &elem(&1,0)) # {module, _ }  or  {module, _, _ }
  defp modules_from_source(:project_app), do:         [ Mix.Project.config[:app] ]
  defp modules_from_source(_), do:                    []


  defp update_app_configs(app_list) do
    Enum.each app_list, fn app ->
      Enum.each Application.get_all_env(app), fn {k, v} ->
        case maybe_get_dynamic_config(v) do
          {:ok, new_config} ->
            #IO.puts("Dynamic config setting {#{app},#{k},#{inspect new_config}}")
            Application.put_env(app, k, new_config, persistent: true)  #persistent:true secures this from getting reset during an Application.ensure_all_started
          {:error, error, dc_module, stacktrace} ->
            troubleshooting_tips(app,k,v,dc_module, error, stacktrace)
            raise error
          :static ->
            :noop
        end
      end
    end
    {:reply, :ok, :ok}
  end




  #
  # Handle a value
  #
  defp maybe_get_dynamic_config({mod, args}) when is_atom(mod) do
    maybe_invoke_module(mod, args)
  end

  # just in case we're Ecto and mix legit compile-time configs with dynamic configs,
  # add the option to specify keyword list key `dynamic_config` to point to the module
  # the existing keyword list will be passed in as the argument
  defp maybe_get_dynamic_config(keywords) when is_list(keywords) do
    if keywords |> Keyword.keyword? and keywords |> Keyword.has_key?(:dynamic_config) do
      maybe_invoke_module(keywords[:dynamic_config], keywords)
    else
      :static
    end
  end

  defp maybe_get_dynamic_config(mod) when is_atom(mod) do
    maybe_invoke_module(mod, nil)
  end

  defp maybe_get_dynamic_config(_) do
    :static
  end

  defp maybe_invoke_module(module, args) do
    if Code.ensure_loaded?(module) and :erlang.function_exported(module, :get_config, 1) do
      #IO.puts("Dynamic Config loading following module: #{module}")
      get_config_from_module(module, args)
    else
      if Regex.match?(~r/Elixir\./,Atom.to_string(module)) do
        IO.puts("Warning: DynamicConfig was not able to load possible module reference: #{module}")
      end
      :static
    end
  end

  defp get_config_from_module(module, args) do
    try do
      result = module.get_config(args)
      {:ok, result}
    rescue
      error ->
       {:error, error, module, System.stacktrace}
    end
  end

  defp troubleshooting_tips(app, key, _value, dc_module, error, stacktrace) do
    IO.puts("=============================================================================")
    IO.puts("| Your Application's DynamicConfig could not be resolved")
    IO.puts("| This will result in boot failure")
    IO.puts("| Error handling in in your config loader may prevent this sort of failure")
    IO.puts("=============================================================================")
    IO.puts("| faulty config:")
    IO.puts("|     #{app} : #{key}")
    IO.puts("|")
    IO.puts("|     handled by: #{dc_module}")
    IO.puts("|")
    IO.puts("")
    IO.inspect(error)
    IO.puts("")
    IO.puts("|")
    IO.puts("| Stacktrace: ")
    IO.puts("|")
    IO.inspect(stacktrace)
    IO.puts("|")
    IO.puts("=============================================================================")

  end

end
