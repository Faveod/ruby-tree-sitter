# Unit testing

Since we don't have languages bundled in ruby gems, we have to load the dynamic
libraries from disk. Make sure to run `bin/setup` which uses
[`tsdl`](https://github.com/stackmystack/tsdl).

Since not all languages have a Makefile in their root dir, and we don't want to
mess with copying Makefiles, we're going to rely on languages that do have a
Makefile in their root.

So for the time being we're sticking with `ruby`.

We might need to change this strategy in the future if we're to test some
multilang parsing.
