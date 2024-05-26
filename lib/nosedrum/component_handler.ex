defmodule Nosedrum.ComponentHandler do
  @moduledoc """
  Handles incoming interactions triggered by interacting with a component.

  ## Register components
  Before the component handler can handle incoming interactions, you must
  register some [custom ids](https://discord.com/developers/docs/interactions/message-components#custom-id)
  with the `c:Nosedrum.ComponentHandler.register_components/3` callback. The arguments for the callback
  are one or more custom ids, a module or a pid that will handle the interaction
  and additional data, that will be passed on to the module or pid that handles
  the interaction. The additional data can be any arbitrary term.

  ### Module handlers
  The registered module should implement the `Nosedrum.ComponentInteraction`
  behaviour. The component handler will call the `c:Nosedrum.ComponentInteraction.message_component_interaction/2`
  callback of the module when a matching interaction is found.

  ### Process handlers
  Once a pid is registered, it will receive a message of the type `t:message_component_interaction/0`
  every time a matching interaction is found.

  ## Handle incomming interactions
  The `c:Nosedrum.ComponentHandler.handle_component_interaction/1` callback will look up the correct module or
  pid and relay the interaction and additional data. The recommended place to
  handle these interactions would be when handling the `:INTERACTION_CREATE`
  event in the consumer. The following example uses the
  `Nosedrum.ComponentHandler.ETS` implementation:

  ```elixir
  # The ready event would be a possible place where you could register static
  # component handlers.
  def handle_event({:READY, _, _}) do
    Nosedrum.ComponentHandler.ETS.register_component(["next_button", "previous_button"],
      MyApp.ButtonHandler, nil)
  end

  # Handle the interaction create in your consumer module.
  def handle_event({:INTERACTION_CREATE, interaction, _}) do
    case interaction.type do
      1 -> Nostrum.Api.create_interaction_response(interaction, %{type: 1})
      2 -> Nosedrum.Storage.Dispatcher.handle_interaction(interaction)
      x when x in 3..5 -> Nosedrum.ComponentHandler.ETS.handle_component_interaction(interaction)
    end
  end
  ```

  ```elixir
  # Start the Component handler in your Application. Ideally before your Consumer.
  defmodule MyApp.Application do
    # ...
    def start(type, args) do
      children = [
        # ...
        Nosedrum.ComponentHandler.ETS
      ]

      options = [strategy: :rest_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, options)
    end
  end
  ```

  ```elixir
  # A simple module for handling component interactions
  defmodule MyApp.ButtonHandler do
    @behaviour Nosedrum.ComponentInteraction

    def message_component_interaction(interaction, _) do
      case interaction.data.custom_id do
        "next_button" -> [content: "The next button was clicked"]
        "prev_button" -> [content: "The previous button was clicked"]
      end
    end
  end
  ```
  """

  @type custom_ids ::
          Nostrum.Struct.Component.custom_id() | [Nostrum.Struct.Component.custom_id()]
  @type component_handler :: module() | pid()
  @type additional_data :: term()
  @type message_component_interaction ::
          {:message_component_interaction, Nostrum.Struct.Interaction.t(), additional_data()}

  @callback register_components(custom_ids, component_handler, additional_data()) :: :ok
  @callback handle_component_interaction(Nostrum.Struct.Interaction.t()) ::
              :ok | {:error, Nostrum.Error.ApiError.t() | :not_found}
end
