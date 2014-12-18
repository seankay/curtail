defmodule Curtail.Html do
  @moduledoc """
  Helper methods for `Curtail`.
  """

  defstruct open_tags: [],
            close_tags: []

  def tag?(token), do: Regex.match?(~r/<\/?[^>]+>/, token) && !comment?(token)

  def open_tag?(token), do: Regex.match?(~r/<(?!(?:br|img|hr|script|\/))[^>]+>/i, token)

  def comment?(token), do: Regex.match?(~r/(*ANY)<\s?!--.*-->/, token)

  def matching_close_tag(token) do
    Regex.replace(~r/<(\w+)\s?.*>/, token, "</\\1>") |> String.strip
  end

  def matching_close_tag?(open_tag, close_tag) do
    matching_close_tag(open_tag) == close_tag
  end
end
