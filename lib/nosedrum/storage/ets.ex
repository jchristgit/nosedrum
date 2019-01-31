defmodule Nosedrum.Storage.ETS do
  @moduledoc """
  An implementation of the `Nosedrum.Storage` behaviour based on ETS tables.

  This module needs to be configured as part of your supervision tree as it
  spins up a `GenServer` which owns the command table.
  """
  @behaviour Nosedrum.Storage
  @default_table :nosedrum_commands

  @doc false
  use GenServer

  @impl true
  def add_command({name}, command) do
    :ets.insert(@default_table, {name, command})

    :ok
  end

  def add_command({name, key}, command) do
    case lookup_command(name) do
      nil ->
        :ets.insert(@default_table, {name, %{key => command}})
        :ok

      module when not is_map(module) ->
        {:error, "command `#{name} is a top-level command, cannot add subcommand `#{key}"}

      map ->
        :ets.insert(@default_table, {name, Map.put(map, key, command)})
        :ok
    end
  end

  @impl true
  def remove_command({name}) do
    :ets.delete(@default_table, name)

    :ok
  end

  def remove_command({name, key}) do
    case lookup_command(name) do
      nil ->
        :ok

      module when not is_map(module) ->
        {:error, "command `#{name}` is a top-level command, cannot remove subcommand `#{key}`"}

      map ->
        :ets.insert(@default_table, {name, Map.delete(map, key)})
        :ok
    end
  end

  @impl true
  def lookup_command(name) do
    case :ets.lookup(@default_table, name) do
      [] ->
        nil

      [{_name, command}] ->
        command
    end
  end

  @impl true
  def all_commands do
    @default_table
    |> :ets.tab2list()
    |> Enum.reduce(%{}, fn {name, cog}, acc -> Map.put(acc, name, cog) end)
  end

  @doc false
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @impl true
  @doc false
  def init(:ok) do
    tid =
      :ets.new(@default_table, [{:read_concurrency, true}, :ordered_set, :public, :named_table])

    {:ok, tid}
  end
end
