defmodule Nosedrum.Interactor.Dispatcher do
  @moduledoc """
  An implementation of `Nosedrum.Interactor`, dispatching Application Command Interactions to the appropriate modules.
  """
  @behaviour Nosedrum.Interactor

  use GenServer

  alias Nostrum.Struct.Interaction
  alias Nosedrum.Interactor

  ## Api
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def handle_interaction(%Interaction{} = interaction) do
    GenServer.cast(__MODULE__, {:handle, interaction})
  end

  # TODO: Add an `:overwrite?` option to add_command. When false, add_command will do nothing if a command under the
  # given path is already registered
  @impl true
  def add_command(path, scope, command) do
    payload = build_payload(path, command)

    GenServer.call(__MODULE__, {:add, payload, path, scope, command})
  end

  defp build_payload(path, command) when is_binary(path) do
    options = if function_exported?(command, :options, 0) do
      command.options()
    else
      []
    end
    IO.inspect command
    IO.inspect function_exported?(command, :options, 0)

    %{
      type: parse_type(command.type()),
      name: path,
      description: command.description(),
      options: options,
    }
  end

  defp build_payload(path, command) when is_list(path) do
    Enum.map(path, fn {{name, desc}, list} ->
      if get_depth(path) == 3 do
        %{
          name: name,
          description: desc,
          options: build_payload(list, command),
        }
      else
        # Determine type based on depth of the remaining path. 2 is SUB_COMMAND_GROUP and 1 is SUB_COMMAND
        type = get_depth(list) == 2 && 2 || 1

        %{
          type: type,
          name: name,
          description: desc,
          options: build_payload(list, command),
        }
      end
    end)
  end

  @impl true
  def remove_command(path, scope) do

  end

  ## Impl
  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:add, payload, path, :global, command}, _from, commands) do
    case Nostrum.Api.create_global_application_command(payload) do
      {:ok, _} = response ->
        {:reply, response, Map.put(commands, path, command)}
      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:add, payload, path, {:guild, guild_ids}, command}, _from, commands) when is_list(guild_ids) do
    Enum.each(guild_ids, fn guild_id ->
      case Nostrum.Api.create_guild_application_command(guild_id, payload) do
        {:ok, _} = response ->
          {:reply, response, Map.put(commands, path, command)}
        error ->
          {:reply, {:error, error}, commands}
      end
    end)
  end

  @impl true
  def handle_call({:add, payload, path, {:guild, guild_id}, command}, _from, commands) do
    case Nostrum.Api.create_guild_application_command(guild_id, payload) do
      {:ok, _} = response ->
        {:reply, response, Map.put(commands, path, command)}
      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_cast({:handle, %Interaction{data: %{name: name}} = interaction}, commands) do
    with {:ok, module} <- Map.fetch(commands, name) do
      response = module.command(interaction)
      Interactor.respond(interaction, response)
    end
    {:noreply, commands}
  end

  defp parse_type(type) do
    Map.fetch!(%{
      slash: 1,
      user: 2,
      message: 3,
    }, type)
  end

  defp get_depth(path, depth) when is_binary(path) do
    depth + 1
  end

  defp get_depth(path, depth) do
    get_depth(path, depth + 1)
  end

  defp get_depth(path) do
    get_depth(path, 0)
  end
end
