defmodule Nosedrum.Converters do
  @moduledoc """
  Conversion from command arguments to various types.

  This module provides an interface to the individual converter modules.
  Most converter functions related to Discord itself take a `guild_id`
  which is used for loading the guild from the cache. If the guild could
  not be load from the cache, implementations will usually attempt to
  fetch the relevant data from the API.
  """

  alias Nostrum.Error.ApiError
  alias Nostrum.Snowflake
  alias Nostrum.Struct.Guild.{Member, Role}
  alias Nostrum.Struct.{Channel, Guild}

  @typedoc """
  Additional options that were used when searching the cache.

  ## Items

  - `:case_insensitive`: the search was done without respect to string casing,
  for example, a role conversion with `ilike` specified.

  - `:not_exact`: the search was not exact, for example, a member search by
  name without discriminator.
  """
  @typedoc since: "0.6.0"
  @type option :: :case_insensitive | :not_exact

  @typedoc """
  Collection of options that were used when searching the cache.
  """
  @typedoc since: "0.6.0"
  @type options :: [option]

  @typedoc """
  Specifies the reason for why a converter operation failed.

  ## Items

  The reason can be two things:

  - Nosedrum could interpret the input as a direct snowflake and tried to fetch
  it both via the cache and via the API. If both fetches fail (which is very
  unlikely to happen), `:uncached_and_fetch_error` can be returned to signify
  that the given snowflake is both uncached and could not be fetched from the
  API. The error from nostrum is also returned in this case.

  - The more common case is that the user input could simply not be found.
  Nosedrum will tell you whether this was a search by `:id` or `:name`, and the
  `query` field contains the parsed query as interpreted by the converter. You
  can use this to provide user feedback, but make sure to escape it properly,
  in case it is a string.

  You will likely want to handle the latter case.
  """
  @typedoc since: "0.6.0"
  @type reason ::
          {:not_found, {:by, :id | :name, parsed_query :: String.t() | Snowflake.t(), options}}
          | {:uncached_and_fetch_error, ApiError.t()}

  @doc """
  Convert the given `text` to a `t:Nostrum.Struct.Channel.t/0`.

  Lookup is attempted in the following order:
  - by direct ID, such as `9999`
  - by mention, such as `<#9999>`
  - by name, such as `mod-log`
  """
  @spec to_channel(String.t(), Guild.id()) :: {:ok, Channel.t()} | {:error, reason}
  defdelegate to_channel(text, guild_id), to: __MODULE__.Channel, as: :into

  @doc """
  Convert the given `text` to a `t:Nostrum.Struct.Guild.Member.t/0`.

  Lookup is attempted in the following order:
  - by direct ID, such as `1231321`
  - by mention, such as `<@1231321>`, `<@!1231321>`
  - by name#discrim combination, such as `Jimmy#9999`
  - by name, such as `Jimmy`

  Note that name lookups may not be 100% accurate: if there are multiple users
  with the same name on the server, the first one found will be used.
  """
  @spec to_member(String.t(), Guild.id()) :: {:ok, Member.t()} | {:error, reason}
  defdelegate to_member(text, guild_id), to: __MODULE__.Member, as: :into

  @doc """
  Convert the given `text` to a `t:Nostrum.Struct.Guild.Role.t/0`.

  Lookup is attempted in the following order:
  - by direct ID, such as `5555`
  - by mention, such as `<@&5555>`
  - by name, such as `Bots`

  The optional `ilike` argument determines whether the role name
  search should be case-insensitive. This is useful if your users
  are lazy and you want to save them from holding down an extra
  button on their keyboard.
  """
  @spec to_role(String.t(), Guild.id(), boolean()) :: {:ok, Role.t()} | {:error, reason}
  defdelegate to_role(text, guild_id, ilike \\ false), to: __MODULE__.Role, as: :into
end
