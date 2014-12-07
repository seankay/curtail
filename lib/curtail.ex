defmodule Curtail do
  @moduledoc ~S"""
  # An HTML-safe string truncator

  ## Usage

      Curtail.truncate("<p>Truncate me</p>", options)
  """

  @regex ~r/(?:<script.*>.*<\/script>)+|<\/?[^>]+>|[a-z0-9\|`~!@#\$%^&*\(\)\-_\+=\[\]{}:;'²³§",\.\/?]+|\s+|[[:punct:]]|\X/xiu

  @default_word_boundary ~r/\S/
  @default_opts %{
    length: 100,
    omission: "...",
    word_boundary: @default_word_boundary,
    break_token: nil
  }

  alias Curtail.Html

  @doc """
  Safely truncates a string that contains HTML tags.

  ## Options

  * length (default: 100)
  * omission (default: "...")
  * word_boundary (default: "~r/\S/")
  * break_token (default: nil)

  ## Examples

      iex> Curtail.truncate("<p>Truncate me!</p>")
      "<p>Truncate me!</p>"

      iex> Curtail.truncate("<p>Truncate me!</p>", length: 12)
      "<p>Truncate...</p>"

  Truncate without omission string:

      iex> Curtail.truncate("<p>Truncate me!</p>", omission: "", length: 8)
      "<p>Truncate</p>"

  Truncate with custom word_boundary:

      iex> Curtail.truncate("<p>Truncate. Me!</p>", word_boundary: ~r/\S[\.]/, length: 12, omission: "")
      "<p>Truncate.</p>"

  Truncate without word boundary:

      iex> Curtail.truncate("<p>Truncate me</p>", word_boundary: false, length: 7)
      "<p>Trun...</p>"

  Truncate with custom break_token:

      iex> Curtail.truncate("<p>This should be truncated here<break_here>!!</p>", break_token: "<break_here>")
      "<p>This should be truncated here</p>"
  """
  def truncate(string, opts \\ %{})
  def truncate(_string, length: length) when length <= 0, do: ""
  def truncate(string, opts) do
    opts = Enum.into(opts, @default_opts)

    if opts.word_boundary === true do
      opts = Map.put(opts, :word_boundary, @default_word_boundary)
    end

    tokens = Regex.scan(@regex, string)
              |> List.flatten
              |> Enum.map(fn(match) ->
                match |> String.replace(~r/\n/, " ") |> String.replace(~r/\s+/, " ")
              end)

    length = opts.length - String.length(opts.omission)

    do_truncate(tokens, %{open_tags: [], close_tags: [], opts: opts}, length, [])
  end

  defp do_truncate([_token|_rest], state, chars_remaining, acc) when chars_remaining <= 0 do
    do_truncate([], state, 0, acc)
  end

  defp do_truncate([token|_rest], state = %{ opts: %{ break_token: break_token}}, _, acc)
  when break_token == token do
    acc |> close_remaining_tags(state) |> finalize_output
  end

  defp do_truncate([], state, chars_remaining, acc) when chars_remaining > 0 do
    acc |> close_remaining_tags(state) |> finalize_output
  end

  defp do_truncate([], state, _, acc) do
    acc
    |> apply_omission(state.opts.omission)
    |> close_remaining_tags(state)
    |> finalize_output
  end

  defp do_truncate([token | rest], state, chars_remaining, acc) do
    acc = process_token(token, chars_remaining, state.opts, acc)
    {state, chars_remaining} = update_state(token, state, chars_remaining)

    do_truncate(rest, state, chars_remaining, acc)
  end

  defp update_state(token, state, chars_remaining) do
    cond do
      Html.tag?(token) ->
        state = if Html.open_tag?(token) do
          Map.put(state, :open_tags, [token | state.open_tags])
        else
          remove_latest_open_tag(token, state)
        end

      !Html.comment?(token) ->
        chars_remaining = calculate_chars_remaining(token, chars_remaining, state.opts)

      true -> #noop
    end

    {state, chars_remaining}
  end

  defp process_token(token, chars_remaining, opts, acc) do
    cond do
      Html.tag?(token) || Html.comment?(token) ->
        [token | acc]
      opts.word_boundary ->
        if (chars_remaining - String.length(token)) >= 0 do
          [token | acc]
        else
          acc
        end
      true ->
        [String.slice(token, 0..chars_remaining - 1) | acc]
    end
  end

  defp remove_latest_open_tag(close_tag, state = %{ open_tags: open_tags }) do
    case Enum.find_index(open_tags, &(Html.matching_close_tag?(&1, close_tag))) do
      nil ->
        state
      index ->
        Map.put(state, :open_tags, List.delete_at(open_tags, index))
    end
  end

  defp calculate_chars_remaining(token, chars_remaining, %{word_boundary: false}) do
    chars_remaining - (String.slice(token, 0..chars_remaining - 1) |> String.length)
  end
  defp calculate_chars_remaining(token, chars_remaining, _) do
    chars_remaining - String.length(token)
  end

  defp apply_omission([], nil), do: [""]
  defp apply_omission([], omission), do: [omission]
  defp apply_omission(tokens, omission) do
    tokens_with_omission = tokens |> List.first |> String.rstrip |> Kernel.<> omission
    List.replace_at(tokens, 0, tokens_with_omission)
  end

  defp close_remaining_tags(tokens, state = %{open_tags: open_tags}) do
    closing_tags = Enum.map(open_tags, &Html.matching_close_tag/1) |> Enum.reverse
    output = closing_tags ++ tokens |> Enum.reverse |> Enum.join

    state |> Map.put(:close_tags, closing_tags) |> Map.put(:output, output)
  end

  defp finalize_output(%{output: output, opts: %{word_boundary: word_boundary}, close_tags: close_tags}) do
    if word_boundary do
      {:ok, r } = Regex.compile("^.*#{Regex.source(word_boundary)}")
      match = Regex.scan(r, output) |> Enum.at(0, []) |> List.first
    end

    cond do
      match && match != output ->
        match <> Enum.join(close_tags)
      true ->
        output
    end
  end
end
