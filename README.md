# DynamicConfig

## Overview

DynamicConfig is an elixir library aimed to support a configuration which can be evaluated at boot-time or run-time (rather than strictly compile-time). This can be applied to any configuration, without requiring changes to the calling libraries, such as re-writing a library to support {:system, :variable_name}

## Example:

```
# static configuration:
config :my_app, :my_key1, :some_value

# Dynamic:
config :my_app, :my_key2, {DynamicConfig.Env, :TERM}
config :my_app, :my_key3, {DynamicConfig.Quoted, quote do: Discovery.get('db_uri')}

# Ecto compatibility:
config :my_app, MyApp.Repo, adapter: "foo", # adapter required at compile-time
                            dynamic_config: MyApp.DynamicEctoConfigAndSecrets
```
(See Use below for more cases)


## Compile-time configuration

Standard elixir pattern involves setting configuration via the erlang configuration pattern:

* set:  
```config :my_app, :my_key, :some_value```

* get:  
```Application.get(:my_app, :my_key)```

These values are set at compile time. If you intend to release directly from compile to your target deploy location, this is sufficient, but there are use cases for which it is not:

* Multiple deploy locations
* 12-Factor "Configuration from Environment" Principle
* Deploy locations unknown at compile time
	* Dynamic/Orchestrated environments Environments 


Previously, we had a bash implementation of REPLACE\_OS\_VARS parameter and it's predecessors (RELX\_REPLACE\_OS\_VARS), but this

* is restricted to linux environments
* requires perfect env var matching to library requirements


## Solution

DynamicConfig provides a solution to this in 2 modes:

* *Boot Time:* Elixir boot-time configuration refresh
* *Run Time:* Implementation of Dynamic Configuration lookup

Note that unlike other tools such as Confex which similarly supply runtime lookup, this is not restricted to environment variables, and simultaneously allows boot-time updates for modules which aready follow the Application.get_env pattern.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dynamic_config` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:dynamic_config, "~> 0.2.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dynamic_config](https://hexdocs.pm/dynamic_config).

Additionally, you must determine how you want DynamicConfig to interact with your app:

### Method 1: Global boot precedence (1-time boot reconfig, runtime optional)

Add DynamicConfig to the beginning of your applications list. This ensures everything loaded afterwards will have it's values dynamically updated

```elixir
def application do
	[
	   ...
		applications: [:dynamic_config, ... ]
		...
	]
end	

```

### Method 2: Strictly Dynamic

Follow the steps for Method 1 (prepend :dynamic_config to your applications list)

Additionally, indicate that no modules should be updated at boot time in your configuration:

```elixir
config :dynamic_config, :boot_modules, []
```

### Method 3: Your app's boot phase (1-time boot reconfig, no runtime)

*Note:* This will not affect applications in your boot sequence which are booted *before* your application, such as cowboy and phoenix_ecto (if you're building a phoenix app)

Add a start phase (or add it to the list if it already exists):

```elixir
def application do
	[
	   ...
	   start_phases: [dynamic_config: []]
	   ...
	]
end
```

Supply the implementation of the boot phase in your app (ie, lib/my_app.ex)

```
defmodule MyApp do
  use Application
  use DynamicConfig.BootPhase # supplies "start_phase(:dynamic_config, _, _)"
  ...
```

### Additional configuration

In any of the 3 methods, if you wish to restrict or enable boot time reconfiguration for a subset of available applications (only *some* modules), you can do this via the :boot_modules configuration parameter:

```
config :dynamic_config, :boot_modules, [:app1, :app2]
```

Boot precedence remains as defined by your chosen installation method. This won't case applications to reload if they read config before dynamic configuration was applied (ie, Method 3). If this is an issue, don't use Method 3 ;-)

## Use

As in the examples above, dynamic configuration can be supplied via any module which supply the DynamicConfig behaviour. Replace your old configuration value with the Module, or with a {Module, param} 2-tuple.

For convenience, The following modules are supplied which provide some basic behavior:

* DynamicConfig.Quoted 
  - execute a quoted expression
* DynamicConfig.Env
  - read in an environment variable (drop in replacement for REPLACE\_OS\_VARS)

You can provide your own functionality:

```elixir
defmodule MyApp.MyConfigurator do
  defmodule Nullary do
    @behaviour DynamicConfig
  
  	 def get_config(_) do
  	   ...
    end
  end
  defmodule Parameterized do
    @behaviour DynamicConfig
  
  	 def get_config(params) do
  	   ...
    end
  end
end  
```

and then attach them to configs as follows:

```elixir
config :my_app, :my_key1, Myapp.MyConfigurator.Nullary
config :my_app, :my_key2, {MyApp.MyConfigurator.Parameterized, [param1, ... ]}
```

If you enabled a boot-time reconfig, then this will contain the updated values:

```elixir
Application.get_env(:my_app, :my_key1)
Application.get_env(:my_app, :my_key2)
```

In strict-only, the values are available via module:

```elixir
DynamicConfig.get_env(:my_app, :my_key1)
DynamicConfig.get_env(:my_app, :my_key2)
```

## Use with compile-time requirements

Some modules, such as Ecto, mix network configuration (db url) and runtime configuration (db username, password) with compile-time configuration (such as compile-time code-loading).

Strict separation of such concerns should be promoted, different Keyword items under the same config is not really "separation". However, in order to get Ecto to compile, some compromises must be made.

Sample ecto config:

```elixir
config, :my_app, MyApp.Repo, adapter: DbAdapter,
                             dynamic_config: MyApp.DbConfig
```

```elixir
defmodule MyApp.DbConfig do
  @behaviour DynamicConfig
  
  def get_config(keywords) do
    keywords |> Keyword.delete(:dynamic_config) |>
    Keyword.merge([
	
      url: System.get_env("DATABASE_URL"),
      username: System.get_env("DATABASE_USERNAME"),
      password: System.get_env("DATABASE_PASSWORD")
	
    ])
  end
end  
```