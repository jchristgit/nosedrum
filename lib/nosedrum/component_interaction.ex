defmodule Nosedrum.ComponentInteraction do
  @doc """
  Handle message component interactions. Behaves the same way as `Nosedrum.ApplicationCommand.commmand/1`-callback
  """
  @callback message_component_interaction(Nostrum.Struct.Interaction.t()) ::
              Nosedrum.ApplicationCommand.response()
end
