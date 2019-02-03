# nosedrum

`nosedrum` is a command framework for use with the excellent
[`nostrum`](https://github.com/Kraigie/nostrum) library.

It contains behaviour specifications for easily implementing command handling in
your bot along with other conveniences to ease creating an interactive bot.

`nosedrum`s provided implementations are largely based off what was originally
written for [bolt](https://github.com/jchristgit/bolt). bolt also contains
around [57
commands](https://github.com/jchristgit/bolt/tree/master/lib/bolt/cogs) based
off the `Nosedrum.Command` behaviour that you can explore if you're looking for
inspiration.

The documentation can be found at https://hexdocs.pm/nosedrum.

## Installation

Since `nostrum`s hex release is out of date and we can only depend on packages
from hex when publishing to hex, you need to specify `override: true` when using
the GitHub version of nostrum:

```elixir
def deps do
  [
    {:nostrum, github: "Kraigie/nostrum", override: true},
    {:nosedrum, "~> 0.1"},
  ]
end
```


<!-- vim: set textwidth=80 sw=2 ts=2: -->
