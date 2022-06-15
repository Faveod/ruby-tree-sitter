# Examples

## Run

From the project root:

```console
bundle exec ruby examples/01-json.rb
```

## Setup

These examples are meant to showcase the use of the API.

They will not work on your local installation directly because we require
loading of dynamic libraries from explicit files on the disk.

The way this happens now is by calling `bin/get json`, for example, which clones
and installs the json parser inside `tree-sitter-parsers` directory.

However, the json parser doesn't come with a make file, so the script will fail.

## Hack #1

A current hack would be to copy a makefile from the parser for
[`ruby`](https://github.com/tree-sitter/tree-sitter-ruby/blob/master/Makefile)
and putting it in the root of the json dir.

This is what I do for my local testing.

This needs to be changed so that the dynamic libraries make part of an external
gem, exactly like they do for `rust` and `node` (e.g. `tree_sitter_json`) which
we can require and work with without worrying about building the parsers.

## Hack #2

Edit the scripts and call 

```ruby
language = load(name, lib)
```

Where `lib` points directly to the dynamic library, i.e. your local build for
your local parser.
