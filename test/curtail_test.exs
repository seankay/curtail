defmodule CurtailTest do
  use ExUnit.Case
  import Curtail
  doctest Curtail

  test "properly uses default options when option is not passed in" do
    string = "<p>this is a test!</p>"

    assert truncate(string) == string
  end

  test "return empty string when length provided is less than or equal to 0" do
    string = "test"
    result = ""

    assert truncate(string, length: 0) == result
    assert truncate(string, length: -1) == result
  end

  test "truncates string based on length" do
    string = "<p>This <a href=\"http://example.com\">link</a> is a test link</p>"
    result = "<p>This <a href=\"http://example.com\">...</a></p>"

    assert truncate(string, length: 10) == result
  end

  test "correctly truncates string with html comments" do
    string = "<h1>hello <!-- stuff --> and <!-- la --> goodbye</h1>"
    result = "<h1>hello <!-- stuff --> and <!-- la -->...</h1>"

    assert truncate(string, length: 15) == result
  end

  test "uses overriden omission" do
    string = "<p>This is a test</p>"
    result = "<p>This is a.</p>"

    assert truncate(string, length: 10, omission: ".") == result
  end

  test "truncates to the exact length specified when word_boundary is set to false" do
    html = "<div>123456789</div>"
    result = "<div>12345</div>"

    assert truncate(html, length: 5, omission: "", word_boundary: false) == result
  end

  test "retains the tags within the text when word_boundary is set to false" do
    html = "some text <span class=\"caps\">CAPS</span> some text"
    result = "some text <span class=\"caps\">CAPS</span> some te..."

    assert truncate(html, length: 25, word_boundary: false) == result
  end

  test "retains the omission text when word_boundary is false" do
    html = "testtest"
    result = "testt.."

    assert truncate(html, length: 7, omission: "..", word_boundary: false) == result
  end

  test "handles multibyte characters when word_boundary is false" do
    html = "prüfenprüfen"
    result = "prüfen.."

    assert truncate(html, length: 8, omission: "..", word_boundary: false) == result
  end

  test "truncates using the default word_boundary option when word_boundary is true" do
    html = "hello there. or maybe not?"
    result = "hello there. or"

    assert truncate(html, length: 16, omission: "", word_boundary: true) == result
  end

  test "truncates to the end of the nearest sentence when word_boundary is custom" do
    html = "hello there. or maybe not?"
    result = "hello there."

    assert truncate(html, length: 16, omission: "", word_boundary: ~r/\S[\.\?\!]/) == result
  end

  test "is respectful of closing tags when word_boundary is custom" do
    html = "<p>hmmm this <em>should</em> be okay. I think...</p>"
    result = "<p>hmmm this <em>should</em> be okay.</p>"

    assert truncate(html, length: 28, omission: "", word_boundary: ~r/\S[\.\?\!]/) == result
  end

  test "includes the omission text's length in the returned truncated html" do
    html = "a b c"
    result = "a..."

    assert truncate(html, length: 4, omission: "...") == result
  end

  test "includes omission even on the edge" do
    result = "One two t..."
    html = "One two three"

    assert truncate(html, word_boundary: false, length: 12) == result
  end

  test "never returns a string longer than length" do
    assert truncate("test this stuff", length: 10) == "test..."
  end

  test "returns the omission when the specified length is smaller than the omission" do
    assert truncate("a b c", length: 2, omission: "...") == "..."
  end

  test "treats script tags as strings with no length" do
    html   = "<p>I have a script <script type = text/javascript>document.write('lum dee dum');</script> and more text</p>"
    result = "<p>I have a script <script type = text/javascript>document.write('lum dee dum');</script> and...</p>"
    assert truncate(html, length: 23) == result
  end

  test "in the middle of a link, truncates and closes the <a>, and closes any remaining open tags" do
    html     = "<div><ul><li>Look at <a href = \"foo\">this</a> link </li></ul></div>"
    result = "<div><ul><li>Look at <a href = \"foo\">this...</a></li></ul></div>"
    assert truncate(html, length: 15) == result
  end

  test "places the punctuation after the tag without any whitespace when character is after closing tag" do
    punctuations = ["!", "@","#","$","%","^","&","*","\(","\)","-","_","+",
      "=","[","]","{","}","\\","|",",",".","/","?"]

    Enum.each(punctuations, fn(char) ->
      html     = "<p>Look at <strong>this</strong>#{char} More words here</p>"
      result = "<p>Look at <strong>this</strong>#{char}...</p>"
      assert truncate(html, length: 19) == result
    end)
  end

   test "leaves a whitespace between the closing tag and the following word character when html has non-punctuation char after closing tag" do
     html = "<p>Look at <a href = \"awesomeful.net\">this</a> link for randomness</p>"
     result = "<p>Look at <a href = \"awesomeful.net\">this</a> link...</p>"
     assert truncate(html, length: 21) == result
   end

   test "handles multibyte characters and leaves them in the result" do
     html = "<p>Look at our multibyte characters ā ž <a href = \"awesomeful.net\">this</a> link for randomness ā ž</p>"
     assert truncate(html, length: String.length(html)) == html
   end

   test "recognizes the multiline html properly" do
     html = "<div id=\"foo\"
     class=\"bar\">
     This is ugly html.
     </div>"
     result = "<div id=\"foo\" class=\"bar\"> This is...</div>"
     assert truncate(html, length: 12) == result
   end

   test "if html contains unpaired tag and unpaired tag does not have closing slash it does not close the unpaired tag" do
     unpaired_tags = ["br", "hr", "img"]

     Enum.each(unpaired_tags, fn(unpaired_tag) ->
       html      = "<div>Some before. <#{unpaired_tag}>and some after</div>"
       html_caps = "<div>Some before. <#{unpaired_tag}>and some after</div>"
       assert truncate(html, length: 19) == "<div>Some before. <#{unpaired_tag}>and...</div>"
       assert truncate(html_caps, length: 19) == "<div>Some before. <#{unpaired_tag}>and...</div>"
     end)
   end

   test "if html contains unpaired tag and unpaired tag does have closing slash it does not close the unpaired tag" do
     unpaired_tags = ["br", "hr", "img"]
     Enum.each(unpaired_tags, fn(unpaired_tag) ->
       html      = "<div>Some before. <#{unpaired_tag} />and some after</div>"
       html_caps = "<div>Some before. <#{unpaired_tag} />and some after</div>"
       assert truncate(html, length: 19) == "<div>Some before. <#{unpaired_tag} />and...</div>"
       assert truncate(html_caps, length: 19) == "<div>Some before. <#{unpaired_tag} />and...</div>"
     end)
   end

  test "does not truncate quotes off when input contains chinese characters" do
    html = "<p>“我现在使用的是中文的拼音。”<br>
    测试一下具体的truncate<em>html功能。<br>
    “我现在使用的是中文的拼音。”<br>
    测试一下具体的truncate</em>html功能。<br>
    “我现在使用的是中文的拼音。”<br>
    测试一下具体的truncate<em>html功能。<br>
    “我现在使用的是中文的拼音。”<br>
    测试一下具体的truncate</em>html功能。</p>"

    result = truncate(html, omission: "", length: 50)
    assert String.contains?(result, "<p>“我现在使用的是中文的拼音。”<br>") == true
  end

  test "does not truncate abnormally if the break_token is not present" do
    assert truncate("This is line one. This is line two.", length: 30, break_token: "foobar") == "This is line one. This is..."
    assert truncate("This is line one. This is line two.", length: 30, break_token: "<break />") == "This is line one. This is..."
    assert truncate("This is line one. This is line two.", length: 30, break_token: "<!-- truncate -->") == "This is line one. This is..."
    assert truncate("This is line one. This is line two.", length: 30, break_token: "<!-- break -->") == "This is line one. This is..."
  end

  test "does not truncate abnormally if the break_token is present, but beyond the length param" do
    assert truncate("This is line one. This is line foobar two.", length: 30, break_token: "foobar") == "This is line one. This is..."
    assert truncate("This is line one. This is line <break /> two.", length: 30, break_token: "<break />") == "This is line one. This is..."
    assert truncate("This is line one. This is line <!-- truncate --> two.", length: 30, break_token: "<!-- truncate -->") == "This is line one. This is..."
    assert truncate("This is line one. This is line <!-- break --> two.", length: 30, break_token: "<!-- break -->") == "This is line one. This is..."
  end

  test "truncates before the length param if the break_token is before the token at length" do
    assert truncate("This is line one. foobar This is line two.", length: 30, break_token: "foobar") == "This is line one."
    assert truncate("This is line one. <break /> This is line two.", length: 30, break_token: "<break />") == "This is line one."
    assert truncate("This is line one. <!-- truncate --> This is line two.", length: 30, break_token: "<!-- truncate -->") == "This is line one."
    assert truncate("This is line one. <!-- break --> This is line two.", length: 30, break_token: "<!-- break -->") == "This is line one."
  end

  test "does not duplicate comments" do
    string = "<h1>hello <!-- stuff --> and <!-- la --> goodbye</h1>"
    result = "<h1>hello <!-- stuff --> and <!-- la -->...</h1>"
    assert truncate(string, length: 15) == result
  end

  test "only applies omission when truncation necessary" do
    string = "no truncation"
    assert truncate(string, length: String.length(string) + 1) == string
  end
end
