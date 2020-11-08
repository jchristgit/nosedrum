defmodule Nosedrum.PredicatesTest do
  alias Nosedrum.Predicates
  alias Nostrum.Cache.CacheSupervisor
  alias Nostrum.Cache.Guild.GuildRegister
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.{Member, Role}
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.User
  use ExUnit.Case

  setup_all do
    start_supervised!(CacheSupervisor)
    admin_id = 120_391
    guest_id = 981_723_981
    cached_guild_id = 555
    role_can_ban_id = 125_910

    role_can_ban = %Role{
      id: role_can_ban_id,
      permissions: Nostrum.Permission.to_bit(:ban_members)
    }

    cached_guild = %Guild{
      id: cached_guild_id,
      members: [
        %Member{
          roles: [role_can_ban_id],
          user: %User{id: admin_id}
        },
        %Member{
          roles: [],
          user: %User{id: guest_id}
        }
      ],
      roles: [
        role_can_ban
      ]
    }

    GuildRegister.create_guild_process(cached_guild_id, cached_guild)

    %{admin_id: admin_id, guest_id: guest_id, guild_id: cached_guild_id}
  end

  describe "evaluate/2" do
    setup do
      %{msg: nil}
    end

    defp always_passthrough(_msg), do: :passthrough
    defp always_error(_msg), do: {:error, "boom"}

    test "returns `:passthrough` if all predicates do", %{msg: msg} do
      predicates = [&always_passthrough/1, &always_passthrough/1]
      assert :passthrough = Predicates.evaluate(msg, predicates)
    end

    test "returns `{:error, reason}` if any predicate does", %{msg: msg} do
      predicates = [&always_passthrough/1, &always_error/1]
      assert {:error, _reason} = Predicates.evaluate(msg, predicates)
    end
  end

  describe "guild_only/1" do
    test "returns `:passthrough` if message was sent on guild" do
      msg = %Message{guild_id: 1_239_018}
      assert :passthrough = Predicates.guild_only(msg)
    end

    test "returns `{:error, reason}` if message was not sent on guild" do
      msg = %Message{guild_id: nil}
      assert {:error, _reason} = Predicates.guild_only(msg)
    end
  end

  describe "has_permission/1" do
    test "raises `FunctionClauseError` for non-permissions" do
      assert_raise FunctionClauseError, fn ->
        Predicates.has_permission(:ok)
      end
    end

    test "returns `{:noperm, _reason}` when not used on a guild" do
      predicate = Predicates.has_permission(:ban_members)
      message = %Message{guild_id: nil}
      assert {:noperm, _reason} = predicate.(message)
    end

    test "returns `{:error, _reason}` when guild is uncached" do
      predicate = Predicates.has_permission(:ban_members)
      message = %Message{guild_id: 9_129_301}
      assert {:error, _reason} = predicate.(message)
    end

    test "returns `{:error, _reason}` when member is uncached", %{guild_id: guild_id} do
      predicate = Predicates.has_permission(:ban_members)
      message = %Message{author: %User{id: 1_239_012_390_132}, guild_id: guild_id}
      assert {:error, _reason} = predicate.(message)
    end

    test "returns `{:noperm, _reason}` when member does not have permissions", %{
      guest_id: guest_id,
      guild_id: guild_id
    } do
      predicate = Predicates.has_permission(:ban_members)
      message = %Message{author: %User{id: guest_id}, guild_id: guild_id}
      assert {:noperm, _reason} = predicate.(message)
    end

    test "returns `:passthrough` when member has permissions", %{
      admin_id: admin_id,
      guild_id: guild_id
    } do
      predicate = Predicates.has_permission(:ban_members)
      message = %Message{author: %User{id: admin_id}, guild_id: guild_id}
      assert :passthrough = predicate.(message)
    end
  end
end
