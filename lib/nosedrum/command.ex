defmodule Nosedrum.Command do
  @moduledoc """
  The command behaviour specifies the interface that a command module should implement.
  Command modules are stateless by themselves, if you want to capture state, drop it in
  a different delegated module.

  Commands by themselves do not implement any logic for determining whether they were
  invoked. This is done by a command processor module, which also maps command strings
  to the command modules to be invoked.

  ## Example

      defmodule Bot.Commands.Ed do
        @behaviour Nosedrum.Command
        @moduledoc false

        @impl true
        def usage, do: ["ed [-GVhs] [-p string] [file]"]

        @impl true
        def description, do: "Ed is the standard text editor."

        @impl true
        def predicates, do: []

        @impl true
        def command(msg, _args) do
          {:ok, _msg} = Nostrum.Api.create_message(msg.channel_id, "?")
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
  """
  # TODO: Define predicate behaviour.
  # TODO: Change {:ok, Message.t()} to :passthrough
  @callback predicates() :: [(Message.t() -> {:ok, Message.t()} | {:error, String.t()})]

  @doc """
  An optional callback that can be used to parse the arguments into something
  more usable. For example, one might want to use `OptionParser` along with the
  arguments to create a more customized command.
  This command receives the command arguments with the prefix, command, and
  (if applicable) subcommand name removed, and should return whatever the
  `c:command/2` function should be passed as the `args` argument.
  """
  @callback parse_args(args :: [String.t()]) :: any()

  @doc """
  Execute the command invoked by the given `Message.t()`.
  The second parameter is a list of arguments with the command
  (or subcommand) along with the bot prefix removed.
  If the command defines `parse_args/1`, the returned value of
  that function will be passed instead (marked as `any()` here).
  The return value of this function is unused.
  """
  @callback command(msg :: Message.t(), args :: [String.t()] | any()) :: any()

  @optional_callbacks [parse_args: 1]
end
