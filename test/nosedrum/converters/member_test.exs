defmodule Nosedrum.Converters.MemberTest do
  alias Nosedrum.Converters.Member, as: MemberConverter
  alias Nostrum.Cache.CacheSupervisor
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Cache.UserCache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member
  use ExUnit.Case

  doctest Nosedrum.Converters.Member

  setup_all do
    start_supervised!(CacheSupervisor)

    user = %{
      id: 34_444,
      username: "Testuser",
      discriminator: 1234
    }

    guild_id = 5189

    member = %Member{nick: "Superuser", user_id: user.id}
    raw_member = %{nick: member.nick, user: %{id: member.user_id}}

    guild = %Guild{
      id: guild_id
    }

    MemberCache.create(guild.id, raw_member)
    UserCache.create(user)
    GuildCache.create(guild)

    %{guild: guild, member: member, user: user}
  end

  describe "into/2" do
    # performs API call
    # test "returns `{:ok, member}` for direct ID lookups"
    # performs API call
    # test "returns `{:ok, member}` for user mentions"
    # performs API call
    # test "returns `{:ok, member}` for nickname mentions"

    test "returns `{:error, _reason}` for uncached guilds" do
      assert {:error, _reason} = MemberConverter.into("abc", 123_901_823_912_138)
    end

    test "returns `{:error, _reason}` for unknown users", %{guild: guild} do
      assert {:error, _reason} = MemberConverter.into("abc", guild.id)
    end

    test "returns `{:error, _reason}` with bad `name#discrim` combo", %{
      guild: guild,
      user: user
    } do
      text = "#{user.username}#1029381039812"
      assert {:error, _reason} = MemberConverter.into(text, guild.id)
    end

    test "returns `{:error, _reason}` with unsuccessful `name#discrim` lookup", %{guild: guild} do
      text = "Niko Laus#9999"
      assert {:error, _reason} = MemberConverter.into(text, guild.id)
    end

    test "returns `{:ok, member}` with successful `name#discrim` lookup", %{
      guild: guild,
      member: member,
      user: user
    } do
      text = "#{user.username}##{user.discriminator}"
      assert {:ok, ^member} = MemberConverter.into(text, guild.id)
    end

    test "returns `{:ok, member}` with successful by-name lookup", %{
      guild: guild,
      member: member,
      user: user
    } do
      assert {:ok, ^member} = MemberConverter.into(user.username, guild.id)
    end
  end
end
