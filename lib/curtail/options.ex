defmodule Curtail.Options do

  @default_word_boundary ~r/\S/

  defstruct length: 100,
            omission: "...",
            word_boundary: @default_word_boundary,
            break_token: nil

  alias __MODULE__

  def new(opts\\ []) do
    configure(struct(Options, opts))
  end

  defp configure(opts = %Options{ word_boundary: true}) do
    %Options{opts | word_boundary: @default_word_boundary}
  end
  defp configure(opts), do: opts
end
