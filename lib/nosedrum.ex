defmodule Nosedrum do
  # https://elixirforum.com/t/ex-doc-how-to-configure-so-it-lands-in-the-readme-md/53244/4
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)
  @external_resource "README.md"
end
