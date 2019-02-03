defmodule Nosedrum.Helpers do
  @moduledoc "User interaction helpers that don't fit into their own module."

  @doc """
  Escape `@everyone` and `@here` mentions in the given `content`
  with a zero-width space character.

  ## Example

      iex> Nosedrum.Helpers.escape_server_mentions("hello world")
      "hello world"
      iex> Nosedrum.Helpers.escape_server_mentions("hello @everyone @here")
      "hello @\u200Beveryone @\u200Bhere"  # No space to be seen, but no mention either!
  """
  @spec escape_server_mentions(String.t()) :: String.t()
  def escape_server_mentions(content) do
    content
    |> String.replace("@everyone", "@\u200Beveryone")
    |> String.replace("@here", "@\u200Bhere")
  end

  @doc """
  Try to split the given `text` using `OptionParser.split/1` and fall back to
  `String.split/1` if not applicable.

  `OptionParser.split/1` raises a `RuntimeError` if the text it is given
  contains opening quotation marks that were not closed again. In other cases,
  it is desirable to split a string into quoted parts, for example:

      iex> Nosedrum.Helpers.quoted_split("echo \\"hello bot\\"")
      ["echo", "hello bot"]
      iex> Nosedrum.Helpers.quoted_split("echo \\"hello bot")
      ["echo", "\\"hello", "bot"]
  """
  @spec quoted_split(String.t()) :: [String.t()]
  def quoted_split(text) do
    OptionParser.split(text)
  rescue
    _ in RuntimeError -> String.split(text)
  end
end
