defmodule Nosedrum.Converters.Channel do
  @moduledoc false

  alias Nosedrum.Converters
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Channel

  @doc """
  Convert a Discord channel mention to an ID.
  This also works if the given string is just the ID.

  ## Examples

    iex> Nosedrum.Converters.Channel.channel_mention_to_id("<#10101010>")
    {:ok, 10101010}
    iex> Nosedrum.Converters.Channel.channel_mention_to_id("<#101010>")
    {:ok, 101010}
    iex> Nosedrum.Converters.Channel.channel_mention_to_id("91203")
    {:ok, 91203}
    iex> Nosedrum.Converters.Channel.channel_mention_to_id("not valid")
    {:error, "not a valid channel ID"}
  """
  @spec channel_mention_to_id(String.t()) :: {:ok, pos_integer()} | {:error, String.t()}
  def channel_mention_to_id(text) do
    maybe_id =
      text
      |> String.trim_leading("<#")
      |> String.trim_trailing(">")

    case Integer.parse(maybe_id) do
      {value, ""} -> {:ok, value}
      _ -> {:error, "not a valid channel ID"}
    end
  end

  # Attempt to find a channel within the given `channels`
  # matching the given `text`.
  # The lookup strategy is as follows:
  # - Channel ID
  # - Channel mention
  # - Channel name
  @spec find_channel(
          [Nostrum.Struct.Channel.t()],
          String.t()
        ) :: Nostrum.Struct.Channel.t() | Converters.reason()
  defp find_channel(channels, query) do
    case channel_mention_to_id(query) do
      {:ok, requested_id} ->
        Enum.find_value(
          channels,
          {:not_found, {:by, :id, requested_id, []}},
          fn
            %{id: ^requested_id} = channel -> channel
            _other -> nil
          end
        )

      {:error, _reason} ->
        Enum.find_value(
          channels,
          {:not_found, {:by, :name, query, []}},
          fn
            %Channel{name: ^query} = channel -> channel
            _other -> nil
          end
        )
    end
  end

  defp okify({:not_found, _reason} = result), do: {:error, result}
  defp okify({_id, channel}), do: {:ok, channel}
  defp okify(channel), do: {:ok, channel}

  @spec into(String.t(), Nostrum.Snowflake.t()) ::
          {:ok, Nostrum.Struct.Channel.t()} | {:error, Converters.reason()}
  def into(text, guild_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        guild.channels
        |> Map.values()
        |> find_channel(text)
        |> okify

      {:error, _reason} ->
        case Api.get_guild_channels(guild_id) do
          {:ok, channels} ->
            channels
            |> find_channel(text)
            |> okify

          {:error, reason} ->
            {:error, {:uncached_and_fetch_error, reason}}
        end
    end
  end
end
