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
      :ets.select_delete(#{@default_table}, match_spec)

  For deleting in different ways such as by guild ID, use
  [`:ets.fun2ms/1`](http://erlang.org/doc/man/ets.html#fun2ms-1) to generate match
  specifications from functions.

  You can use the `GenServer.call(cache_process, :tid)` to obtain the internal
  table ID when not using a named table.
  """

  @behaviour Nosedrum.MessageCache

  @doc false
  use GenServer

  @doc """
  Initialize the ETS message cache.

  By default, the table used for storing messages is a named table with
  the name `#{@default_table}`. The table reference is stored internally
  as the state of this process, the public-facing API functions default
  to using the table name to access the module.
  """
  @spec start_link(atom() | nil, List.t(), GenServer.options()) :: GenServer.on_start()
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
      [{id, _guild_id, channel_id, author_id, content}] -> {id, channel_id, author_id, content}
    end
  end

  @impl true
  def recent_in_guild(guild_id, limit, table_ref \\ @default_table)

  def recent_in_guild(guild_id, nil, table_ref) do
    :ets.select_reverse(table_ref, [
      # {Message.id(), Guild.id(), Channel.id(), User.id(), Message.content()}
      {{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:==, :"$2", guild_id}],
       [{{:"$1", :"$3", :"$4", :"$5"}}]}
    ])
  end

  def recent_in_guild(guild_id, limit, table_ref) do
    selection =
      :ets.select_reverse(
        table_ref,
        [
          # {Message.id(), Guild.id(), Channel.id(), User.id(), Message.content()}
          {{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:==, :"$2", guild_id}],
           [{{:"$1", :"$3", :"$4", :"$5"}}]}
        ],
        limit
      )

    case selection do
      :"$end_of_table" -> []
      {matches, _continuation} -> matches
    end
  end

  @impl true
  def consume(message, table_ref \\ @default_table) do
    cache_entry =
      {message.id, message.guild_id, message.channel_id, message.author.id, message.content}

    :ets.insert(table_ref, cache_entry)

    :ok
  end

  @impl true
  def update(message, table_ref \\ @default_table) do
    # Erlang table column indices start from 1, so 5 references the content here.
    :ets.update_element(table_ref, message.id, [{5, message.content}])

    :ok
  end
end
