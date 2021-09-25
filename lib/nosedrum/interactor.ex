defmodule Nosedrum.Interactor do
  @moduledoc """
  Interactors take the role of both `Nosedrum.Invoker` and `Nosedrum.Storage` when
  it comes to Discord's Application Commands. An Interactor handles incoming
  `t:Interaction.t/0`s, invoking `Nosedrum.ApplicationCommand.command/1` callbacks
  and responding to the Interaction.

  In addition to updating commands in its local state, an Interactor is
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
    update_message: 7,
  }

  @type command_scope :: :global | {:guild, Snowflake.t() | [Snowflake.t()]}

  @typedoc """
  Defines either the name of an Application Command, or a structure of commands, subcommands, subcommand groups, as
  outlined in the [official documentation](https://discord.com/developers/docs/interactions/application-commands#subcommands-and-subcommand-groups)

  **Note** that Discord only supports nesting 3 levels deep, like `command -> subcommand group -> subcommand`.
  """
  @type application_command_path ::
    %{name :: String.t() => app_cmd_module :: module}
    | %{
      {group_name :: String.t(), group_desc :: String.t()} => application_command_path
    }

  @doc """
  Handle an Application Command invocation.

  This callback is responsible
  """
  @callback handle_interaction(interaction :: Interaction.t()) :: :ok

  @doc """
  Add a new command under the given `path`.

  If the command already exists, it will be overwritten.
  """
  @callback add_command(path :: application_command_path, scope :: command_scope) ::
              :ok | {:error, String.t()}

  @doc """
  Remove the command under the given `path`.

  If the command does not exist, no error should be returned.
  """
  @callback remove_command(path :: application_command_path, scope :: command_scope) ::
              :ok | {:error, String.t()}

  @doc """
  Responds to a given Interaction with `Nosedrum.ApplicationCommand.response` value.
  """
  @spec respond(Interaction.t(), Nosedrum.ApplicationCommand.response) :: {:ok} | Nostrum.Api.error
  def respond(interaction, command_response) do
    type =
      command_response
      |> Keyword.get(:type, :channel_message_with_source)
      |> then(&Map.get(@callback_type_map, &1))

    data =
      command_response
      |> Keyword.take([:content, :embeds, :components, :tts?, :allowed_mentions])
      |> Map.new()
      |> then(&(if command_response[:ephemeral?], do: Map.put(&1, :flags, 64), else: &1))

    res = %{
      type: type,
      data: data
    }

    Nostrum.Api.create_interaction_response(interaction, res)
  end
end
