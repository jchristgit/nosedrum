# nosedrum

`nosedrum` is a command framework for use with the excellent
[`nostrum`](https://github.com/Kraigie/nostrum) library.

It contains behaviour specifications for easily implementing command handling in
your bot along with other conveniences to ease creating an interactive bot.

The command processing related parts of the framework consists of three parts:
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

`nosedrum`s provided implementations are largely based off what was originally
written for [bolt](https://github.com/jchristgit/bolt). bolt also contains
around [59
commands](https://github.com/jchristgit/bolt/tree/master/lib/bolt/cogs) based
off the `Nosedrum.Command` behaviour that you can explore if you're looking for
inspiration.

The documentation can be found at https://hexdocs.pm/nosedrum.

## Installation
Simply add `:nosedrum` to your `mix.exs`:

```elixir
def deps do
  [
    {:nosedrum, "~> 0.2"},
  ]
end
```

If you want to install the GitHub version of Nostrum, you will need to specify
it with `override: true` in your `mix.exs`, for example:
```elixir
def deps do
  [
    {:nosedrum, "~> 0.2"},
    {:nostrum, github: "Kraigie/nostrum", override: true}
  ]
end
```


<!-- vim: set textwidth=80 sw=2 ts=2: -->
