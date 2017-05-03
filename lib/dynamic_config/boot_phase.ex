defmodule DynamicConfig.BootPhase do
  @moduledoc """
  DynamicConfig.BootPhase

  Supply a boot-time implementation of DynamicConfig which updates the configuration
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      def start_phase(:dynamic_config, _, _) do
        if unquote(opts[:skip_bootstrap]) do
          if Application.get_env(:dynamic_config, :no_boot_update) do
            :ok
          else
            DynamicConfig.Service.dynamically_update_config
          end
        else
          {:ok, pid} = DynamicConfig.Supervisor.start_link
          DynamicConfig.Service.dynamically_update_config
          DynamicConfig.Supervisor.stop(pid)
        end
      end
    end
  end

end