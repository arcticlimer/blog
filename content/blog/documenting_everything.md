---
date: 2022-07-24
title: Documenting Stuff
---

Recently I've been thinking about why usually my projects or codebases at work
doesn't have per-function/class documentation or type specs. This seems tricky
to answer: we just need to write above the function what it does, right?

So why is this not happening? I personally don't know. I want to read more about
documentation per se to have a more solid base on the subject, but right now
thinking about it we probably spend much more time tweaking and reading our
functions than we'd spent adding documentation to it.

I'm now planning to code in a more thoughtful way and try to always document my
code when relevant, e.g: public interface of Elixir modules.

```elixir
defmodule MyModule do
  @moduledoc "This modules explains how to properly document Elixir APIs"

  @spec public_api :: String.t()
  @doc "Returns a string that ensures this function is documented."
  def public_api do
    secret_function()
    "hey, I'm documented!"
  end

  # This doesn't need any comments, since it's
  # private API subject to change
  defp secret_function do
    nil
  end
end
```
