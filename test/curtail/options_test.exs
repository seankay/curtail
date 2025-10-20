defmodule Curtail.OptionsTest do
  use ExUnit.Case

  alias Curtail.Options

  test "creating options" do
    options = Options.new
    assert %Regex{source: "\\S"} = options.word_boundary
    assert options.omission == "..."
    assert options.length == 100
    assert options.break_token == nil
  end

  test "uses default word_boundary when word_boundary is `true`" do
    assert %Regex{source: "\\S"} = Options.new([word_boundary: true]).word_boundary
  end

  test "overriding default options" do
    assert Options.new(omission: "!").omission == "!"
  end
end
