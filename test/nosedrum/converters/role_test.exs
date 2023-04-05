defmodule Nosedrum.Converters.RoleTest do
  alias Nosedrum.Converters.Role, as: RoleConverter
  alias Nostrum.Cache.CacheSupervisor
  alias Nostrum.Cache.GuildCache.ETS, as: GuildCache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role
  use ExUnit.Case

  doctest Nosedrum.Converters.Role

  setup_all do
    start_supervised!(CacheSupervisor)

    role = %Role{
      id: 129_031_231,
      name: "Test Role"
    }

    guild = %Guild{
      id: 512,
      roles: [role]
    }

    GuildCache.create(guild)

    %{guild: guild, role: role}
  end

  describe "into/2" do
    # does API call
    # test "returns `{:error, reason}` for uncached guilds"

    test "returns `{:ok, role}` for by-id lookup", %{guild: guild, role: role} do
      assert {:ok, ^role} = RoleConverter.into("#{role.id}", guild.id, false)
    end

    test "returns `{:error, reason}` for unsuccessful by-id lookup", %{guild: guild} do
      assert {:error, _reason} = RoleConverter.into("210381991023", guild.id, false)
    end

    test "returns `{:ok, role}` for by-mention lookup", %{guild: guild, role: role} do
      assert {:ok, ^role} = RoleConverter.into("<@&#{role.id}>", guild.id, false)
    end

    test "returns `{:ok, role}` for by-name lookup", %{guild: guild, role: role} do
      assert {:ok, ^role} = RoleConverter.into(role.name, guild.id, false)
    end

    test "returns `{:ok, role}` for case-insensitive by-name lookup", %{guild: guild, role: role} do
      assert {:ok, ^role} = RoleConverter.into(String.upcase(role.name), guild.id, true)
    end

    test "returns `{:error, reason}` for non-matching case-insensitive by-name lookup", %{
      guild: guild,
      role: role
    } do
      assert {:error, _reason} = RoleConverter.into(String.upcase(role.name), guild.id, false)
    end
  end
end
