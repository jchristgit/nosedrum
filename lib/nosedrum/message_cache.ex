defmodule Nosedrum.MessageCache do
  @moduledoc """
  A cache for recent messages sent on guilds.

  Usage of implementations of this module is useful when your bot needs
  to access recently sent messages without hogging the API. One use case
  would be bots with an integrated mod log that want to show a before &
  after comparison of edited messages.
  """

  alias Nostrum.Struct.{Channel, Guild, Message, User}

  @typedoc """
  A slimmed down message with the most relevant data.

  You can fetch information about the author and the channel using
  Nostrum's built in cache, specificaly `Nostrum.Cache.ChannelCache.get/1`
  and `Nostrum.Cache.UserCache.get/1`.
  """
  @type cache_message :: {Message.id(), Channel.id(), User.id(), Message.content()}

  @doc """
  Retrieve a single message for the given `guild_id` with the specified `message_id`
  from the cache process identified by `cache`.

  If no message with the given ID is cached, `nil` is returned.
  """
  @callback get(guild_id :: Guild.id(), message_id :: Message.id(), cache :: reference()) ::
              cache_message | nil | {:error, String.t()}

  @doc """
  Retrieve up to `limit` messages for the given `guild_id` from the cache
  process identified by `cache`. If `limit` is `nil`, return all
  messages for that guild from the cache.

  If the guild is not cached, an empty message list is returned.
  """
  @callback recent_in_guild(
              guild_id :: Guild.id(),
              limit :: pos_integer | nil,
              cache :: reference()
            ) ::
              {:ok, [cache_message]} | {:error, String.t()}

  @doc """
  Consume the given `message` in the cache process identified by `cache`.

  Whether this is done asynchronously or synchronously depends on the implementation.
  """
  @callback consume(message :: Message.t(), cache :: reference()) :: :ok

  @doc """
  Update the given `message` in the cache, if present.

  Whether this is done asynchronously or synchronously depends on the implementation.
  """
  @callback update(message :: Message.t(), cache :: reference()) :: :ok
end
