defmodule Nosedrum.Storage.ETSTest do
  alias Nosedrum.Storage
  use ExUnit.Case

  defmodule TestCommand do
    def aliases, do: ["nose", "drum"]
  end

  describe "reading with no table entries" do
    setup do
      %{pid: start_supervised!(Storage.ETS)}
    end

    test "all_commands/0 returns an empty map" do
      assert %{} = Storage.ETS.all_commands()
    end
  end

  describe "writing top-level commands" do
    setup do
      %{pid: start_supervised!(Storage.ETS)}
    end

    test "add_command/1 returns `:ok`" do
      assert :ok = Storage.ETS.add_command(["test"], TestCommand)
    end

    test "delete_command/1 returns `:ok`" do
      assert :ok = Storage.ETS.remove_command(["abcdefg"])
    end
  end

  describe "reading top-level commands" do
    setup do
      pid = start_supervised!(Storage.ETS)
      command_name = "zoink"
      :ok = Storage.ETS.add_command([command_name], TestCommand)
      %{pid: pid, command_name: command_name}
    end

    test "lookup_command/1 returns the added command" do
      assert Storage.ETS.lookup_command("zoink") == TestCommand
      assert Storage.ETS.lookup_command("nose") == TestCommand
      assert Storage.ETS.lookup_command("drum") == TestCommand
    end

    test "all_commands/0 shows added command", %{command_name: command_name} do
      assert Storage.ETS.all_commands() == %{
               command_name => TestCommand,
               "nose" => TestCommand,
               "drum" => TestCommand
             }
    end

    test "add_command/2 returns error when trying to add subcommand", %{
      command_name: command_name
    } do
      assert {:error, _reason} = Storage.ETS.add_command([command_name, "test"], TestCommand)
    end

    test "remove_command/2 returns error when trying to remove subcommand", %{
      command_name: command_name
    } do
      assert {:error, _reason} = Storage.ETS.remove_command([command_name, "stuff"])
    end
  end

  describe "removing top-level commands" do
    setup do
      pid = start_supervised!(Storage.ETS)
      command_name = "borg"
      :ok = Storage.ETS.add_command([command_name], Command)
      %{pid: pid, command_name: command_name}
    end

    test "remove_command/0 deletes properly", %{command_name: command_name} do
      assert :ok = Storage.ETS.remove_command([command_name])
      assert %{} = Storage.ETS.all_commands()
    end
  end

  describe "adding subcommands in command groups" do
    setup do
      pid = start_supervised!(Storage.ETS)
      command_path = ["zerg", "spawn"]
      :ok = Storage.ETS.add_command(command_path, Command)
      %{pid: pid, command_path: command_path}
    end

    test "add_command/2 updates the entry", %{command_path: [name, subcommand]} do
      assert :ok = Storage.ETS.add_command([name, "promote"], Command)
      assert Storage.ETS.lookup_command(name) == %{subcommand => Command, "promote" => Command}
    end
  end

  describe "working with subsubcommands" do
    setup do
      pid = start_supervised!(Storage.ETS)
      command_path = ["zerg", "spawn", "minion"]
      :ok = Storage.ETS.add_command(command_path, TestCommand)
      %{pid: pid, command_path: command_path}
    end

    test "add_command/2 updates the entry", %{command_path: [group, subgroup, subcommand]} do
      assert :ok = Storage.ETS.add_command([group, subgroup, "promote"], Command)

      assert Storage.ETS.lookup_command(group) == %{
               subgroup => %{
                 subcommand => TestCommand,
                 "nose" => TestCommand,
                 "drum" => TestCommand,
                 "promote" => Command
               }
             }
    end

    test "remove_command/2 removes the entry", %{command_path: [group, subgroup, subcommand]} do
      assert Storage.ETS.lookup_command(group) == %{
               subgroup => %{
                 subcommand => TestCommand,
                 "nose" => TestCommand,
                 "drum" => TestCommand
               }
             }

      assert :ok = Storage.ETS.remove_command([group, subgroup, subcommand])
      assert Storage.ETS.lookup_command(group) == nil
    end
  end

  describe "removing subcommands from command groups" do
    setup do
      pid = start_supervised!(Storage.ETS)
      :ok = Storage.ETS.add_command(["zerg", "arise"], Command)
      command_path = ["zerg", "spawn"]
      :ok = Storage.ETS.add_command(command_path, Command)
      %{pid: pid, command_path: command_path}
    end

    test "remove_command/2 removes the subcommand", %{command_path: [name, subcommand] = path} do
      assert Storage.ETS.lookup_command(name) == %{subcommand => Command, "arise" => Command}
      assert :ok = Storage.ETS.remove_command(path)
      assert Storage.ETS.lookup_command(name) == %{"arise" => Command}
    end
  end
end
