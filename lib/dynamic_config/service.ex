
defmodule DynamicConfig.Service do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, :ok}
  end

  def dynamically_update_config do
    GenServer.call(__MODULE__, {:dynamically_update_config})
  end

  def get_env(app, key) do
    GenServer.call(__MODULE__, {:get_env, app, key})
  end


  def handle_call({:dynamically_update_config}, _from, :ok) do
    #app_list = Application.get_env(:dynamic_config, :load_applications)
    app_list = Enum.map Application.loaded_applications(), fn {app, _, _ } -> app; end

    Enum.each app_list, fn app ->
      Enum.each Application.get_all_env(app), fn {k, v} ->
        case maybe_get_dynamic_config(v) do
          {:ok, new_config} ->
            Application.put_env(app, k, new_config)
          :static ->
            :noop
        end
      end
    end
    {:reply, :ok, :ok}
  end

  def handle_call({:get_env, app, key}, _from, :ok ) do
    v = Application.get_env(app,key)
    case maybe_get_dynamic_config(v) do
      {:ok, new_config} ->
        {:reply, new_config, :ok}
      :static ->
        {:reply, v, :ok}
    end
  end

  #
  # Handle a value
  #
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
end