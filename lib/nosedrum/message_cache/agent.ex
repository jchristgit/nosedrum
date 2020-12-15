defmodule Nosedrum.MessageCache.Agent do
  @default_limit_per_guild 200
  @doc_modname __MODULE__ |> Atom.to_string() |> String.trim_leading("Elixir.")
  @moduledoc """
  An `Agent`-based message cache.

  Note that using this cache across your entire bot can easily lead to
  the cache becoming a bottleneck, since an agent is a single process.
  Instead, you might want to use this cache across several smaller guilds
  to avoid overloading a single process with events from multiple guilds.

  ## Usage

      defmodule MyBot.Application do
        use Application

        def start(type, args) do
          children = [
            %{
              id: MessageCache,
              start: {#{@doc_modname}, :start_link, [[name: #{@doc_modname}]]}
            }
          ]
        end
      end

  If using multiple instances of this agent, you can pass the agent process
  reference as the last argument to the individual functions that this
  implementation provides. By default, this uses `#{@doc_modname}` as the
  agent reference, requiring you to specify the `name:` in your application
  callback.

  ## Configuration
  By default, the cache keeps up to #{@default_limit_per_guild} messages in
  the cache per guild. To configure this, you can pass the `limit:` option
  as an argument to the process, such as:

      defmodule MyBot.Application do
        use Application

        def start(type, args) do
          children = [
            %{
              id: MessageCache,
              start: {#{@doc_modname}, :start_link, [[name: #{@doc_modname}, limit: 50]]}
            }
          ]
        end
      end

  This will ensure that no more than 50 messages are kept in cache per guild.
  """

  @behaviour Nosedrum.MessageCache

  @doc false
  use Agent

  @doc false
  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(options) do
    {limit, gen_options} = Keyword.pop(options, :limit, @default_limit_per_guild)
    initial_state = {%{}, false, limit}
    Agent.start_link(fn -> initial_state end, gen_options)
  end

  @impl true
  def get(guild_id, message_id, cache \\ __MODULE__) do
    Agent.get(cache, fn state ->
      state
      |> elem(0)
      |> Map.get(guild_id, [])
      |> Enum.find(&(&1.id == message_id))
    end)
  end

  @impl true
  def recent_in_guild(guild_id, limit, cache \\ __MODULE__)

  def recent_in_guild(guild_id, :infinity, cache) do
    Agent.get(cache, fn state ->
      state
      |> elem(0)
      |> Map.get(guild_id, [])
    end)
  end

  def recent_in_guild(guild_id, limit, cache) do
    Agent.get(cache, fn state ->
      state
      |> elem(0)
      |> Map.get(guild_id, [])
      |> Enum.slice(0..(limit - 1))
    end)
  end

  @impl true
  def consume(msg, cache \\ __MODULE__) do
    Agent.get_and_update(
      cache,
      fn {messages, has_hit_limit, limit} = state ->
        hits_limit_after_insertion =
          has_hit_limit or length(Map.get(messages, msg.guild_id, [])) >= limit

        updated_messages =
          Map.update(
            messages,
            msg.guild_id,
            [msg],
            &if(hits_limit_after_insertion,
              do: [msg | Enum.drop(&1, -1)],
              else: [msg | &1]
            )
          )

        # Only recalculate the length of the messages if we haven't already hit the
        # limit to avoid unnecessary list traversal.
        updated_state = {updated_messages, hits_limit_after_insertion, limit}
        {state, updated_state}
      end
    )
  end

  @impl true
  def update(msg, cache \\ __MODULE__) do
    Agent.get_and_update(
      cache,
      fn {messages, _has_hit_limit, _limit} = state ->
        with guild_msgs when guild_msgs != nil <- Map.get(messages, msg.guild_id, []),
             cached_idx when cached_idx != nil <-
               Enum.find_index(guild_msgs, &(&1.id == msg.id)) do
          updated_messages = %{
            messages
            | msg.guild_id => List.replace_at(guild_msgs, cached_idx, msg)
          }

          updated_state = put_elem(state, 0, updated_messages)
          {state, updated_state}
        else
          _err -> {state, state}
        end
      end
    )
  end
end
