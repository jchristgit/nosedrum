defmodule Nosedrum.Storage.ETS do
  @moduledoc """
  An implementation of the `Nosedrum.Storage` behaviour based on ETS tables.

  This module needs to be configured as part of your supervision tree as it
  spins up a `GenServer` which owns the command table.
  """
  @behaviour Nosedrum.Storage
  @default_table :nosedrum_commands
  @default_table_options [{:read_concurrency, true}, :ordered_set, :public, :named_table]

  @doc false
  use GenServer

  @impl true
  def add_command(path, command, table_ref \\ @default_table)

  def add_command({name}, command, table_ref) do
    :ets.insert(table_ref, {name, command})

    :ok
  end

  def add_command({name, key}, command, table_ref) do
    case lookup_command(name, table_ref) do
      nil ->
        :ets.insert(table_ref, {name, %{key => command}})
        :ok

      module when not is_map(module) ->
        {:error, "command `#{name} is a top-level command, cannot add subcommand `#{key}"}

      map ->
        :ets.insert(table_ref, {name, Map.put(map, key, command)})
        :ok
    end
  end

  @impl true
  def remove_command(path, table_ref \\ @default_table)

  def remove_command({name}, table_ref) do
    :ets.delete(table_ref, name)

    :ok
  end

  def remove_command({name, key}, table_ref) do
    case lookup_command(name, table_ref) do
      nil ->
        :ok

      module when not is_map(module) ->
        {:error, "command `#{name}` is a top-level command, cannot remove subcommand `#{key}`"}

      map ->
        :ets.insert(table_ref, {name, Map.delete(map, key)})
        :ok
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
  @spec start_link(atom() | nil, List.t(), Keyword.t()) :: GenServer.on_start()
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
end
