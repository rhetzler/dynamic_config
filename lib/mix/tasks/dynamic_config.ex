defmodule Mix.Tasks.DynamicConfig do
  use Mix.Task

  @shortdoc "Bootstrap DynamicConfig for use with other tasks"


  # @TODO add parameters to target specific applications for dynamic config bootstrap
  @doc false
  def run(args) do
    {_opts, args, _} = OptionParser.parse(args)

    case args do
      [] -> bootstrap()
      _ ->
        Mix.raise "Invalid arguments, expected: mix do dynamic_config, other_tasks ..."
    end

  end

  # The boot phase does the magic.
  @doc false
  defp bootstrap() do
    Application.ensure_started(:dynamic_config)
  end

end