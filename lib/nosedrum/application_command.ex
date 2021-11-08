defmodule Nosedrum.ApplicationCommand do
  @moduledoc """
  The application command behaviour specifies the interface that a slash, user,
  or message command module should implement.

  Like regular commands, application command modules are stateless on their own. Implementations of the callbacks
  defined by this behaviour are invoked from other modules/functions, notably a `Nosedrum.Interactor`.

  The types defined in this module reflect the official
  [Application Command docs](https://discord.com/developers/docs/interactions/application-commands).
  """

  @type response_type ::
          :channel_message_with_source
          | :deferred_channel_message_with_source
          | :deferred_update_message
          | :pong
          | :update_message

  @typedoc """
  A field in a keyword list interaction response.

  Special notes:
  - `:type` is required, unless `:content` or `:embeds` is present, in which case it defaults to
  `:channel_message_with_source`.
  - `:allowed_mentions` is a list that should contain "users", "roles", and/or "everyone", or be empty.
  """
  @type response_field ::
          {:type, response_type}
          | {:content, String.t()}
          | {:embeds, [Embed.t()]}
          | {:components, [map()]}
          | {:ephemeral?, boolean()}
          | {:tts?, boolean()}
          | {:allowed_mentions, [String.t()] | []}

  @typedoc """
  A keyword list of fields to include in the interaction response, after running the `command/1` callback.

  If `:type` is not specified, it will default to `:channel_message_with_source`, though one of
  either `:embeds` or `:content` must be present.

  ## Example
  ```elixir
  def command(interaction) do

    # Since `:content` is included, Nosedrum will infer `type: :channel_message_with_source`
    response = [
      content: "Hello, world!",
      ephemeral?: true,
      allowed_mentions: ["users", "roles"]
    ]

    {:response, response}
  end
  ```
  """
  @type response :: [response_field]

  @typedoc """
  An option (argument) for an application command.

  See callback `options/0` documentation for examples.
  """
  @type option :: %{
          optional(:required) => true | false,
          optional(:choices) => [choice],
          optional(:options) => [option],
          type:
            :sub_command
            | :sub_command_group
            | :string
            | :integer
            | :boolean
            | :user
            | :channel
            | :role
            | :mentionable
            | :number,
          name: String.t(),
          description: String.t()
        }

  @typedoc """
  A choice for an option.

  See callback `options/0` documentation for examples.
  """
  @type choice :: %{
          name: String.t(),
          value: String.t() | number()
        }

  @doc """
  Returns an atom indicating what kind of application command this module represents.
  """
  @callback type() :: :slash | :message | :user

  @doc """
  Returns a description of the command. Used when registering the command with Discord. This is what the user will see
  in the autofill command-selection menu.

  ## Example
  ```elixir
  def description, do: "This is a command description."
  ```
  """
  @callback description() :: String.t()

  @doc """
  An optional callback that returns a list of options (arguments) that the
  command takes. Used when registering the command with Discord. Only valid for
  CHAT_INPUT application commands, aka slash commands.

  Read more in the official
  [Application Command documentation](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure).

  ## Example
  ```elixir
  # For example, the options for a /role command might look like...
  def options, do:
    [
      %{
        type: :user,
        name: "user",
        description: "The user to assign the role to.",
        required: true # Defaults to false if not specified.
      },
      %{
        type: :role,
        name: "role",
        description: "The role to be assigned.",
        required: true,
        choices: [
          %{
            name: "Event Notifications",
            value: 123456789123456789 # A role ID, passed to your `command/1` callback via the Interaction struct.
          },
          %{
            name: "Announcements",
            value: 123456789123456790
          }
        ]
      }
    ]
  ```
  """
  @callback options() :: [option]

  @doc """
  Execute the command invoked by the given `t:Nostrum.Struct.Interaction.t/0`. Returns a `c:response()`

  ## Example
  ```elixir
  defmodule MyApp.MyCommand do
    @behaviour Nosedrum.ApplicationCommand

    # ...

    @impl true
    def command(interaction) do
      %{name: opt_name} = List.first(interaction.data.options)
      [content: "Hello World \#{opt_name}!"]
    end
  end
  ```
  """
  @callback command(Interaction.t()) :: response

  @optional_callbacks [options: 0]
end