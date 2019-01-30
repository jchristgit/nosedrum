defmodule Nosedrum.Invoker do
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
  on their configured prefix and ask the selected `Nosedrum.Storage`
  whether a command exists. If it exists, they proceed to invoke it
  using only the arguments to the message, with bot prefix and command
  invocation removed from the message.
  """
  @callback handle_message(message :: Nostrum.Struct.Message.t()) :: any()
end
