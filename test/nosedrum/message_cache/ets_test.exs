defmodule Nosedrum.MessageCache.ETSTest do
  alias Nosedrum.MessageCache.ETS, as: MessageCache
  use ExUnit.Case, async: true

  describe "get/2-3" do
    setup do
      pid = start_supervised!(MessageCache)
      tid = GenServer.call(pid, :tid)

      message = %{
        author: %{
          id: 12_319_031
        },
        content: "testing is fun",
        channel_id: 123_913_103,
        id: 1_231,
        guild_id: 12_301_283_091
      }

      :ok = MessageCache.consume(message, tid)
      %{tid: tid, message: message}
    end

    test "returns nil for unknown guild", %{tid: tid} do
      refute MessageCache.get(1_203_912_301, 9031, tid)
    end

    test "returns nil for cached guild with unknown message ID", %{tid: tid, message: message} do
      refute MessageCache.get(message.guild_id, 3_751, tid)
    end

    test "returns cached message tuple for cached entry", %{tid: tid, message: message} do
      cache_message = {message.id, message.channel_id, message.author.id, message.content}
      assert ^cache_message = MessageCache.get(message.guild_id, message.id, tid)
    end
  end

  describe "update/2" do
    setup do
      pid = start_supervised!(MessageCache)
      tid = GenServer.call(pid, :tid)

      message = %{
        author: %{
          id: 12_319_031
        },
        content: "testing is fun",
        channel_id: 123_913_103,
        id: 1_231,
        guild_id: 12_301_283_091
      }

      :ok = MessageCache.consume(message, tid)
      %{tid: tid, message: message}
    end

    test "does not update state for unknown guilds", %{tid: tid} do
      old_state = :ets.tab2list(tid)

      irrelevant_message = %{
        author: %{
          id: 123_901_823
        },
        content: "whatever",
        channel_id: 1_203_981_092,
        id: 1_205_912,
        guild_id: 57_189
      }

      assert :ok = MessageCache.update(irrelevant_message, tid)
      assert ^old_state = :ets.tab2list(tid)
    end

    test "updates message content for cached messages", %{tid: tid, message: message} do
      updated_message = %{message | content: "new content"}
      cache_entry = {message.id, message.channel_id, message.author.id, updated_message.content}
      assert :ok = MessageCache.update(updated_message, tid)
      assert ^cache_entry = MessageCache.get(message.guild_id, message.id, tid)
    end
  end

  describe "recent_in_guild/2-3" do
    setup do
      pid = start_supervised!(MessageCache)
      tid = GenServer.call(pid, :tid)
      guild_id = 1_290_318_419

      messages = [
        %{
          author: %{id: 1_931},
          content: "abc",
          channel_id: 12_931,
          id: 120_391,
          guild_id: guild_id
        },
        %{
          author: %{id: 152_801},
          content: "asdc",
          channel_id: 120_491,
          id: 15_795,
          guild_id: guild_id
        }
      ]

      messages
      |> Enum.reverse()
      |> Enum.each(&MessageCache.consume(&1, tid))

      %{tid: tid, messages: messages}
    end

    test "returns empty list for unknown guild", %{tid: tid} do
      assert [] = MessageCache.recent_in_guild(21_951_095, nil, tid)
    end

    test "returns all messages for cached guild", %{tid: tid, messages: [msg, second_msg]} do
      first_msg_id = msg.id
      second_msg_id = second_msg.id

      assert [{^first_msg_id, _, _, _}, {^second_msg_id, _, _, _}] =
               MessageCache.recent_in_guild(msg.guild_id, nil, tid)
    end

    test "returns sliced messages with specified limit", %{tid: tid, messages: [msg | _]} do
      msg_id = msg.id
      assert [{^msg_id, _, _, _}] = MessageCache.recent_in_guild(msg.guild_id, 1, tid)
    end
  end

  describe "argument defaults" do
    setup do
      start_supervised!(MessageCache)

      :ok
    end

    test "get/2-3 provides a default table name" do
      refute MessageCache.get(129_031, 140_824)
    end

    test "recent_in_guild/2-3 provides a default table name" do
      assert [] = MessageCache.recent_in_guild(1_295_012_951, nil)
    end

    test "recent_in_guild/2-3 provides a default table name with a specified limit" do
      assert [] = MessageCache.recent_in_guild(1_295_102_591, 50)
    end

    test "consume/1-2 provides a default table name" do
      message = %{
        author: %{id: 120_391_032_913},
        channel_id: 12_903_180_941,
        content: "woop woop",
        id: 1_203_910_958_102,
        guild_id: 12_095_190
      }

      assert :ok = MessageCache.consume(message)
    end

    test "update/1-2 provides a default table name" do
      message = %{
        author: %{id: 1_590_215_920},
        channel_id: 129_810_412,
        content: "hello world",
        guild_id: 195_810_295,
        id: 125_091_809_251
      }

      assert :ok = MessageCache.update(message)
    end
  end
end
