defmodule Nosedrum.Storage.Dispatcher do
  @moduledoc """
  An implementation of `Nosedrum.Storage`, dispatching Application Command Interactions to the appropriate modules.
  """
  @moduledoc since: "0.4.0"
  @behaviour Nosedrum.Storage

  use GenServer

  alias Nosedrum.Storage
  alias Nostrum.Api.ApplicationCommand
  alias Nostrum.Struct.Interaction

  @type_mappings %{
    options: %{
      sub_command: 1,
      sub_command_group: 2,
      string: 3,
      integer: 4,
      boolean: 5,
      user: 6,
      channel: 7,
      role: 8,
      mentionable: 9,
      number: 10,
      attachment: 11
    },
    contexts: %{
      guild: 0,
      bot_dms: 1,
      private_channel: 2
    },
    integration_types: %{
      guild_install: 0,
      user_install: 1
    },
    commands: %{
      slash: 1,
      user: 2,
      message: 3
    }
  }

  @optional_fields %{
    nsfw: 0,
    default_member_permissions: 0,
    contexts: 0,
    integration_types: 0
  }

  ## Api
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def handle_interaction(%Interaction{} = interaction, id \\ __MODULE__) do
    with {:ok, module} <- GenServer.call(id, {:fetch, interaction}),
         response <- module.command(interaction),
         {:ok} <- Storage.respond(interaction, response),
         {_defer_type, callback_tuple} <- Keyword.get(response, :type) do
      Storage.followup(interaction, callback_tuple)
    else
      :error ->
        {:error, :unknown_command}

      # the response type was not a callback tuple, no need to follow up
      res_type when is_atom(res_type) or is_integer(res_type) ->
        {:ok}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def process_queue(scope, id \\ __MODULE__) do
    GenServer.call(id, {:process_queue, scope})
  end

  @impl true
  def queue_command(path, command, id \\ __MODULE__) do
    command_name =
      if is_binary(path) do
        path
      else
        path
        |> Enum.take(1)
        |> List.first()
        |> unwrap_key()
      end

    GenServer.call(id, {:queue, command_name, command})
  end

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
        |> unwrap_key()
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

  def handle_call({:process_queue, :global}, _from, commands) do
    command_list =
      Enum.map(commands, fn {p, c} ->
        build_payload(p, c)
      end)

    case ApplicationCommand.bulk_overwrite_global_commands(command_list) do
      {:ok, _} = response ->
        {:reply, response, commands}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  def handle_call({:process_queue, guild_id}, _from, commands) do
    command_list =
      Enum.map(commands, fn {p, c} ->
        build_payload(p, c)
      end)

    case ApplicationCommand.bulk_overwrite_guild_commands(guild_id, command_list) do
      {:ok, _} = response ->
        {:reply, response, commands}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:queue, name, command}, _from, commands) do
    {:reply, :ok, Map.put(commands, name, command)}
  end

  @impl true
  def handle_call({:add, payload, name, command, :global}, _from, commands) do
    case ApplicationCommand.create_global_command(payload) do
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
        case ApplicationCommand.create_guild_command(guild_id, payload) do
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
    case ApplicationCommand.create_guild_command(guild_id, payload) do
      {:ok, _} = response ->
        {:reply, response, Map.put(commands, name, command)}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:remove, name, command_id, :global}, _from, commands) do
    case ApplicationCommand.delete_global_command(command_id) do
      {:ok} = response ->
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
        case ApplicationCommand.delete_guild_command(guild_id, command_id) do
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
    case ApplicationCommand.delete_guild_command(guild_id, command_id) do
      {:ok} = response ->
        {:reply, response, Map.delete(commands, name)}

      error ->
        {:reply, {:error, error}, commands}
    end
  end

  @impl true
  def handle_call({:fetch, %Interaction{data: %{name: name}}}, _from, commands) do
    {:reply, Map.fetch(commands, name), commands}
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
      name: name
    }
    |> put_type_specific_fields(command, options)
    |> add_optional_fields(command)
    |> apply_payload_updates(command)
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

  defp build_payload({options, _command}) when is_list(options) do
    parse_option_types(options)
  end

  defp parse_type(type) do
    Map.fetch!(
      @type_mappings.commands,
      type
    )
  end

  defp parse_option_types(options) do
    Enum.map(options, fn
      map when is_map_key(map, :type) ->
        updated_map = Map.update!(map, :type, &Map.fetch!(@type_mappings.options, &1))

        if is_map_key(updated_map, :options) do
          parsed_options = parse_option_types(updated_map[:options])
          Map.replace!(updated_map, :options, parsed_options)
        else
          updated_map
        end

      map ->
        map
    end)
  end

  defp apply_payload_updates(payload, command) do
    if function_exported?(command, :update_command_payload, 1) do
      command.update_command_payload(payload)
    else
      payload
    end
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

  defp unwrap_key({{key, _}, _}), do: key
  defp unwrap_key({key, _}), do: key

  defp put_type_specific_fields(payload, command, options) do
    if command.type() == :slash do
      payload
      |> Map.put(:description, command.description())
      |> Map.put(:options, options)
    else
      payload
    end
  end

  defp add_optional_fields(payload, command) do
    Enum.reduce(@optional_fields, payload, fn
      {callback_name, callback_arity}, acc ->
        if command |> function_exported?(callback_name, callback_arity) do
          acc |> add_field(command, callback_name)
        else
          acc
        end
    end)
  end

  defp add_field(payload, command, :default_member_permissions) do
    Map.put(
      payload,
      :default_member_permissions,
      command.default_members_permissions() |> Nostrum.Permission.to_bitset()
    )
  end

  defp add_field(payload, command, :contexts) do
    Map.put(
      payload,
      :contexts,
      command.contexts() |> Enum.map(&@type_mappings.contexts[&1])
    )
  end

  defp add_field(payload, command, :integration_types) do
    Map.put(
      payload,
      :integration_types,
      command.integration_types() |> Enum.map(&@type_mappings.integration_types[&1])
    )
  end

  defp add_field(payload, command, name), do: Map.put(payload, name, apply(command, name, []))
end
