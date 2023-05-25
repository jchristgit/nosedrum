defmodule Nosedrum.TextCommand.Invoker do
  @moduledoc """
  Invoker modules process messages from Discord.

  They determine the following things:
  - whether the message is a valid command
  - whether the author is permitted to issue the command.
  When both of these conditions are met, the command callback function is invoked.
  """

  @doc """
  Called by consumers when a message arrives.

  This is the main entry point for invokers: from here on they
  check whether the message could contain a valid command based
  on their configured prefix and ask the selected `Nosedrum.TextCommand.Storage`
  whether a command exists. If it exists, they proceed to invoke it
  using only the arguments to the message, with bot prefix and command
  invocation removed from the message.

  The second argument, `storage`, determines which storage implementation the
  command invoker should use. A command invoker implementation can supply
  this argument by default if applicable.

  `storage_process` is passed along to the given `storage` and determines
  which storage process, ETS table, or similar is used.
  """
  @callback handle_message(
              message :: Nostrum.Struct.Message.t(),
              storage :: Nostrum.Storage,
              reference :: any()
            ) ::
              any()
end
