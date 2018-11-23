Curtail
=======
[![Build Status](https://travis-ci.org/seankay/curtail.svg?branch=master)](https://travis-ci.org/seankay/curtail)

HTML tag safe string truncation.

Port of the [html_truncate](https://github.com/hgmnz/truncate_html) gem.

Installation
=====

```elixir
def deps do
  [ {:curtail, "~> 1.0"} ]
end
```

Usage
======

### Options
    * length (default: 100)
    * omission (default: "...")
    * word_boundary (default: "~r/\S/")
    * break_token (default: nil)

Truncate using default options:
```elixir
  iex> Curtail.truncate("<p>Truncate me!</p>")
  "<p>Truncate me!</p>"

```
Truncate with custom length:
```elixir
  iex> Curtail.truncate("<p>Truncate me!</p>", length: 12)
  "<p>Truncate...</p>"
```

Truncate without omission string:
```elixir
iex> Curtail.truncate("<p>Truncate me!</p>", omission: "", length: 8)
"<p>Truncate</p>"
```

Truncate with custom word_boundary:
```elixir
iex> Curtail.truncate("<p>Truncate. Me!</p>", word_boundary: ~r/\S[\.]/, length: 12, omission: "")
"<p>Truncate.</p>"
```

Truncate without word boundary:
```elixir
iex> Curtail.truncate("<p>Truncate me</p>", word_boundary: false, length: 7)
"<p>Trun...</p>"
```

Truncate with custom break_token:
```elixir
iex> Curtail.truncate("<p>This should be truncated here<break_here>!!</p>", break_token: "<break_here>")
"<p>This should be truncated here</p>"
```

License
=======
Released under [MIT License.](http://opensource.org/licenses/MIT)
