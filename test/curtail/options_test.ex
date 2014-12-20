defmodule Curtail.HtmlTagTest do
  use ExUnit.Case

  import Curtail.Options
  alias Curtail.Options

  test "creating options" do
    assert Options.new == %Options{}
  end

  test "uses default word_boundary when word_boundary is `true`" do
    assert Options.new([word_boundary: true]).word_boundary == ~r/\S/
  end

  test "overriding default options" do
    assert Options.new(omission: "!").omission == "!"
  end
end
