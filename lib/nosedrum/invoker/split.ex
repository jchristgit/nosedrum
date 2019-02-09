defmodule Nosedrum.Invoker.Split do
  @moduledoc """
  An `OptionParser.split/1`-based command processor.

  This parser supports a single prefix configured via the `nosedrum.prefix`
  configuration variable:

      config :nosedrum,
        prefix: "!"

  The default prefix is `.`. Note that the prefix is looked up at
  compilation time to avoid constant ETS reads.

  This invoker checks predicates and reports errors
  directly in the channel in which they were caused.
  """

  @behaviour Nosedrum.Invoker
  @prefix Application.get_env(:nosedrum, :prefix, ".")

  alias Nosedrum.{Helpers, Predicates}
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @doc false
  def handle_message(
        message,
        storage \\ Nosedrum.Storage.ETS,
        storage_process \\ :nosedrum_commands
      ) do
    with @prefix <> content <- message.content,
         [command | args] <- Helpers.quoted_split(content),
         cog when cog != nil <- storage.lookup_command(command, storage_process) do
      handle_command(cog, message, args)
    else
      _mismatch -> :ignored
    end
  end

  @spec parse_args(Module.t(), [String.t()]) :: [String.t()] | any()
  defp parse_args(command_module, args) do
    if function_exported?(command_module, :parse_args, 1) do
      command_module.parse_args(args)
    else
      args
    end
  end

  @spec invoke(Module.t(), Message.t(), [String.t()]) :: any()
  defp invoke(command_module, msg, args) do
    case Predicates.evaluate(msg, command_module.predicates()) do
      :passthrough ->
        command_module.command(msg, parse_args(command_module, args))

      {:error, reason} ->
        # a predicate failed. show the response generated by it
        Api.create_message!(msg.channel_id, reason)
    end
  end

  @spec handle_command(Map.t() | Module.t(), Message.t(), [String.t()]) ::
          :ignored | {:ok, Message.t()} | any()
  defp handle_command(command_map, msg, original_args) when is_map(command_map) do
    maybe_subcommand = List.first(original_args)

    case Map.fetch(command_map, maybe_subcommand) do
      {:ok, subcommand_module} ->
        # If we have at least one subcommand, that means `original_args`
        # needs to at least contain one element, so `args` is either empty
        # or the rest of the arguments excluding the subcommand name.
        [_subcommand | args] = original_args
        invoke(subcommand_module, msg, args)

      :error ->
        # Does the command group have a default command to invoke?
        if Map.has_key?(command_map, :default) do
          # If yes, invoke it with all arguments.
          invoke(command_map.default, msg, original_args)
        else
          # Otherwise, respond with all known subcommands in the command group.
          subcommand_string =
            command_map |> Map.keys() |> Stream.map(&"`#{&1}`") |> Enum.join(", ")

          response = "🚫 unknown subcommand, known subcommands: #{subcommand_string}"
          Api.create_message!(msg.channel_id, response)
        end
    end
  end

  defp handle_command(command_module, msg, args) do
    invoke(command_module, msg, args)
  end
end
