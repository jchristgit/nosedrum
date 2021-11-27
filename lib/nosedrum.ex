defmodule Nosedrum do
  @moduledoc """
  `nosedrum` is a command framework for use with the excellent
  [`nostrum`](https://github.com/Kraigie/nostrum) library.

  It contains behaviour specifications for easily implementing command handling
  for both Discord's application commands and the traditional text-based
  commands in your bot along with other conveniences to ease creating an
  interactive bot.

  `nosedrum`s provided implementations are largely based off what was originally
  written for [bolt](https://github.com/jchristgit/bolt). bolt also contains
  around [57
  commands](https://github.com/jchristgit/bolt/tree/master/lib/bolt/cogs) based
  off the `Nosedrum.Command` behaviour that you can explore if you're looking
  for inspiration.

  The application command related parts of the framework consist of two parts:
  - `Nosedrum.ApplicationCommand`, the behaviour that all application commands
    must implement.
  - `Nosedrum.Invoker`, the behaviour for any slash command invoker. A default
    implementation provided by nosedrum resides at `Nosedrum.Invoker.Dispatcher`.

  The traditional command processing related parts of the framework consists of
  three parts:
  - `Nosedrum.Command`, the behaviour that all commands must implement.
  - `Nosedrum.Invoker`, the behaviour of command processors. Command processors
    take a message, look it up in the provided storage implementation,
    and invoke commands as required. nosedrum ships with an implementation of
    this based on bolt's original command parser named `Nosedrum.Invoker.Split`.
  - `Nosedrum.Storage`, the behaviour of command storages. Command storages
    allow for fast and simple lookups of commands and command groups and store
    command names along with their corresponding `Nosedrum.Command`
    implementations internally. An ETS-based command storage implementation is
    provided with `Nosedrum.Storage.ETS`.

  Additionally, the following utilities are provided:
  - `Nosedrum.Converters`, functions for converting parts of messages to objects
    from Nostrum such as channels, members, and roles.
  - `Nosedrum.MessageCache`, a behaviour for defining message caches, along with
    an ETS-based and an Agent-based implementation.

  Simply add `:nosedrum` to your `mix.exs`:

      def deps do
        [
          {:nosedrum, "~> #{String.replace_trailing(Mix.Project.config()[:version], ".0", "")}"},
          # To use the GitHub version of Nostrum:
          # {:nostrum, github: "Kraigie/nostrum", override: true}
        ]
      end

  # Getting started

  For getting started with application commands, see the
  `Nosedrum.ApplicationCommand` module.

  To write a traditional command, your commands need to implement the
  `Nosedrum.Command` behaviour.  As a simple example, let's reimplement
  [`ed`](https://www.gnu.org/fun/jokes/ed-msg.html).

      defmodule MyBot.Cogs.Ed do
        @behaviour Nosedrum.Command

        alias Nostrum.Api

        @impl true
        def usage, do: ["ed [-GVhs] [-p string] [file]"]

        @impl true
        def description, do: "Ed is the standard text editor."

        @impl true
        def predicates, do: []

        @impl true
        def command(msg, _args) do
          {:ok, _msg} = Api.create_message(msg.channel_id, "?")
        end
      end

  With your commands defined, choose a `Nosedrum.Storage` implementation and add
  it to your application callback. We will use the included
  `Nosedrum.Storage.ETS` implementation here, but feel free to write your own:

      defmodule MyBot.Application do
        use Application

        def start(_type, _args) do
          children = [
            Nosedrum.Storage.ETS,
            MyBot.Consumer
          ]
          options = [strategy: :one_for_one, name: MyBot.Supervisor]
          Supervisor.start_link(children, options)
        end
      end

  Finally, we hook things up in our consumer: we will load commands once the bot
  is ready, and invoke the command invoker on each message.

      defmodule MyBot.Consumer do
        alias Nosedrum.Invoker.Split, as: CommandInvoker
        alias Nosedrum.Storage.ETS, as: CommandStorage
        use Nostrum.Consumer

        @commands %{
          "ed" => MyBot.Cogs.Ed
        }

        def handle_event({:READY, _data, _ws_state}) do
          Enum.each(@commands, fn {name, cog} -> CommandStorage.add_command([name], cog) end)
        end

        def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
          CommandInvoker.handle_message(msg, CommandStorage)
        end

        def handle_event(_data), do: :ok
      end

  That's all we need to get started with. If you want to customize your bot's
  prefix, set the `nosedrum.prefix` configuration variable:

      config :nosedrum,
        prefix: System.get_env("BOT_PREFIX") || "."

  If no value is configured, the default prefix used depends on the chosen
  command invoker implementation. `Nosedrum.Invoker.Split` defaults to `.`.
  """

  # vim: textwidth=80 sw=2 ts=2:
end
