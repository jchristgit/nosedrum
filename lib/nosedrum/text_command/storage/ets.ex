defmodule Nosedrum.TextCommand.Storage.ETS do
  @moduledoc """
  An implementation of the `Nosedrum.TextCommand.Storage` behaviour based on ETS tables.

  This module needs to be configured as part of your supervision tree as it
  spins up a `GenServer` which owns the command table. If you want to obtain
  the table ID of the internal ETS table, send a call with the message `:tid`.
  """
  @behaviour Nosedrum.TextCommand.Storage
  @default_table :nosedrum_commands
  @default_table_options [{:read_concurrency, true}, :ordered_set, :public, :named_table]

  @doc false
  use GenServer

  @spec put_nested_command(map(), [String.t()], module()) ::
          Nosedrum.TextCommand.Storage.command_group()
  defp put_nested_command(acc, [name], command) do
    if function_exported?(command, :aliases, 0) do
      Enum.reduce(command.aliases(), acc, &Map.put(&2, &1, command))
    else
      acc
    end
    |> Map.put(name, command)
  end

  defp put_nested_command(acc, [name | path], command),
    do: Map.put(acc, name, put_nested_command(Map.get(acc, name, %{}), path, command))

  @impl true
  def add_command(path, command, table_ref \\ @default_table)

  def add_command([name], command, table_ref) do
    if function_exported?(command, :aliases, 0) do
      Enum.each(command.aliases, &:ets.insert(table_ref, {&1, command}))
    end

    :ets.insert(table_ref, {name, command})

    :ok
  end

  def add_command([name | path], command, table_ref) do
    case lookup_command(name, table_ref) do
      maybe_map when is_map(maybe_map) or is_nil(maybe_map) ->
        cog = put_nested_command(maybe_map || %{}, path, command)
        :ets.insert(table_ref, {name, cog})
        :ok

      module when not is_map(module) ->
        {:error, "command `#{name} is a top-level command, cannot add subcommand at `#{path}"}
    end
  end

  @spec empty_cog?({String.t() | :default, map() | module()}) :: boolean()
  defp empty_cog?({_key, module}) when is_atom(module), do: false
  defp empty_cog?({_key, %{}}), do: true
  defp empty_cog?({_key, cog}), do: Enum.all?(cog, &empty_cog?/1)

  @impl true
  def remove_command(path, table_ref \\ @default_table)

  def remove_command([name], table_ref) do
    command = lookup_command(name, table_ref)

    if function_exported?(command, :aliases, 0) do
      Enum.each(command.aliases(), &:ets.delete(table_ref, {&1, command}))
    end

    :ets.delete(table_ref, name)

    :ok
  end

  def remove_command([name | path], table_ref) do
    case lookup_command(name, table_ref) do
      nil ->
        :ok

      module when not is_map(module) ->
        {:error,
         "command `#{name}` is a top-level command, cannot remove subcommand at `#{path}`"}

      map ->
        {dropped_cog, updated_cog} = pop_in(map, path)

        updated_cog =
          if function_exported?(dropped_cog, :aliases, 0) do
            Map.drop(updated_cog, dropped_cog.aliases())
          else
            updated_cog
          end

        case Enum.reject(updated_cog, &empty_cog?/1) do
          [] ->
            :ets.delete(table_ref, name)
            :ok

          entries ->
            mapped = Map.new(entries)
            :ets.insert(table_ref, {name, mapped})
            :ok
        end
    end
  end

  @impl true
  def lookup_command(name, table_ref \\ @default_table) do
    case :ets.lookup(table_ref, name) do
      [] ->
        nil

      [{_name, command}] ->
        command
    end
  end

  @impl true
  def all_commands(table_ref \\ @default_table) do
    table_ref
    |> :ets.tab2list()
    |> Enum.reduce(%{}, fn {name, cog}, acc -> Map.put(acc, name, cog) end)
  end

  @doc """
  Initialize the ETS command storage.

  By default, the table used for storing commands is a named table with
  the name `#{@default_table}`. The table reference is stored internally
  as the state of this process, the public-facing API functions default
  to using the table name to access the module.
  """
  def start_link(
        table_name \\ @default_table,
        table_options \\ @default_table_options,
        gen_options
      ) do
    GenServer.start_link(__MODULE__, {table_name, table_options}, gen_options)
  end

  @impl true
  @doc false
  def init({table_name, table_options}) do
    tid = :ets.new(table_name, table_options)

    {:ok, tid}
  end

  @impl true
  def handle_call(:tid, _, tid) do
    {:reply, tid, tid}
  end
end
