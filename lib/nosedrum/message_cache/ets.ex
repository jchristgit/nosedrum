defmodule Nosedrum.MessageCache.ETS do
  @default_table :nosedrum_message_cache
  @default_table_options [
    {:read_concurrency, true},
    {:write_concurrency, true},
    :ordered_set,
    :public,
    :named_table
  ]
  @moduledoc """
  An ETS-table based message cache.

  This module does not implement any cache expiration: by default, the
  table fills up infinitely. One possibility of keeping messages under control
  would be to delete all messages sent before a certain date. Since the key
  of table entries are message IDs, you can use
  [`:ets.select_delete/2`](http://erlang.org/doc/man/ets.html#select_delete-2)
  to accomplish this. For example, to delete all messages older than one day,
  you could use the following construct:

      now = DateTime.utc_now()
      one_day_ago = DateTime.add(now, -1, :day)
      snowflake = Nostrum.Snowflake.from_datetime!(one_day_ago)
      match_spec = [{{:"$1", :_, :_, :_, :_}, [{:<, :"$1", snowflake}], [true]}]
      :ets.select_delete(:#{@default_table}, match_spec)

  For deleting in different ways such as by guild ID, use
  [`:ets.fun2ms/1`](http://erlang.org/doc/man/ets.html#fun2ms-1) to generate match
  specifications from functions.

  You can use the `GenServer.call(cache_process, :tid)` to obtain the internal
  table ID when not using a named table.
  """

  # Perhaps, someday, check match specs with `map_get`:
  #
  #   def recent_in_guild(guild_id, :infinity, table_ref) do
  #     :ets.select_reverse(table_ref, [
  #       {{:"$1", :"$2"}, [{:==, {:map_get, :"$2", :guild_id}, guild_id}], [:"$2"]}
  #     ])
  #   end

  @behaviour Nosedrum.MessageCache

  @doc false
  use GenServer

  @doc """
  Initialize the ETS message cache.

  By default, the table used for storing messages is a named table with
  the name `:#{@default_table}`. The table reference is stored internally
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
  def handle_call(:tid, _, tid) do
    {:reply, tid, tid}
  end

  @impl true
  @doc false
  def init({table_name, table_options}) do
    tid = :ets.new(table_name, table_options)

    {:ok, tid}
  end

  @impl true
  def get(_guild_id, message_id, table_ref \\ @default_table) do
    case :ets.lookup(table_ref, message_id) do
      [] -> nil
      [{_message_id, _guild_id, message}] -> message
    end
  end

  @impl true
  def recent_in_guild(guild_id, limit, table_ref \\ @default_table)

  def recent_in_guild(guild_id, :infinity, table_ref) do
    :ets.select_reverse(table_ref, [
      {{:"$1", :"$2", :"$3"}, [{:==, :"$2", guild_id}], [:"$3"]}
    ])
  end

  def recent_in_guild(guild_id, limit, table_ref) do
    selection =
      :ets.select_reverse(
        table_ref,
        [{{:"$1", :"$2", :"$3"}, [{:==, :"$2", guild_id}], [:"$3"]}],
        limit
      )

    case selection do
      :"$end_of_table" -> []
      {matches, _continuation} -> matches
    end
  end

  @doc """
  See `c:Nosedrum.MessageCache.consume/2`.
  Returns the result of `:ets.insert`.
  """
  @impl true
  def consume(message, table_ref \\ @default_table) do
    :ets.insert(table_ref, {message.id, message.guild_id, message})
  end

  @impl true
  @doc """
  See `c:Nosedrum.MessageCache.update/2`.
  Returns the result of `:ets.insert/2`.
  """
  def update(message, table_ref \\ @default_table) do
    # Erlang table column indices start from 1, so 5 references the content here.
    :ets.insert(table_ref, {message.id, message.guild_id, message})
  end
end
