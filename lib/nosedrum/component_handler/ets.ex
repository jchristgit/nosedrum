defmodule Nosedrum.ComponentHandler.ETS do
  @moduledoc """
  ETS-based implementation of a `Nosedrum.ComponentHandler`.

  When a pid is registered as a handler for components it will be monitored
  and automatically removed once the process exits. Registered module handlers
  on the other hand are never cleared. You can access the named ETS-table manually
  to remove any keys if necessary.

  ## Options
  * :name - name used for registering the process under and also the name of the ETS-table.
  Must be a atom, because it will be passed to `:ets.new/2` as name. Defaults to `Nosedrum.ComponentHandler.ETS`
  > ### Note {: .info}
  > When using a different name than the default you must pass it as first argument of
  > the callbacks.
  >
  > ```elixir
  > # Assuming name was set to MyApp.ComponentHandler
  > Nosedrum.Storage.ETS.register_components(MyApp.ComponentHandler,
  >   ["a", "b", "c"], MyApp.ComponentHandlers.ABCHandler)
  > ```

  """

  @doc false
  use GenServer

  @behaviour Nosedrum.ComponentHandler

  alias Nosedrum.Storage

  @impl Nosedrum.ComponentHandler
  def register_components(server \\ __MODULE__, component_ids, module, additional_data) do
    GenServer.call(server, {:register_components, component_ids, module, additional_data})
  end

  @impl Nosedrum.ComponentHandler
  def handle_component_interaction(
        server \\ __MODULE__,
        %Nostrum.Struct.Interaction{} = interaction
      ) do
    component_id = interaction.data.custom_id

    case :ets.match(server, {component_id, :"$1", :"$2"}) do
      [[pid, additional_data]] when is_pid(pid) ->
        send(pid, {:message_component_interaction, interaction, additional_data})
        :ok

      [[module, additional_data]] when is_atom(module) ->
        with response <- module.message_component_interaction(interaction, additional_data),
             {:ok} <- Storage.respond(interaction, response),
             {_defer_type, callback_tuple} <- Keyword.get(response, :type) do
          Storage.followup(interaction, callback_tuple)
        end

      [] ->
        {:error, :not_found}
    end
  end

  @doc false
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    table = :ets.new(name, [:named_table, :public, :ordered_set, read_concurrency: true])
    {:ok, table}
  end

  @impl GenServer
  def handle_call(
        {:register_components, component_ids, component_handler, additional_data},
        _from,
        table
      ) do
    if is_pid(component_handler) do
      # Get notified then a stateful component handler exists
      Process.monitor(component_handler)
    end

    entries =
      component_ids
      |> List.wrap()
      |> Enum.map(&{&1, component_handler, additional_data})

    :ets.insert(table, entries)
    {:reply, :ok, table}
  end

  @impl GenServer
  def handle_info({:DOWN, _, :process, pid, _}, table) do
    # Remove stateful component handlers when the process exits
    :ets.match_delete(table, {:_, pid})
    {:noreply, table}
  end
end
