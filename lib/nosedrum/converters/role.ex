defmodule Nosedrum.Converters.Role do
  @moduledoc false

  alias Nosedrum.Converters
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache

  @doc """
  Convert a Discord role mention to an ID.
  This also works if the given string is just the ID.

  ## Examples

    iex> Nosedrum.Converters.Role.role_mention_to_id("<@&10101010>")
    {:ok, 10101010}
    iex> Nosedrum.Converters.Role.role_mention_to_id("<@&101010>")
    {:ok, 101010}
    iex> Nosedrum.Converters.Role.role_mention_to_id("91203")
    {:ok, 91203}
    iex> Nosedrum.Converters.Role.role_mention_to_id("not valid")
    {:error, "not a valid role ID"}
  """
  @spec role_mention_to_id(String.t()) :: {:ok, pos_integer()} | :error
  def role_mention_to_id(text) do
    maybe_id =
      text
      |> String.trim_leading("<@&")
      |> String.trim_trailing(">")

    case Integer.parse(maybe_id) do
      {value, ""} -> {:ok, value}
      _ -> :error
    end
  end

  @spec find_by_name(
          [Nostrum.Struct.Guild.Role.t()],
          String.t(),
          boolean()
        ) :: Nostrum.Struct.Guild.Role.t() | {:error, Converters.reason()}
  defp find_by_name(roles, name, case_insensitive) do
    if case_insensitive do
      downcased_name = String.downcase(name)

      error_return = {
        :error,
        {:not_found, {:by, :name, downcased_name, [:case_insensitive]}}
      }

      Enum.find_value(
        roles,
        error_return,
        fn
          # credo:disable-for-next-line
          %{name: name} = role -> if String.downcase(name) == downcased_name, do: {:ok, role}
          _other -> nil
        end
      )
    else
      error_return = {:error, {:not_found, {:by, :name, name, []}}}

      Enum.find_value(
        roles,
        error_return,
        fn
          %{name: ^name} = role -> {:ok, role}
          _other -> nil
        end
      )
    end
  end

  @spec find_role(
          [Nostrum.Struct.Guild.Role.t()],
          String.t(),
          boolean
        ) :: {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, Converters.reason()}
  def find_role(roles, text, ilike) do
    case role_mention_to_id(text) do
      # We have a direct snowflake given. Try to find an exact match.
      {:ok, id} ->
        error_return = {:error, {:not_found, {:by, :id, id, []}}}

        Enum.find_value(roles, error_return, fn
          %{id: ^id} = role -> {:ok, role}
          _other -> nil
        end)

      # We do not have a snowflake given, assume it's a name and search through the roles by name.
      :error ->
        find_by_name(roles, text, ilike)
    end
  end

  @spec into(String.t(), Nostrum.Snowflake.t(), boolean) ::
          {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, String.t()}
  def into(text, guild_id, ilike) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        find_role(Map.values(guild.roles), text, ilike)

      {:error, _reason} ->
        case Api.get_guild_roles(guild_id) do
          {:ok, roles} ->
            find_role(roles, text, ilike)

          {:error, _reason} ->
            {:error, "This guild is not in the cache, nor could it be fetched from the API."}
        end
    end
  end
end
