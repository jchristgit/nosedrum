defmodule Nosedrum.Converters.Member do
  @moduledoc false

  alias Nosedrum.Converters
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Cache.UserCache
  alias Nostrum.Snowflake
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

  @doc """
  Convert a given string in the form name#discrim
  to parts {name, discrim} parts. If no "#" can be
  found in the string, returns `:error`.
  Additionally, this function verifies that the
  discriminator is between 0001 and 9999 (the range
  of valid discriminators on Discord).

  ## Examples

    iex> Nosedrum.Converters.Member.text_to_name_and_discrim("hello#0312")
    {"hello", 0312}
    iex> Nosedrum.Converters.Member.text_to_name_and_discrim("marc#4215")
    {"marc", 4215}
    iex> Nosedrum.Converters.Member.text_to_name_and_discrim("name")
    :error
    iex> Nosedrum.Converters.Member.text_to_name_and_discrim("joe#109231")
    :error
  """
  @spec text_to_name_and_discrim(String.t()) :: {String.t(), 0001..9999} | :error
  def text_to_name_and_discrim(text) do
    match_result = :binary.match(String.reverse(text), "#")

    if match_result != :nomatch do
      {index, _length} = match_result
      index = String.length(text) - index
      {name, discrim} = String.split_at(text, index - 1)
      discrim = String.trim_leading(discrim, "#")

      case Integer.parse(discrim) do
        {value, _remainder} when value in 0001..9999 ->
          {name, value}

        _err ->
          :error
      end
    else
      :error
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
        {query, failure_options} =
          case text_to_name_and_discrim(text) do
            {name, discrim} ->
              query =
                :nosedrum_member_converter_qlc.find_by(
                  guild_id,
                  name,
                  discrim,
                  MemberCache,
                  UserCache
                )

              {query, []}

            :error ->
              query =
                :nosedrum_member_converter_qlc.find_by(guild_id, text, MemberCache, UserCache)

              {query, [:not_exact]}
          end

        case :qlc.eval(query) do
          [member | _] -> {:ok, member}
          [] -> {:error, {:not_found, {:by, :name, text, failure_options}}}
        end
    end
  end
end
