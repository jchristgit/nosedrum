defmodule Nosedrum.MessageCache do
  @moduledoc """
  A cache for recent messages on a guild.

  Usage of implementations of this module is useful when your bot needs
  to access recently sent messages without hogging the API. One use case
  would be bots with an integrated mod log that want to show a before &
  after comparison of edited messages.
  """

  alias Nostrum.Struct.{Guild, Message}

  @doc """
  Retrieve a single message for the given `guild_id` with the specified `message_id` from the cache.

  If no message with the given ID is cached, `{:error, :not_found}` is returned.
  """
  @callback get(guild_id :: Guild.id(), message_id :: Message.id()) ::
              {:ok, Message.t()} | {:error, :not_found} | {:error, String.t()}

  @doc """
  Retrieve up to `limit` messages for the given `guild_id` from the cache.

  If the guild is not cached, an empty message list is returned.
  """
  @callback recent_in_guild(guild_id :: Guild.id(), limit :: pos_integer) ::
              {:ok, [Message.t()]} | {:error, String.t()}

  @doc """
  Consume the given `message` in the cache.

  Whether this is done asynchronously or synchronously depends on the implementation.
  """
  @callback consume(message :: Message.t()) :: :ok

  @doc """
  Update the given `message` in the cache, if present.

  Whether this is done asynchronously or synchronously depends on the implementation.
  """
  @callback update(message :: Message.t()) :: :ok
end
