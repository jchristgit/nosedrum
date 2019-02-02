defmodule Nosedrum.Converters do
  @moduledoc """
  Conversion from command arguments to various types.

  This module provides an interface to the individual converter modules.
  Most converter functions related to Discord itself take a `guild_id`
  which is used for loading the guild from the cache. If the guild could
  not be load from the cache, implementations will usually attempt to
  fetch the relevant data from the API.
  """

  alias Nostrum.Struct.{Channel, Guild}
  alias Nostrum.Struct.Guild.{Member, Role}

  # TODO: add support for choosing only specific channel types, because
  #       e.g. voice or category channels may not be desirable in some cases
  @doc """
  Convert the given `text` to a `t:Nostrum.Struct.Channel.t/0`.

  Lookup is attempted in the following order:
  - by direct ID, such as `9999`
  - by mention, such as `<#9999>`
  - by name, such as `mod-log`
  """
  @spec to_channel(String.t(), Guild.id()) :: {:ok, Channel.t()} | {:error, String.t()}
  def to_channel(text, guild_id) do
  end

  @doc """
  Convert the given `text` to a `t:Nostrum.Struct.Guild.Member.t/0`.

  Lookup is attempted in the following order:
  - by direct ID, such as `1231321`
  - by mention, such as `<@1231321>`, `<@!1231321>`
  - by name#discrim combination, such as `Jimmy#9999`
  - by name, such as `Jimmy`
  - by nickname, such as `SuperJimmy`

  Note that name and nickname lookups may not be 100% accurate: if there are
  multiple users with the same name on the server, the first one found will be
  used.
  """
  @spec to_member(String.t(), Guild.id()) :: {:ok, Member.t()} | {:error, String.t()}
  def to_member(text, guild_id) do
    __MODULE__.Member.into(text, guild_id)
  end

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
  @spec to_role(String.t(), Guild.id(), boolean()) :: {:ok, Role.t()} | {:error, String.t()}
  def to_role(text, guild_id, ilike \\ false) do
    __MODULE__.Role.into(text, guild_id, ilike)
  end
end
