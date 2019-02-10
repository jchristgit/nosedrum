defmodule Nosedrum.MessageCache.AgentTest do
  alias Nosedrum.MessageCache.Agent, as: MessageCache
  use ExUnit.Case, async: true

  describe "start_link/1" do
    test "properly initializes the internal state" do
      pid =
        start_supervised!(%{id: MessageCache, start: {MessageCache, :start_link, [[limit: 5]]}})

      assert {%{}, false, 5} = Agent.get(pid, & &1)
    end
  end

  describe "get/2-3" do
    setup do
      pid = start_supervised!(MessageCache)

      message = %{
        author: %{
          id: 12_319_031
        },
        content: "testing is fun",
        channel_id: 123_913_103,
        id: 1_231,
        guild_id: 12_301_283_091
      }

      :ok = MessageCache.consume(message, pid)
      %{pid: pid, message: message}
    end

    test "returns nil for unknown guild", %{pid: pid} do
      refute MessageCache.get(1_203_912_301, 9031, pid)
    end

    test "returns nil for cached guild with unknown message ID", %{pid: pid, message: message} do
      refute MessageCache.get(message.guild_id, 3_751, pid)
    end

    test "returns cached message tuple for cached entry", %{pid: pid, message: message} do
      cache_message = {message.id, message.channel_id, message.author.id, message.content}
      assert ^cache_message = MessageCache.get(message.guild_id, message.id, pid)
    end
  end

  describe "update/2" do
    setup do
      pid = start_supervised!(MessageCache)

      message = %{
        author: %{
          id: 12_319_031
        },
        content: "testing is fun",
        channel_id: 123_913_103,
        id: 1_231,
        guild_id: 12_301_283_091
      }

      :ok = MessageCache.consume(message, pid)
      %{pid: pid, message: message}
    end

    test "does not update state for unknown guilds", %{pid: pid} do
      old_state = Agent.get(pid, fn state -> state end)

      irrelevant_message = %{
        author: %{
          id: 123_901_823
        },
        content: "whatever",
        channel_id: 1_203_981_092,
        id: 1_205_912,
        guild_id: 57_189
      }

      assert :ok = MessageCache.update(irrelevant_message, pid)
      assert ^old_state = Agent.get(pid, fn state -> state end)
    end

    test "updates message content for cached messages", %{pid: pid, message: message} do
      updated_message = %{message | content: "new content"}
      cache_entry = {message.id, message.channel_id, message.author.id, updated_message.content}
      assert :ok = MessageCache.update(updated_message, pid)
      assert ^cache_entry = MessageCache.get(message.guild_id, message.id, pid)
    end
  end

  describe "recent_in_guild/2-3" do
    setup do
      pid = start_supervised!(MessageCache)
      guild_id = 1_290_318_419

      messages = [
        %{
          author: %{id: 1931},
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
      |> Enum.each(&MessageCache.consume(&1, pid))

      %{pid: pid, messages: messages}
    end

    test "returns empty list for unknown guild", %{pid: pid} do
      assert [] = MessageCache.recent_in_guild(21_951_095, nil, pid)
    end

    test "returns all messages for cached guild", %{pid: pid, messages: [msg, second_msg]} do
      first_msg_id = msg.id
      second_msg_id = second_msg.id

      assert [{^first_msg_id, _, _, _}, {^second_msg_id, _, _, _}] =
               MessageCache.recent_in_guild(msg.guild_id, nil, pid)
    end

    test "returns sliced messages with specified limit", %{pid: pid, messages: [msg | _]} do
      msg_id = msg.id
      assert [{^msg_id, _, _, _}] = MessageCache.recent_in_guild(msg.guild_id, 1, pid)
    end
  end

  describe "`limit: n` option" do
    setup do
      pid =
        start_supervised!(%{id: MessageCache, start: {MessageCache, :start_link, [[limit: 1]]}})

      message = %{
        author: %{id: 123_901},
        channel_id: 1_390,
        content: "test",
        id: 1_290_134,
        guild_id: 12_039_182_390
      }

      :ok = MessageCache.consume(message, pid)
      %{pid: pid, message: message}
    end

    test "throws off old messages upon hitting the limit", %{pid: pid, message: message} do
      new_message = %{
        author: %{id: 192_051},
        channel_id: 190_281,
        content: "another test",
        id: 125_091,
        guild_id: message.guild_id
      }

      new_message_cache_entry =
        {new_message.id, new_message.channel_id, new_message.author.id, new_message.content}

      message_id = message.id
      assert {^message_id, _, _, _} = MessageCache.get(message.guild_id, message.id, pid)
      assert [{^message_id, _, _, _}] = MessageCache.recent_in_guild(message.guild_id, nil, pid)
      assert :ok = MessageCache.consume(new_message, pid)
      assert [^new_message_cache_entry] = MessageCache.recent_in_guild(message.guild_id, nil, pid)

      assert ^new_message_cache_entry =
               MessageCache.get(new_message.guild_id, new_message.id, pid)
    end
  end

  describe "argument defaults" do
    setup do
      start_supervised!(MessageCache, %{
        id: MessageCache,
        start: {MessageCache, :start_link, [[name: Nosedrum.MessageCache.Agent]]}
      })

      :ok
    end

    test "get/2-3 defaults to using the module name" do
      refute MessageCache.get(129_031, 140_824)
    end

    test "recent_in_guild/2-3 with no limit defaults to using the module name" do
      assert [] = MessageCache.recent_in_guild(1_295_012_951, nil)
    end

    test "recent_in_guild/2-3 with limit defaults to using the module name" do
      assert [] = MessageCache.recent_in_guild(1_295_102_591, 50)
    end

    test "consume/1-2 defaults to using the module name" do
      message = %{
        author: %{id: 120_391_032_913},
        channel_id: 12_903_180_941,
        content: "woop woop",
        id: 1_203_910_958_102,
        guild_id: 12_095_190
      }

      assert :ok = MessageCache.consume(message)
    end

    test "update/1-2 defaults to using the module name" do
      assert :ok = MessageCache.update(%{guild_id: 1_291_049_124_210})
    end
  end
end
