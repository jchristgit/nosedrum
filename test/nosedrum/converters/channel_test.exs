defmodule Nosedrum.Converters.ChannelTest do
  alias Nosedrum.Converters.Channel, as: ChannelConverter
  alias Nostrum.Cache.CacheSupervisor
  alias Nostrum.Cache.GuildCache.ETS, as: GuildCache
  alias Nostrum.Struct.Channel
  alias Nostrum.Struct.Guild
  use ExUnit.Case

  doctest Nosedrum.Converters.Channel

  setup_all do
    start_supervised!(CacheSupervisor)

    channel = %Channel{
      id: 1_203_913,
      name: "bot-tests"
    }

    guild = %Guild{
      id: 940_124,
      channels: [channel]
    }

    GuildCache.create(guild)
    %{channel: channel, guild: guild}
  end

  describe "into/2" do
    # makes API call
    # test "returns `{:error, reason}` for uncached guild"

    test "returns `{:error, reason}` for unsuccessful by-id lookup", %{guild: guild} do
      assert {:error, _reason} = ChannelConverter.into("123908102931", guild.id)
    end

    test "returns `{:error, reason}` for unsucccesful by-mention lookup", %{guild: guild} do
      assert {:error, _reason} = ChannelConverter.into("<#123819237>", guild.id)
    end

    test "returns `{:error, reason}` for unsuccessful by-name lookup", %{guild: guild} do
      assert {:error, _reason} = ChannelConverter.into("absent test channel", guild.id)
    end

    test "returns `{:ok, channel}` for by-id lookup", %{channel: channel, guild: guild} do
      assert {:ok, ^channel} = ChannelConverter.into("#{channel.id}", guild.id)
    end

    test "returns `{:ok, channel}` for by-mention lookup", %{channel: channel, guild: guild} do
      assert {:ok, ^channel} = ChannelConverter.into("<##{channel.id}>", guild.id)
    end

    test "returns `{:ok, channel}` for by-name lookup", %{channel: channel, guild: guild} do
      assert {:ok, ^channel} = ChannelConverter.into(channel.name, guild.id)
    end
  end
end
