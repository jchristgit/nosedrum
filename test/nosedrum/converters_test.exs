defmodule Nosedrum.ConvertersTest do
  alias Nosedrum.Converters
  alias Nostrum.Cache.CacheSupervisor
  alias Nostrum.Cache.Guild.GuildRegister
  alias Nostrum.Struct.Guild
  use ExUnit.Case

  doctest Nosedrum.Converters

  setup_all do
    start_supervised!(CacheSupervisor)

    guild = %Guild{
      id: 940_124,
      channels: %{},
      roles: %{},
      members: %{}
    }

    GuildRegister.create_guild_process(guild.id, guild)
    %{guild: guild}
  end

  describe "to_channel/2" do
    test "returns `{:error, reason}` with uncached channel", %{guild: guild} do
      assert {:error, _reason} = Converters.to_channel("abc", guild.id)
    end
  end

  describe "to_member/2" do
    test "returns `{:error, reason}` with uncached member", %{guild: guild} do
      assert {:error, _reason} = Converters.to_member("abc", guild.id)
    end
  end

  describe "to_role/2,3" do
    test "returns `{:error, reason}` with uncached role", %{guild: guild} do
      assert {:error, _reason} = Converters.to_role("abc", guild.id)
    end
  end
end
