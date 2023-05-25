defmodule Nosedrum.TextCommand.Predicates do
  @moduledoc """
  Built-in command predicates and predicate evaluation.

  `c:Nosedrum.TextCommand.predicates/0` allows commands to specify a set of
  conditions that must be met before a command is invoked, effectively allowing
  you to deny access to certain access. For instance, allowing every user on
  your server to issue a ban command may not be desirable.

  For using the `c:Nosedrum.TextCommand.predicates/0` callback, you can either
  define your own predicates or use [those provided by this
  module](#predicates).
  """
  @moduledoc since: "0.2.0"

  alias Nostrum.Cache.GuildCache
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Permission
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Message

  @all_permissions Permission.all()

  @typedoc """
  The result of a predicate evaluation, determining whether the command
  invocation should proceed or abort.

  The values represent the following:
  - `:passthrough` if the predicate permits the command to be invoked.
  - `{:noperm, any()}` if the predicate does not permit the command to be invoked.
  - `{:error, any()}` if the predicate could not determine its result.

  On `:passthrough`, invokers will continue with predicate checking and
  finally invoke the command. On `:noperm` or `:error`, command execution
  is aborted.
  """
  @typedoc since: "0.2.0"
  @type evaluation_result :: :passthrough | {:noperm, any()} | {:error, any()}

  @typedoc """
  A condition that must pass before a command is invoked.

  ## Example

      defmodule MyBot.Predicates do
        alias Nostrum.Struct.Message

        def guild_only(%Message{guild_id: nil}) do
          {:error, "This command can only be used on guilds."}
        end

        def guild_only(_msg), do: :passthrough
      end
  """
  @typedoc since: "0.2.0"
  @type predicate :: (Message.t() -> evaluation_result)

  @doc """
  Lazily evaluate all given `predicates` and return the result.

  While usually used by command invokers, you can use this function if you need
  to manually evaluate the result of predicates.

  ## Return value
  If all predicates returned `:passthrough`, `:passthrough` is returned.
  Otherwise, the error of the first predicate returning one is returned.
  """
  @doc section: :evaluation
  @doc since: "0.2.0"
  @spec evaluate(Message.t(), [predicate]) :: evaluation_result
  def evaluate(message, predicates) do
    predicates
    |> Stream.map(& &1.(message))
    |> Enum.find(:passthrough, &match?({kind, _reason} when kind in [:error, :noperm], &1))
  end

  @doc """
  Check whether the command was invoked on a guild.

  Note that `has_permission/1` already checks whether a command was invoked
  on a guild and this predicate does not need to be stack with it.
  """
  @doc section: :predicates
  @doc since: "0.2.0"
  def guild_only(%Message{guild_id: nil}), do: {:error, "this command can only be used on guilds"}
  def guild_only(_), do: :passthrough

  @doc """
  Check whether the message author has the given `permission`.

  This does not directly return an `t:evaluation_result/0`: it returns a
  function allowing you to use this in your `c:Nosedrum.TextCommand.predicates/0`
  callback.

  When evaluation fails, an error with a description of the required permission
  is returned, or another error when the permission could not be checked on the
  author - for example, because the guild or member was not found in the cache.

  ## Example

      defmodule MyBot.Cogs.Ban do
        @behaviour Nosedrum.TextCommand

        def usage, do: ["ban <member>"]
        def description, do: "Ban the given `member`."
        def predicates, do: [Nosedrum.TextCommand.Predicates.has_permission(:ban_members)]
        def command(msg, [target]) do
          # ... 🔨
        end
      end
  """
  @doc section: :predicates
  @doc since: "0.2.0"
  @spec has_permission(Permission.t()) :: predicate
  def has_permission(permission) when permission in @all_permissions do
    fn msg ->
      with {:is_on_guild, true} <- {:is_on_guild, msg.guild_id != nil},
           {:ok, guild} <- GuildCache.get(msg.guild_id),
           {:member, {:ok, member}} <-
             {:member, MemberCache.get(msg.guild_id, msg.author.id)},
           {:has_permission, true} <-
             {:has_permission, permission in Member.guild_permissions(member, guild)} do
        :passthrough
      else
        {:error, _reason} ->
          {:error, "❌ this guild is not in the cache, can't check perms"}

        {:has_permission, false} ->
          permission_string =
            permission
            |> Atom.to_string()
            |> String.upcase()

          {:noperm, "🚫 you need the `#{permission_string}` permission to do that"}

        {:is_on_guild, false} ->
          {:noperm, "🚫 this command can only be used on guilds"}

        {:member, {:error, :not_found}} ->
          {:error, "❌ you're not in the guild member cache, can't check perms"}
      end
    end
  end

  # vim: textwidth=80 sw=2 ts=2:
end
