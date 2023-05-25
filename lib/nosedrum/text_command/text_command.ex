defmodule Nosedrum.TextCommand do
  @moduledoc """
  The command behaviour specifies the interface that a command module should implement.

  Command modules are stateless by themselves, if you want to capture state, drop it in
  a different delegated module.

  Commands by themselves do not implement any logic for determining whether they were
  invoked. This is done by a command processor module, which also maps command strings
  to the command modules to be invoked.

  ## Example

      defmodule MyBot.Cogs.Echo do
        @behaviour Nosedrum.Command
        @moduledoc false

        @impl true
        def usage, do: ["echo <text...>"]

        @impl true
        def description, do: "display a line of text"

        @impl true
        def parse_args(args), do: Enum.join(args, " ")

        @impl true
        def predicates, do: []

        @impl true
        def command(msg, "") do
          response = "Need something to echo"
          {:ok, _msg} = Nostrum.Api.create_message(msg.channel_id, response)
        end

        def command(msg, text) do
          {:ok, _msg} = Nostrum.Api.create_message(msg.channel_id, text)
        end
      end
  """

  alias Nostrum.Struct.Message

  @doc """
  Return a list of possible ways to use the command (or its subcommands).

  This is separate from the `c:description/0` callback since the command
  processor is expected to prepend usage strings with its configured prefix.

  ## Example

      @impl true
      def usage do
        [
          "clean <amount:int>",
          "clean <options...>"
        ]
      end
  """
  @callback usage() :: [String.t()]

  @doc """
  Return a description of the command and how to use it.

  ## Example

      @impl true
      def description,
        do: "Cleanup messages."
  """
  @callback description() :: String.t()

  @doc """
  Return a list of predicates that must pass before this command is invoked.

  This is expected to be invoked by the command processor. Predicates retrieve
  the message which should be checked for allowance to invoke the command.

  Predicates are evaluated lazily: For instance, you can have a command which
  uses a predicate ensuring the command can only be invoked on guilds (for
  example, by checking whether `msg.guild_id == nil`), and predicates
  afterwards do not need to check whether the command was invoked on a guild.

  ## Return value

  If the predicate allows the invoking user to issue the command, it should
  return `:passthrough`. If the user has no permission to execute the command,
  a pair in the form `{:noperm, reason}` should be returned, where `reason` is
  a concise description of why the user is not allowed to execute the command.
  `{:error, reason}` should be returned when the predicate was not able to
  determine allowance of the invoking user.

  ## Example

      def is_bot(message) do
        if message.author.bot do
          :passthrough
        else
          {:noperm, "sorry, only bots allowed"}
        end
      end

      @impl true
      def predicates, do: [&is_bot/1]
  """
  @callback predicates() :: [
              (Message.t() -> :passthrough | {:noperm, String.t()} | {:error, String.t()})
            ]

  @doc """
  An optional callback that can be used to parse the arguments into something more usable.

  For example, one might want to use `OptionParser` along with the
  arguments to create a more customized command.
  This command receives the command arguments (without any prefix, command,
  or if applicable, subcommand), and should return whatever the
  `c:command/2` function should be passed as the `args` argument.
  """
  @callback parse_args(args :: [String.t()]) :: any()

  @doc """
  Execute the command invoked by the given `t:Nostrum.Struct.Message.t/0`.

  The second parameter is a list of arguments with the command
  (or subcommand) along with the bot prefix removed.
  If the command defines `c:parse_args/1`, the returned value of
  that function will be passed instead (marked as `any()` here).
  The return value of this function is unused.
  """
  @callback command(msg :: Message.t(), args :: [String.t()] | any()) :: any()

  @doc """
  An optional callback that returns a list of aliases for the command.

  `Nosedrum.TextCommand.Storage` implementations use this function when adding/removing a command
  with `add_command/2` or `remove_command/2`. If any of the aliases returned conflict
  with existing commands/aliases, they will be overwritten.
  """
  @doc since: "0.4.0"
  @callback aliases() :: [String.t()]

  @optional_callbacks [parse_args: 1, aliases: 0]
end
