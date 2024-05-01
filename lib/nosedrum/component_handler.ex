defmodule Nosedrum.ComponentHandler do
  @moduledoc """
  Handles incommming interactions triggered by interacting with a component.

  ## Register components
  The component handler allows you to register a set of component ids to be
  handled by a module that implements the `Nosedrum.ComponentInteraction`-
  behaviour or any pid with the `register_components/2`-callback. 

  When a pid is given to the `register_components/2`-callback, it will receive 
  a message of the form `{:message_component_interaction, t:Nostrum.Struct.Interaction.t()}`.

  ## Handle incomming interactions
  Use the `handle_message_component_interaction/1` callback to handle 
  incomming interactions and route them to the correct module or pid. The 
  recommended place to handle these interactions would be when handling
  the `:INTERACTION_CREATE` event in the consumer. The following example
  uses the `Nosedrum.ComponentHandler.ETS` implementation:

  ```elixir
  def handle_event({:INTERACTION_CREATE, interaction, _}) do
    case interaction.type do
      1 -> Nostrum.Api.create_interaction_response(interaction, %{type: 1})
      2 -> Nosedrum.Storage.Dispatcher.handle_interaction(interaction)
      x when x in 3..5 -> Nosedrum.ComponentHandler.ETS.handle_component_interaction(interaction)
    end
  end
  ```
  """

  @type component_id :: String.t()
  @type component_handler :: module() | pid()

  @callback register_components(component_id | [component_id], component_handler) :: :ok
  @callback handle_component_interaction(Nostrum.Struct.Interaction.t()) ::
              :ok | {:error, Nostrum.Error.ApiError.t() | :not_found}
end
