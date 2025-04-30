defmodule Nosedrum.Converters.Member do
  @moduledoc false

  alias Nosedrum.Converters
  alias Nosedrum.Helpers
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Snowflake
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member

  @doc """
  Convert a Discord user mention to an ID.
  This also works if the given string is just the ID.

  ## Examples

    iex> Nosedrum.Converters.Member.user_mention_to_id("<@10101010>")
    {:ok, 10101010}
    iex> Nosedrum.Converters.Member.user_mention_to_id("<@!101010>")
    {:ok, 101010}
    iex> Nosedrum.Converters.Member.user_mention_to_id("91203")
    {:ok, 91203}
    iex> Nosedrum.Converters.Member.user_mention_to_id("not valid")
    :error
  """
  @spec user_mention_to_id(String.t()) :: {:ok, pos_integer()} | :error
  def user_mention_to_id(text) do
    maybe_id =
      text
      |> String.trim_leading("<@")
      |> String.trim_leading("!")
      |> String.trim_trailing(">")

    case Integer.parse(maybe_id) do
      {value, ""} -> {:ok, value}
      _ -> :error
    end
  end

  @spec into(String.t(), Snowflake.t()) :: {:ok, Member.t()} | {:error, Converters.reason()}
  def into(text, guild_id) do
    with {:ok, user_id} <- user_mention_to_id(text),
         {:ok, fetched_member} <- MemberCache.get(guild_id, user_id) do
      {:ok, fetched_member}
    else
      {:error, _reason} = cache_error ->
        cache_error

      :error ->
        find_by_username(guild_id, text) || find_by_global_name(guild_id, text) ||
          not_found_error(text)
    end
  end

  @spec find_by_username(Guild.id(), String.t()) :: Member.t() | nil
  defp find_by_username(guild_id, text) do
    []
    |> MemberCache.fold_with_users(guild_id, fn {member, user}, acc ->
      if user.username == text do
        [member | acc]
      else
        acc
      end
    end)
    |> one_or_none(:username)
  end

  @spec find_by_global_name(Guild.id(), String.t()) :: Member.t() | nil
  defp find_by_global_name(guild_id, text) do
    []
    |> MemberCache.fold_with_users(guild_id, fn {member, user}, acc ->
      if user.global_name == text do
        [member | acc]
      else
        acc
      end
    end)
    |> one_or_none(:global_name)
  end

  @spec one_or_none([Member.t()], :global_name | :username) ::
          nil | {:ok, Member.t()} | {:error, Converters.reason()}
  defp one_or_none([], _via), do: nil
  defp one_or_none([member], _via), do: {:ok, member}
  defp one_or_none([_member | _members], via), do: {:error, {:multiple_matches, :by, via}}

  @spec not_found_error(String.t()) :: {:error, Converters.reason()}
  defp not_found_error(text) do
    {:error, {:not_found, {:by, :name, Helpers.escape_server_mentions(text), []}}}
  end
end
