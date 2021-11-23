defmodule Nosedrum.Interactor do
  @moduledoc """
  Interactors take the role of both `Nosedrum.Invoker` and `Nosedrum.Storage` when
  it comes to Discord's Application Commands. An Interactor handles incoming
  `t:Interaction.t/0`s, invoking `Nosedrum.ApplicationCommand.command/1` callbacks
  and responding to the Interaction.

  In addition to tracking commands locally for the bot, an Interactor is
  responsible for registering an Application Command with Discord when `add_command/3`
  or `remove_command/2` is called.
  """

  alias Nostrum.Snowflake
  alias Nostrum.Struct.Interaction

  @callback_type_map %{
    pong: 1,
    channel_message_with_source: 4,
    deferred_channel_message_with_source: 5,
    deferred_update_message: 6,
    update_message: 7
  }

  @flag_map %{
    ephemeral?: 64
  }

  @type command_scope :: :global | Snowflake.t() | [Snowflake.t()]

  @typedoc """
  Defines a structure of commands, subcommands, subcommand groups, as
  outlined in the [official documentation](https://discord.com/developers/docs/interactions/application-commands#subcommands-and-subcommand-groups)

  **Note** that Discord only supports nesting 3 levels deep, like `command -> subcommand group -> subcommand`.

  ## Example path:
  ```elixir
  %{
    {"castle", MyApp.CastleCommand.description()} =>
      %{
        {"prepare", "Prepare the castle for an attack."} => [],
        {"open", "Open up the castle for traders and visitors."} => [],
        # ...
      }
  }
  ```
  """
  @type application_command_path ::
          %{
            {group_name :: String.t(), group_desc :: String.t()} => [
              application_command_path | [Nosedrum.ApplicationCommand.option()]
            ]
          }

  @typedoc """
  The name or pid of the Interactor process.
  """
  @type name_or_pid :: atom() | pid()

  @doc """
  Handle an Application Command invocation.

  This callback should be invoked upon receiving an interaction via the `:INTERACTION_CREATE` event.

  ## Example using `Nosedrum.Interactor.Dispatcher`:
  ```elixir
  # In your `Nostrum.Consumer` file:
  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    IO.puts "Got interaction"
    Nosedrum.Interactor.Dispatcher.handle_interaction(interaction)
  end
  ```
  """
  @callback handle_interaction(interaction :: Interaction.t(), name_or_pid) :: :ok

  @doc """
  Add a new command under the given name or application command path. Returns `:ok` if successful, and
  `{:error, reason}` otherwise.

  If the command already exists, it will be overwritten.
  """
  @callback add_command(
              name_or_path :: String.t() | application_command_path,
              command_module :: module,
              scope :: command_scope,
              name_or_pid
            ) ::
              :ok | {:error, reason :: String.t()}

  @doc """
  Remove the command under the given name or application command path. Returns `:ok` if successful, and
  `{:error, reason}` otherwise.

  If the command does not exist, no error should be returned.
  """
  @callback remove_command(
              name_or_path :: String.t() | application_command_path,
              command_id :: Nostrum.Snowflake.t(),
              scope :: command_scope,
              name_or_pid
            ) ::
              :ok | {:error, reason :: String.t()}

  @doc """
  Responds to an Interaction with the values in the given `t:Nosedrum.ApplicationCommand.response()`. Returns `{:ok}` if
  successful, and a `Nostrum.Api.error()` otherwise.
  """
  @spec respond(Interaction.t(), Nosedrum.ApplicationCommand.response()) ::
          {:ok} | Nostrum.Api.error()
  def respond(interaction, command_response) do
    type =
      command_response
      |> Keyword.get(:type, :channel_message_with_source)
      |> convert_callback_type()

    data =
      command_response
      |> Keyword.take([:content, :embeds, :components, :tts?, :allowed_mentions])
      |> Map.new()
      |> put_flags(command_response)

    res = %{
      type: type,
      data: data
    }

    Nostrum.Api.create_interaction_response(interaction, res)
  end

  defp convert_callback_type(type) do
    Map.get(@callback_type_map, type)
  end

  defp put_flags(data_map, command_response) do
    Enum.reduce(@flag_map, data_map, fn {flag, value} ->
      if command_response[flag] do
        Map.put(data_map, :flags, value)
      else
        data_map
      end
    end)
  end
end
