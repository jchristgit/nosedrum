defmodule Nosedrum.ApplicationCommand do
  @moduledoc """
  The application command behaviour specifies the interface that a slash, user,
  or message command module should implement.

  Like regular commands, application command modules are stateless on their own. Implementations of the callbacks
  defined by this behaviour are invoked from other modules/functions, notably a `Nosedrum.Storage`.

  The types defined in this module reflect the official
  [Application Command docs](https://discord.com/developers/docs/interactions/application-commands).

  ## Example Slash Command
  This command echos the passed message back to the user.
  ```elixir
  # In your application command module file, e.g. ./lib/my_app/commands/echo.ex
  defmodule MyApp.Commands.Echo do
    @behaviour Nosedrum.ApplicationCommand

    @impl true
    def description() do
      "Echos a message."
    end

    @impl true
    def command(interaction) do
      [%{name: "message", value: message}] = interaction.data.options
      [
        content: message,
        ephemeral?: true
      ]
    end

    @impl true
    def type() do
      :slash
    end

    @impl true
    def options() do
      [
        %{
          type: :string,
          name: "message",
          description: "The message for the bot to echo.",
          required: true
        }
      ]
    end
  end
  ```

  ```elixir
  # In your Nostrum.Consumer file, e.g. ./lib/my_app/consumer.ex
  defmodule MyApp.Consumer do
    use Nostrum.Consumer

    # ...

    # You may use `:global` instead of a guild id at GUILD_ID_HERE, but note
    # that global commands could take up to an hour to become available.
    def handle_event({:READY, _data, _ws_state}) do
      case Nosedrum.Storage.Dispatcher.add_command("echo", MyApp.Commands.Echo, GUILD_ID_HERE) do
        {:ok, _} -> IO.puts("Registered Echo command.")
        e -> IO.inspect(e, label: "An error occurred registering the Echo command")
      end
    end

    def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
      Nosedrum.Storage.Dispatcher.handle_interaction(interaction)
    end
  end
  ```

  You will also need to start the `Nosedrum.Storage.Dispatcher` as part of
  your supervision tree, for example, by adding this to your application start
  function:

  ```elixir
  # ./lib/my_app/application.ex
  defmodule MyApp.Application do
    # ...
    def start(type, args) do
      children = [
        # ...
        {Nosedrum.Storage.Dispatcher, name: Nosedrum.Storage.Dispatcher},
      ]

      options = [strategy: :rest_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, options)
    end
  end
  ```
  """
  @moduledoc since: "0.4.0"

  alias Nostrum.Struct.{Embed, Interaction}

  @typedoc """
  Called by `Nosedrum.Storage.followup/2` after deferring an interaction response.

  The callback should return a response similar to `c:command/1`, excluding the `:type`, `:tts?`, and `:ephemeral?`
  options.
  """
  @type callback ::
          {(... -> response()), args :: list()} | {module(), fn_name :: atom(), args :: list()}
  @typedoc """
  A value of the `:type` field in a `c:command/1` return value. See
  `t:response/0` for more details.
  """
  @type response_type ::
          :channel_message_with_source
          | :deferred_channel_message_with_source
          | :deferred_update_message
          | {:deferred_channel_message_with_source, callback()}
          | {:deferred_update_message, callback()}
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
  A keyword list of fields to include in the interaction response, after running the `c:command/1` callback.

  If `:type` is not specified, it will default to `:channel_message_with_source`, though one of
  either `:embeds` or `:content` must be present.

  If you are deferring an interaction response with `:deferred_channel_message_with_source` or
  `:deferred_update_message`, you should also supply a callback under `:type` in the form of
  `{:deferred_*, callback_tuple}` (See the Deferred Response Example below for more details on `callback_tuple`).

  ## Example

  ```elixir
  def command(interaction) do
    # Since `:content` is included, Nosedrum will infer `type: :channel_message_with_source`
    [
      content: "Hello, world!",
      ephemeral?: true,
      allowed_mentions: ["users", "roles"]
    ]
  end
  ```

  ## Deferred Response Example

  In order to avoid a potential race condition when deferring, you should supply a callback function for Nosedrum
  to call only after the initial response succeeds. The callback should take the form of `{anonymous_fn, args}`, or an
  MFA (Module, Function, Args) tuple, like `{MyCommand, :followup_fn, [interaction, extra_arg]}`

  ```elixir
  @impl Nosedrum.ApplicationCommand
  def command(interaction) do
    [
      type: {:deferred_channel_message_with_source, {&expensive_calculation/1, [interaction]}}
    ]
  end

  defp expensive_calculation(interaction) do
    # ... do expensive things
    [
      content: "Hello, I've been edited in after the original interaction response"
    ]
  end
  ```
  """
  @type response :: [response_field]

  @typedoc """
  An option (argument) for an application command.

  See callback `c:options/0` documentation for examples.
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

  See callback `c:options/0` documentation for examples.
  """
  @type choice :: %{
          name: String.t(),
          value: String.t() | number()
        }

  @doc """
  Returns one of `:slash`, `:message`, or `:user`, indicating what kind of application command this module represents.
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

  ## Example options callback for a "/role" command
  ```elixir
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
  Execute the command invoked by the given `t:Nostrum.Struct.Interaction.t/0`. Returns a `t:response/0`

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
  @callback command(interaction :: Interaction.t()) :: response

  @optional_callbacks [options: 0]
end
