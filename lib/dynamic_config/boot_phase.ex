defmodule DynamicConfig.BootPhase do
  @moduledoc """
  DynamicConfig.BootPhase

  Supply a boot-time implementation of DynamicConfig which updates the configuration
  """

  defmacro __using__(opts) do
    boot_modules = opts[:boot_modules]

    if opts[:skip_service_bootstrap] do
      quote do
        def start_phase(:dynamic_config, _, _) do
          DynamicConfig.Service.dynamically_update_config(unquote(boot_modules))
        end
      end
    else
      quote do
        def start_phase(:dynamic_config, _, _) do
          {:ok, pid} = DynamicConfig.Supervisor.start_link
          DynamicConfig.Service.dynamically_update_config(unquote(boot_modules))
          DynamicConfig.Supervisor.stop(pid)
        end
      end
    end
  end

end