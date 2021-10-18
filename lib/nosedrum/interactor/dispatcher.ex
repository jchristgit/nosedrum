defmodule Nosedrum.Interactor.Dispatcher do
  @moduledoc """
  An implementation of `Nosedrum.Interactor`, dispatching Application Command Interactions to the appropriate modules.
  """
  @behaviour Nosedrum.Interactor

  use GenServer

  alias Nostrum.Struct.Interaction
  alias Nosedrum.Interactor

  @option_type_map %{
    sub_command: 1,
    sub_command_group: 2,
    string: 3,
    integer: 4,
    boolean: 5,
    user: 6,
    channel: 7,
    role: 8,
    mentionable: 9,
    number: 10
  }

  ## Api
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def handle_interaction(%Interaction{} = interaction, id \\ __MODULE__) do
    GenServer.cast(id, {:handle, interaction})
  end

  # TODO: Add an `:overwrite?` option to add_command. When false, add_command will do nothing if a command under the
  # given path is already registered. Default to true
  @impl true
  def add_command(path, command, scope, id \\ __MODULE__) do
    payload = build_payload(path, command)

    command_name =
      if is_binary(path) do
        path
      else
        path
        |> Enum.take(1)
        |> List.first()
        |> then(fn {key, _v} -> if is_tuple(key), do: elem(key, 0), else: key end)
      end

    GenServer.call(id, {:add, payload, command_name, command, scope})
  end

  @impl true
  def remove_command(name, command_id, scope, id \\ __MODULE__) do
    GenServer.call(id, {:remove, name, command_id, scope})
  end

  ## Impl
  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:add, payload, name, command, :global}, _from, commands) do
    case Nostrum.Api.create_global_application_command(payload) do
      {:ok, _} = response ->
        {:reply, response, Map.put(commands, name, command)}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:add, payload, name, command, guild_id_list}, _from, commands)
      when is_list(guild_id_list) do
    res =
      Enum.reduce(guild_id_list, {[], []}, fn guild_id, {errors, responses} ->
        case Nostrum.Api.create_guild_application_command(guild_id, payload) do
          {:ok, _} = response ->
            {errors, [response | responses]}

          error ->
            {[error | errors], responses}
        end
      end)

    {:reply, res, Map.put(commands, name, command)}
  end

  @impl true
  def handle_call({:add, payload, name, command, guild_id}, _from, commands) do
    case Nostrum.Api.create_guild_application_command(guild_id, payload) do
      {:ok, _} = response ->
        {:reply, response, Map.put(commands, name, command)}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:remove, name, command_id, :global}, _from, commands) do
    case Nostrum.Api.delete_global_application_command(command_id) do
      {:ok, _} = response ->
        {:reply, response, Map.delete(commands, name)}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:remove, name, command_id, guild_id_list}, _from, commands)
      when is_list(guild_id_list) do
    res =
      Enum.reduce(guild_id_list, {[], []}, fn guild_id, {errors, responses} ->
        case Nostrum.Api.delete_guild_application_command(guild_id, command_id) do
          {:ok} ->
            {errors, [:ok | responses]}

          error ->
            {[error | errors], responses}
        end
      end)

    {:reply, res, Map.delete(commands, name)}
  end

  @impl true
  def handle_call({:remove, name, command_id, guild_id}, _from, commands) do
    case Nostrum.Api.delete_guild_application_command(guild_id, command_id) do
      {:ok, _} = response ->
        {:reply, response, Map.delete(commands, name)}

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

  defp build_payload(name, command) when is_binary(name) do
    Code.ensure_loaded(command)

    options =
      if function_exported?(command, :options, 0) do
        command.options()
        |> parse_option_types()
      else
        []
      end

    %{
      type: parse_type(command.type()),
      name: name,
    }
    |> then(& if command.type() == :slash do
      &1
      |> Map.put(:description, command.description())
      |> Map.put(:options, options)
    else
      &1
    end)
  end

  # This seems like a hacky way to unwrap the outer list...
  defp build_payload(path, command) do
    build_payload({path, command})
    |> List.first()
  end

  defp build_payload({path, command}) when is_map(path) do
    Enum.map(path, fn {{name, desc}, value} ->
      if get_depth(path) == 3 do
        %{
          name: name,
          description: desc,
          options: build_payload({value, command})
        }
      else
        # Determine type based on depth of the remaining path. 2 is SUB_COMMAND_GROUP and 1 is SUB_COMMAND
        type = (get_depth(value) == 2 && 2) || 1

        %{
          type: type,
          name: name,
          description: desc,
          options: build_payload({value, command})
        }
      end
    end)
  end

  # TODO: Might want to let the user define a `options/1` callback in their command module, where the parameter is the
  # tuple key for these options in the path (i.e. {"get", "Get permissions for a user"})
  defp build_payload({options, _command}) when is_list(options) do
    parse_option_types(options)
  end

  defp parse_type(type) do
    Map.fetch!(
      %{
        slash: 1,
        user: 2,
        message: 3
      },
      type
    )
  end

  defp parse_option_types(options) do
    Enum.map(options, fn
      map when is_map_key(map, :type) ->
        Map.update!(map, :type, &Map.fetch!(@option_type_map, &1))

      map ->
        map
    end)
  end

  defp get_depth(path, depth) do
    Enum.reduce(path, 0, fn
      {_key, map}, cur_max when is_list(map) ->
        max(cur_max, get_depth(map, depth + 1))

      _, cur_max ->
        max(cur_max, depth)
    end)
  end

  defp get_depth(path) do
    get_depth(path, 1)
  end
end
