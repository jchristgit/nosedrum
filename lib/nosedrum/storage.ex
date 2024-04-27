defmodule Nosedrum.Storage do
  @moduledoc """
  `Storage`s keep track of your Application Command names and their associated modules.

  A `Storage` handles incoming `t:Nostrum.Struct.Interaction.t/0`s, invoking
  `c:Nosedrum.ApplicationCommand.command/1` callbacks and responding to the Interaction.

  In addition to tracking commands locally for the bot, a `Storage` is
  responsible for registering an Application Command with Discord when `c:add_command/4`
  or `c:remove_command/4` is called.
  """
  @moduledoc since: "0.4.0"
  alias Nostrum.Struct.{Guild, Interaction}

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

  @type command_scope :: :global | Guild.id() | [Guild.id()]

  @typedoc """
  Defines a structure of commands, subcommands, subcommand groups.

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

  ## References
  - Official Documentation:
  https://discord.com/developers/docs/interactions/application-commands#subcommands-and-subcommand-groups
  """
  @type application_command_path ::
          %{
            {group_name :: String.t(), group_desc :: String.t()} => [
              application_command_path | [Nosedrum.ApplicationCommand.option()]
            ]
          }

  @typedoc """
  The name or pid of the Storage process.
  """
  @type name_or_pid :: atom() | pid()

  @doc """
  Handle an Application Command invocation.

  This callback should be invoked upon receiving an interaction via the `:INTERACTION_CREATE` event.

  ## Example using `Nosedrum.Storage.Dispatcher`:
  ```elixir
  # In your `Nostrum.Consumer` file:
  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    IO.puts "Got interaction"
    Nosedrum.Storage.Dispatcher.handle_interaction(interaction)
  end
  ```

  ## Return value

  Returns `{:ok}` on success, or `{:ok, t:Nostrum.Struct.Message.t()}` when deferring and the supplied callback
  completes with a successful edit of the original response. `{:error, reason}` is returned otherwise.
  """
  @callback handle_interaction(interaction :: Interaction.t(), name_or_pid) ::
              {:ok}
              | {:ok, Nostrum.Struct.Message.t()}
              | {:error, :unknown_command}
              | Nostrum.Api.error()

  @doc """
  Queues a new command to be registered under the given name or application command path. Queued commands are
  added to the internal dispatch storage, and will be registered in bulk upon calling process_queue/1

  If any command already exists, it will be overwritten.

  ## Return value
  Returns `:ok` if successful, and `{:error, reason}` otherwise.
  """
  @callback queue_command(
              name_or_path :: String.t() | application_command_path,
              command_module :: module,
              name_or_pid
            ) :: :ok | {:error, Nostrum.Error.ApiError.t()}

  @doc """
  Add a new command under the given name or application command path.

  If the command already exists, it will be overwritten.

  When adding many commands, it is recommended to use queue_command, and to call process_queue once all
  commands are queued for registration.

  ## Return value
  Returns `:ok` if successful, and `{:error, reason}` otherwise.
  """
  @callback add_command(
              name_or_path :: String.t() | application_command_path,
              command_module :: module,
              scope :: command_scope,
              name_or_pid
            ) :: :ok | {:error, Nostrum.Error.ApiError.t()}

  @doc """
  Remove the command under the given name or application command path.

  ## Return value

  Returns `:ok` if successful, and `{:error, reason}` otherwise.

  If the command does not exist, no error should be returned.
  """
  @callback remove_command(
              name_or_path :: String.t() | application_command_path,
              command_id :: Nostrum.Snowflake.t(),
              scope :: command_scope,
              name_or_pid
            ) :: :ok | {:error, Nostrum.Error.ApiError.t()}

  @doc """
  Register all currently queued commands to discord, making them available for use

  Global commands can take up to 1 hour to be made available. Guild commands are available immediately.

  ## Return value
  Returns `:ok` if successful, and `{:error, reason}` otherwise.
  """
  @callback process_queue(
              scope :: command_scope,
              name_or_pid
            ) :: :ok | {:error, Nostrum.Error.ApiError.t()}

  @doc """
  Responds to an Interaction with the given `t:Nosedrum.ApplicationCommand.response/0`.

  ## Return value

  Returns `{:ok}` if successful, and a `t:Nostrum.Api.error/0` otherwise.
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

  @doc """
  Edits an interaction with a follow up response.

  The response is obtained by running the given function/MFA tuple, see
  `t:Nosedrum.ApplicationCommand.callback/0`.

  ## Return value

  Returns `{:ok, `t:Nostrum.Struct.Message.t()`}` if successful, and a `t:Nostrum.Api.error/0` otherwise.
  """
  @spec followup(Interaction.t(), Nosedrum.ApplicationCommand.callback()) ::
          {:ok, Nostrum.Struct.Message.t()} | Nostrum.Api.error()
  def followup(interaction, callback_tuple) do
    followup_response =
      case callback_tuple do
        {callback, args} -> apply(callback, args)
        {module, callback, args} -> apply(module, callback, args)
      end

    data =
      followup_response
      |> Keyword.take([:content, :embeds, :components, :allowed_mentions])
      |> Map.new()

    Nostrum.Api.edit_interaction_response(interaction, data)
  end

  defp convert_callback_type({type, _fn}) do
    convert_callback_type(type)
  end

  defp convert_callback_type(type) do
    Map.get(@callback_type_map, type)
  end

  defp put_flags(data_map, command_response) do
    Enum.reduce(@flag_map, data_map, fn {flag, value}, data_map_acc ->
      if command_response[flag] do
        Map.put(data_map_acc, :flags, value)
      else
        data_map_acc
      end
    end)
  end
end
