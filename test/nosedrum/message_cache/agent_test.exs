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

      MessageCache.consume(message, pid)
      %{pid: pid, message: message}
    end

    test "returns nil for unknown guild", %{pid: pid} do
      refute MessageCache.get(1_203_912_301, 9031, pid)
    end

    test "returns nil for cached guild with unknown message ID", %{pid: pid, message: message} do
      refute MessageCache.get(message.guild_id, 3_751, pid)
    end

    test "returns cached message tuple for cached entry", %{pid: pid, message: message} do
      assert ^message = MessageCache.get(message.guild_id, message.id, pid)
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

      MessageCache.consume(message, pid)
      %{pid: pid, message: message}
    end

    test "updates state for new guilds", %{pid: pid} do
      new_message = %{
        author: %{
          id: 123_901_823
        },
        content: "whatever",
        channel_id: 1_203_981_092,
        id: 1_205_912,
        guild_id: 57_189
      }

      assert MessageCache.update(new_message, pid)
    end

    test "updates message content for cached messages", %{pid: pid, message: message} do
      updated_message = %{message | content: "new content"}
      assert MessageCache.update(updated_message, pid)
      assert ^updated_message = MessageCache.get(message.guild_id, message.id, pid)
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
      assert [] = MessageCache.recent_in_guild(21_951_095, :infinity, pid)
    end

    test "returns all messages for cached guild", %{pid: pid, messages: [msg, second_msg]} do
      assert [^msg, ^second_msg] = MessageCache.recent_in_guild(msg.guild_id, :infinity, pid)
    end

    test "returns sliced messages with specified limit", %{pid: pid, messages: [msg | _]} do
      assert [^msg] = MessageCache.recent_in_guild(msg.guild_id, 1, pid)
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

      MessageCache.consume(message, pid)
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

      assert message = MessageCache.get(message.guild_id, message.id, pid)
      assert [message] = MessageCache.recent_in_guild(message.guild_id, :infinity, pid)
      assert MessageCache.consume(new_message, pid)
      assert [^new_message] = MessageCache.recent_in_guild(message.guild_id, :infinity, pid)

      assert ^new_message = MessageCache.get(new_message.guild_id, new_message.id, pid)
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
      assert [] = MessageCache.recent_in_guild(1_295_012_951, :infinity)
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

      assert MessageCache.consume(message)
    end

    test "update/1-2 defaults to using the module name" do
      assert MessageCache.update(%{guild_id: 1_291_049_124_210})
    end
  end
end
