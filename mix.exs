defmodule DynamicConfig.Mixfile do
  use Mix.Project

  def project do
    [app: :dynamic_config,
     version: "0.3.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      mod: {DynamicConfig, []},
      extra_applications: [:logger],
      start_phases: [dynamic_config: []],
      env: [
        # an explicit list of erlang apps to apply dynamic config to
        #  eg [ :my_app ]
        #   [] will result in no dynamic config applied at boot
        #   nil will result in modules detected implicitly from sources (see below)
        boot_modules: nil,

        # implicit_sources used when no boot_modules have been specified
        #  the purpose here is to enable most use cases to "just work" out of the box
        #
        #  :loaded_applications  -> Application.loaded_applications
        #  :project_app          -> Mix.Project.config[:app]
        #  :project_dependencies -> Mix.Project.config[:deps]
        implicit_sources: [:loaded_applications, :project_app, :project_dependencies]
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
         {:ex_doc, "~> 0.14", only: :dev, runtime: false},
    ]
  end
end
