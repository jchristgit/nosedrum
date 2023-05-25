defmodule Nosedrum.TextCommand.Storage do
  @moduledoc """
  Storages contain commands and are used by command invokers to look up commands.

  How you start a storage is up to the module itself - what is
  expected is that storage modules implement the behaviours
  documented in this module.

  The public-facing API of storage modules takes an optional argument,
  the storage process or other information used to identify the storage
  such as an ETS table name.
  """

  @typedoc """
  A single command module or mapping of subcommand names to command groups.

  In addition to subcommand names, the key `:default` can be specified by
  the module. `:default` should be invoked when none of the subcommands in the
  map match.
  """
  @type command_group ::
          module
          | %{optional(:default) => command_group, required(String.t()) => command_group}

  @typedoc """
  The "invocation path" of the command.

  The public-facing API of storage modules should use this in order
  to allow users to identify the command they want to operate on.

  ## Usage
  To identify a single command, use a single element list, such as `["echo"]`.
  To identify a subcommand, use a pair, such as `["infraction", "search"]`.
  To identify the default subcommand invoked when no matching subcommand is
  found, specify the group name first, then `:default`, such as
  `["tags", :default]`.
  """
  @type command_path :: [String.t() | :default, ...]

  @doc """
  Look up a command group under the specified `name`.

  If the command was not found, `nil` should be returned.
  """
  @callback lookup_command(name :: String.t(), storage :: reference) :: command_group | nil

  @doc """
  Add a new command under the given `path`.

  If a command has the c:Nosedrum.TextCommand.aliases/0 callback defined,
  they will also be added under `path`. If the command already exists,
  no error should be returned.
  """
  @callback add_command(path :: command_path, command :: module, storage :: reference) ::
              :ok | {:error, String.t()}

  @doc """
  Remove the command under the given `path`.

  If a command has the c:Nosedrum.TextCommand.aliases/0 callback defined,
  they will also be removed under `path`. If the command does not exist,
  no error should be returned.
  """
  @callback remove_command(path :: command_path, storage :: reference) ::
              :ok | {:error, String.t()}

  @doc """
  Return a mapping of command names to `t:command_group/0`s.

  For top-level commands, the value should be a string, otherwise,
  a mapping of subcommand names to subcommand modules as described
  on `t:command_group/0`s documentation should be returned.
  """
  @callback all_commands(storage :: reference) :: %{String.t() => command_group}
end
