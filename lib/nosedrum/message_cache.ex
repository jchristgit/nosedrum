defmodule Nosedrum.MessageCache do
  @moduledoc """
  A cache for recent messages sent on guilds.

  Usage of implementations of this module is useful when your bot needs
  to access recently sent messages without hogging the API. One use case
  would be bots with an integrated mod log that want to show a before &
  after comparison of edited messages.
  """

  alias Nostrum.Struct.{Guild, Message}

  @doc """
  Retrieve a single message for the given `guild_id` with the specified `message_id`
  from the cache process identified by `cache`.

  If no message with the given ID is cached, `nil` is returned.
  """
  @callback get(guild_id :: Guild.id(), message_id :: Message.id(), cache :: any()) ::
              Message.t() | nil | {:error, String.t()}

  @doc """
  Retrieve up to `limit` messages for the given `guild_id` from the cache
  process identified by `cache`. If `limit` is `:infinity`, return all
  messages for that guild from the cache.

  If the guild is not cached, an empty message list is returned.
  """
  @callback recent_in_guild(
              guild_id :: Guild.id(),
              limit :: pos_integer | :infinity,
              cache :: any()
            ) :: [Message.t()]

  @doc """
  Consume the given `message` in the cache process identified by `cache`.

  Whether this is done asynchronously or synchronously depends on the implementation.
  """
  @callback consume(message :: Message.t(), cache :: any()) :: any()

  @doc """
  Update the given `message` in the cache, if present.

  Whether this is done asynchronously or synchronously depends on the implementation.
  """
  @callback update(message :: Message.t(), cache :: any()) :: any()
end
