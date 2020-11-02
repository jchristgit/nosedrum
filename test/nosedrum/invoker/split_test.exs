defmodule Nosedrum.Invoker.SplitTest do
  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nosedrum.Storage.ETS, as: CommandStorage
  use ExUnit.Case, async: true

  doctest Nosedrum.Invoker.Split

  defmodule SimpleCommand do
    def command(_msg, _args), do: :command_return
    def predicates, do: []
  end

  describe "handle_message/1-3 with non-prefixed messages" do
    test "ignores messages" do
      message = %{content: "hello world"}
      assert :ignored = CommandInvoker.handle_message(message)
    end
  end

  describe "handle_message/1-3 with unknown commands" do
    setup do
      start_supervised!(CommandStorage)
      :ok
    end

    test "ignores messages" do
      message = %{content: ".test abc"}
      assert :ignored = CommandInvoker.handle_message(message)
    end
  end

  describe "handle_command/1-3 with regular commands" do
    setup do
      storage_pid = start_supervised!(CommandStorage)
      storage_tid = GenServer.call(storage_pid, :tid)
      assert :ok = CommandStorage.add_command(["simple_command"], SimpleCommand)

      %{storage: storage_tid}
    end

    test "invokes command on proper invocation", %{storage: storage_tid} do
      message = %{content: ".simple_command help"}
      assert :command_return = CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end
  end

  describe "handle_command/1-3 with custom parse_args" do
    defmodule SimpleParsedCommand do
      def command(_msg, args), do: args
      def predicates, do: []
      def parse_args(_args), do: :parsed_args
    end

    setup do
      storage_pid = start_supervised!(CommandStorage)
      storage_tid = GenServer.call(storage_pid, :tid)
      assert :ok = CommandStorage.add_command(["simple", "subcommand"], SimpleParsedCommand)

      %{storage: storage_tid}
    end

    test "invokes command on proper invocation", %{storage: storage_tid} do
      message = %{content: ".simple subcommand"}
      assert :parsed_args = CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end
  end

  describe "handle_command/1-3 with nested subcomamnds" do
    setup do
      storage_pid = start_supervised!(CommandStorage)
      storage_tid = GenServer.call(storage_pid, :tid)
      assert :ok = CommandStorage.add_command(["simple", "nested", "subcommand"], SimpleCommand)

      %{storage: storage_tid}
    end

    test "invokes command on proper invocation", %{storage: storage_tid} do
      message = %{content: ".simple nested subcommand"}
      assert :command_return = CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end
  end

  describe "handle_command/1-3 with default subcommands" do
    defmodule SimpleDefaultSubcommand do
      def command(_msg, args), do: args
      def predicates, do: []
    end

    setup do
      storage_pid = start_supervised!(CommandStorage)
      storage_tid = GenServer.call(storage_pid, :tid)
      assert :ok = CommandStorage.add_command(["test", :default], SimpleDefaultSubcommand)

      assert :ok =
               CommandStorage.add_command(["test", "nested", :default], SimpleDefaultSubcommand)

      %{storage: storage_tid}
    end

    test "invokes command on proper invocation", %{storage: storage_tid} do
      message = %{content: ".test me"}
      assert ["me"] = CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end

    test "invokes subcommand on proper invocation", %{storage: storage_tid} do
      message = %{content: ".test nested me"}
      assert ["me"] = CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end
  end

  describe "handle_command/1-3 with predicates denying" do
    defmodule PredicatedCommandWithNoperm do
      def command(_msg, args), do: args
      def predicates, do: [fn _msg -> {:noperm, "you shall not pass"} end]
    end

    setup do
      storage_pid = start_supervised!(CommandStorage)
      storage_tid = GenServer.call(storage_pid, :tid)
      assert :ok = CommandStorage.add_command(["test"], PredicatedCommandWithNoperm)
      %{storage: storage_tid}
    end

    test "bubbles up noperm from predicate", %{storage: storage_tid} do
      message = %{content: ".test"}

      assert {:noperm, "you shall not pass"} =
               CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end
  end

  describe "handle_command/1-3 with predicates failing" do
    defmodule PredicatedCommandWithInternalFailure do
      def command(_msg, args), do: args
      def predicates, do: [fn _msg -> {:error, "I shall not pass"} end]
    end

    setup do
      storage_pid = start_supervised!(CommandStorage)
      storage_tid = GenServer.call(storage_pid, :tid)

      assert :ok =
               CommandStorage.add_command(
                 ["test"],
                 PredicatedCommandWithInternalFailure
               )

      %{storage: storage_tid}
    end

    test "bubbles up noperm from predicate", %{storage: storage_tid} do
      message = %{content: ".test"}

      assert {:error, "I shall not pass"} =
               CommandInvoker.handle_message(message, CommandStorage, storage_tid)
    end
  end
end
