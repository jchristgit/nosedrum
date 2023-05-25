defmodule Nosedrum.TextCommand.Invoker.Split do
  @moduledoc """
  An `OptionParser.split/1`-based command processor.

  This parser supports command prefixes configured via the `nosedrum.prefix`
  configuration variable. You can specify a single prefix (as a string):

      config :nosedrum,
        prefix: "!"

  Or a multiple prefixes (as a list of strings):

      config :nosedrum,
        prefix: ["!", "?"]

  If multiple prefixes are specified, the first match in the list will be used.
  For example, if the prefixes are `["a", "ab"]`, then the message `"ab foo"`
  will invoke the command `b`, with the argument `foo`.  However, if the prefixes
  were ordered `["ab", "a"]`, the message `"abfoo"` would invoke the command
  `foo` with no arguments.

  The default prefix is `.`, and the prefix are looked up at compilation time
  due to the nature of Elixir's binary matching. This means that if you change
  your prefix, you need to recompile this module, usually using
  `mix deps.compile --force nosedrum`.

  This invoker checks predicates and returns predicate failures to the caller.
  """

  @behaviour Nosedrum.TextCommand.Invoker

  # This must be looked up at compilation time due to the nature of Elixir's
  # binary matching. Also, SPEEEEEEEEEEEEEED!!
  @prefix Application.compile_env(:nosedrum, :prefix, ".")

  alias Nosedrum.Helpers
  alias Nosedrum.TextCommand.Predicates
  alias Nostrum.Struct.Message

  @spec remove_prefix(String.t()) :: String.t() | :not_found
  if is_list(@prefix) do
    defp remove_prefix(message) do
      with(
        # Find the prefix that was used in the message, going through the list of prefixes
        real_prefix when real_prefix != :not_found <-
          Enum.find(
            @prefix,
            :not_found,
            &String.starts_with?(message, &1)
          ),
        # Then, just remove the prefix from the message
        prefix_length <- byte_size(real_prefix),
        content <-
          message
          |> binary_part(prefix_length, byte_size(message) - prefix_length)
      ) do
        content
      else
        _no_match -> :not_found
      end
    end
  else
    defp remove_prefix(message) do
      # credo:disable-for-next-line
      with @prefix <> content <- message do
        content
      else
        _no_match -> :not_found
      end
    end
  end

  @doc """
  Handle the given message.

  This involves checking whether the message starts with the given prefix, splitting
  the message into command and arguments, looking up a candidate command, and finally
  resolving it and invoking the module.

  ## Arguments

  - `message`: The message to handle.
  - `storage`: The storage implementation the command invoker should use.
  - `storage_process`: The storage process, ETS table, or similar that is used by
    the storage process. For instance, this allows you to use different ETS tables
    for the `Nosedrum.TextCommand.Storage.ETS` module if you wish.

  ## Return value

  Returns `:ignored` if one of the following applies:
  - The message does not start with the configured prefix.
  - The message only contains the configured prefix.
  - No command could be looked up that matches the command the message invokes.

  ## Examples

      iex> Nosedrum.TextCommand.Invoker.Split.handle_message(%{content: "foo"})
      :ignored
      iex> Nosedrum.TextCommand.Invoker.Split.handle_message(%{content: "."})
      :ignored
  """
  @spec handle_message(Message.t(), module, atom() | pid()) ::
          :ignored
          | {:error, {:unknown_subcommand, String.t(), :known, [String.t() | :default]}}
          | {:error, :predicate, {:error | :noperm, any()}}
          | any()
  def handle_message(
        message,
        storage \\ Nosedrum.TextCommand.Storage.ETS,
        storage_process \\ :nosedrum_commands
      ) do
    with content when content != :not_found <- remove_prefix(message.content),
         [command | args] <- Helpers.quoted_split(content),
         cog when cog != nil <- storage.lookup_command(command, storage_process) do
      handle_command(cog, message, args)
    else
      _mismatch ->
        :ignored
    end
  end

  @spec parse_args(module(), [String.t()]) :: [String.t()] | any()
  defp parse_args(command_module, args) do
    if function_exported?(command_module, :parse_args, 1) do
      command_module.parse_args(args)
    else
      args
    end
  end

  @spec invoke(module(), Message.t(), [String.t()]) ::
          any() | {:error, :predicate, {:noperm | :error, any()}}
  defp invoke(command_module, msg, args) do
    case Predicates.evaluate(msg, command_module.predicates()) do
      :passthrough ->
        command_module.command(msg, parse_args(command_module, args))

      {atom, _reason} = response when atom in [:noperm, :error] ->
        {:error, :predicate, response}
    end
  end

  @spec handle_command(map() | module(), Message.t(), [String.t()]) ::
          :ignored
          | {:error, {:unknown_subcommand, String.t(), :known, [String.t() | :default]}}
          | {:error, :predicate, {:error | :noperm, any()}}
          | any()
  defp handle_command(command_map, msg, original_args) when is_map(command_map) do
    maybe_subcommand = List.first(original_args)

    case Map.fetch(command_map, maybe_subcommand) do
      {:ok, subcommand} ->
        # If we have at least one subcommand, that means `original_args`
        # needs to at least contain one element, so `args` is either empty
        # or the rest of the arguments excluding the subcommand name.
        [_subcommand | args] = original_args
        # Recursively traverse down to a command module via the `is_map/1`
        # guard clause attached to this function head.
        handle_command(subcommand, msg, args)

      :error ->
        # Does the command group have a default command to invoke?
        if Map.has_key?(command_map, :default) do
          # If yes, invoke it with all arguments.
          invoke(command_map.default, msg, original_args)
        else
          {:error, {:unknown_subcommand, maybe_subcommand, :known, Map.keys(command_map)}}
        end
    end
  end

  defp handle_command(command_module, msg, args) do
    invoke(command_module, msg, args)
  end
end
