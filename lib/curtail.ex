defmodule Curtail do
  @moduledoc ~S"""
  # An HTML-safe string truncator

  ## Usage
      Curtail.truncate("<p>Truncate me</p>", options)
  """

  @regex ~r/(?:<script.*>.*<\/script>)+|<\/?[^>]+>|[a-z0-9\|`~!@#\$%^&*\(\)\-_\+=\[\]{}:;'²³§",\.\/?]+|\s+|[[:punct:]]|\X/xiu

  alias Curtail.Html
  alias Curtail.Options

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
  def truncate(string, opts \\ [])
  def truncate(_string, length: length) when length <= 0, do: ""
  def truncate(string, opts) do
    opts = Options.new(opts)

    tokens = Regex.scan(@regex, string)
              |> List.flatten
              |> Enum.map(fn(match) ->
                match
                |> String.replace(~r/\n/, " ")
                |> String.replace(~r/\s+/, " ")
              end)

    chars_remaining = opts.length - String.length(opts.omission)

    do_truncate(tokens, %Html{}, opts, chars_remaining, [])
  end

  defp do_truncate([_token|_rest], tags, opts, chars_remaining, acc) when chars_remaining <= 0 do
    do_truncate([], tags, opts, 0, acc)
  end

  defp do_truncate([token|_rest], tags, opts = %Options{break_token: break_token}, _, acc)
    when break_token == token do
    finalize_output(acc, tags, opts)
  end

  defp do_truncate([], tags, opts, chars_remaining, acc) when chars_remaining > 0 do
    finalize_output(acc, tags, opts)
  end

  defp do_truncate([], tags, opts, _, acc) do
    acc |> apply_omission(opts.omission) |> finalize_output(tags, opts)
  end

  defp do_truncate([token | rest], tags, opts, chars_remaining, acc) do
    acc = cond do
      Html.tag?(token) || Html.comment?(token) ->
        [token | acc]
      opts.word_boundary ->
        case (chars_remaining - String.length(token)) >= 0 do
          true ->[token | acc]
          false -> acc
        end
      true ->
        [String.slice(token, 0..chars_remaining - 1) | acc]
    end

    cond do
      Html.tag?(token) ->
        tags = case Html.open_tag?(token) do
          true -> %Html{tags | open_tags: [token | tags.open_tags]}
          false -> remove_latest_open_tag(token, tags)
        end
      !Html.comment?(token) ->
        chars_remaining = case opts.word_boundary do
          false ->
            chars_remaining - (String.slice(token, 0..chars_remaining - 1) |> String.length)
          _ ->
            chars_remaining - String.length(token)
        end
      true ->
        nil #noop
    end

    do_truncate(rest, tags, opts, chars_remaining, acc)
  end

  defp remove_latest_open_tag(close_tag, tags = %Html{open_tags: open_tags}) do
    case Enum.find_index(open_tags, &(Html.matching_close_tag?(&1, close_tag))) do
      nil -> tags
      index -> %Html{tags | open_tags: List.delete_at(open_tags, index)}
    end
  end

  defp apply_omission([], nil), do: [""]
  defp apply_omission([], omission), do: [omission]
  defp apply_omission(tokens, omission) do
    tokens_with_omission = tokens
                            |> List.first
                            |> String.rstrip
                            |> Kernel.<>(omission)

    List.replace_at(tokens, 0, tokens_with_omission)
  end

  defp apply_word_boundary(output, false), do: output
  defp apply_word_boundary(output, word_boundary) do
    {:ok, r } = Regex.compile("^.*#{Regex.source(word_boundary)}")
    Regex.scan(r, output) |> Enum.at(0, []) |> List.first
  end

  defp finalize_output(tokens, %Html{open_tags: open_tags}, %Options{word_boundary: word_boundary}) do
    closing_tags = open_tags
                    |> Enum.map(&Html.matching_close_tag/1)
                    |> Enum.reverse

    output = (closing_tags ++ tokens) |> Enum.reverse |> Enum.join

    case apply_word_boundary(output, word_boundary) do
      nil -> output
      match when match != output -> match <> Enum.join(closing_tags)
      _ -> output
    end
  end
end
