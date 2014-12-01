defmodule Curtail.HtmlTagTest do
  use ExUnit.Case
  import Curtail.Html

  test "html tag" do
    assert tag?("<p>") == true
    assert tag?("</p>") == true
    assert tag?("<!--comment-->") == false
  end

  test "html comment" do
    assert comment?("<!--comment-->") == true
    assert comment?("</p>") == false
  end

  test "open tag" do
    assert open_tag?("<p>") == true
    assert open_tag?("</p>") == false
    assert open_tag?("<br>") == false
    assert open_tag?("<img>") == false
    assert open_tag?("<hr>") == false
  end

  test "finds matching close tag" do
    assert matching_close_tag("<p>") == "</p>"
  end

  test "checking matching close tag" do
    assert matching_close_tag?("<p>", "</p>") == true
    assert matching_close_tag?("<p>", "</h1>") == false
  end
end
