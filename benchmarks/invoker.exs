defmodule MyCommand do
  def predicates, do: []
  def description, do: ""
  def command(_, [_word]), do: :ok
end

Nosedrum.Storage.ETS.start_link(name: Nosedrum.Storage.ETS)
Nosedrum.Storage.ETS.add_command([".echo"], MyCommand)

inputs = [
  {"short non-commands", %{content: "hi guys"}},
  {"short non-commands", %{content: "hello its me"}},
  {"short non-commands", %{content: "abcdefg"}},

  {"long non-commands", %{content: "hello world this is pure garbage that i am typing here and it makes absolutely no sense at all"}},
  {"long non-commands", %{content: "zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop zoop"}},
  {"long non-commands", %{content: ?A..?z |> Enum.to_list() |> List.to_string()}},

  {"prefixed non-command messages", %{content: ".what is pointer???"}},
  {"prefixed non-command messages", %{content: ".man adduser"}},
  {"prefixed non-command messages", %{content: ".hellobotpleasereplytome"}},

  {"simple command invocations", %{content: ".echo"}},
  {"simple command invocations", %{content: ".echo hello world"}},
  {"simple command invocations", %{content: ".echo foo bar baz 😃"}}
]

bench = %{
  "Split-based invoker" => &Nosedrum.Invoker.Split.handle_message(&1)
}

Benchee.run(bench, time: 20, inputs: inputs)
