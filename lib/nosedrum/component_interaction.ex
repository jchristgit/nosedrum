defmodule Nosedrum.ComponentInteraction do
  @moduledoc """
  Behaviour for processing an interaction triggered from a message component.

  Modules implementing this behaviour can be registered to a command handler
  via `c:Nosedrum.ComponentHandler.register_components/3`. See the module
  documentation for `Nosedrum.ComponentHandler` for more information.
  """

  @doc """
  Handle message component interactions.

  Behaves the same way as the `Nosedrum.ApplicationCommand.commmand/1` callback.
  """
  @callback message_component_interaction(
              interaction :: Nostrum.Struct.Interaction.t(),
              Nosedrum.ComponentHandler.additional_data()
            ) ::
              Nosedrum.ApplicationCommand.response()
end
