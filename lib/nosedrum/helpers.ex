defmodule Nosedrum.Helpers do
  @moduledoc "User interaction helpers that don't fit into their own module."

  @doc """
  Escape `@everyone` and `@here` mentions in the given `content`
  with a zero-width space character.

  ## Example

      iex> Nosedrum.Helpers.escape_server_mentions("hello world")
      "hello world"
      iex> Nosedrum.Helpers.escape_server_mentions("hello @everyone @here")
      "hello @\u200Beveryone @\u200Bhere"
  """
  @spec escape_server_mentions(String.t()) :: String.t()
  def escape_server_mentions(content) do
    content
    |> String.replace("@everyone", "@\u200Beveryone")
    |> String.replace("@here", "@\u200Bhere")
  end
end
