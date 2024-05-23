# Ruby tree-sitter bindings

[![docs](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/publish-docs.yml/badge.svg)](https://faveod.github.io/ruby-tree-sitter)
[![rubygems.org](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/publish.yml/badge.svg)](https://rubygems.org/gems/ruby_tree_sitter)
[![ci](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/ci.yml/badge.svg)](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/ci.yml)
<!--
[![valgrind](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/valgrind.yml/badge.svg)](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/valgrind.yml)
[![asan/ubsan](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/asan.yml/badge.svg)](https://github.com/Faveod/ruby-tree-sitter/actions/workflows/asan.yml)
-->

Ruby bindings for [tree-sitter](https://github.com/tree-sitter/tree-sitter).

The [official bindings](https://github.com/tree-sitter/ruby-tree-sitter) are
very old, unmaintained, and don't work with modern `tree-sitter` APIs.


## Usage

### TreeSitter API

The TreeSitter API is a low-level Ruby binding for tree-sitter.

``` ruby
require 'tree_sitter'

parser = TreeSitter::Parser.new
language = TreeSitter::Language.load('javascript', 'path/to/libtree-sitter-javascript.{so,dylib}')

src = "[1, null]"

parser.language = language

tree = parser.parse_string(nil, src)
root = tree.root_node

root.each do |child|
  # ...
end
```

The main philosophy behind the TreeSitter bindings is to do a 1:1 mapping between
tree-sitter's `C` API and `Ruby`, which makes it easier to experiment and port
ideas from different languages/bindings.

But it feels like writing some managed `C` with `Ruby`, and that's why we provide
a high-level API ([TreeStand](#treestand-api)) as well.

### TreeStand API

The TreeStand API is a high-level Ruby wrapper for the [TreeSitter](#treesitter-api) bindings. It
makes it easier to configure the parsers, and work with the underlying syntax tree.
```ruby
require 'tree_stand'

TreeStand.configure do
  config.parser_path = "path/to/parser/folder/"
end

sql_parser = TreeStand::Parser.new("sql")
ruby_parser = TreeStand::Parser.new("ruby")
```

TreeStand provides an idiomatic Ruby interface to work with tree-sitter parsers.

## Dependencies

This gem is a binding for `tree-sitter`. It doesn't have a version of
`tree-sitter` baked in it by default.

You must install `tree-sitter` and make sure that their dynamic library is
accessible from `$PATH`, or build the gem with `--disable-sys-libs`, which will
download the latest tagged `tree-sitter` and build against it (see [Build from source](docs/Contributing.md#build-from-source) .)

You can either install `tree-sitter` from source or through your go-to package manager.

### Linux

`ubuntu >= 22.04`

```console
sudo apt install libtree-sitter-dev
```

`arch`

```console
sudo pacman -S tree-sitter
```

### MacOS

```console
sudo port install tree-sitter
```

or

```console
brew install tree-sitter
```

## Install

From [rubygems](https://rubygems.org/gems/ruby_tree_sitter), in your `Gemfile`:

```ruby
gem 'ruby_tree_sitter', '~> 1.0'
```

Or manually:

```sh
gem install ruby_tree_sitter
```

Or from `git` sources, which will compile on installation:

```ruby
gem 'ruby_tree_sitter', git: 'https://github.com/Faveod/ruby-tree-sitter'
```

### Disable system libraries

To install with `--disable-sys-lib`, you can either:

```sh
gem install ruby_tree_sitter -- --disable-sys-libs
```

Or via bundle:

```sh
bundle config set build.ruby_tree_sitter --disable-sys-libs
```

### No compilation

If you don't want to install from `rubygems`, `git`, or if you don't want to
compile on install, then download a native gem from this repository's
[releases](https://github.com/Faveod/ruby-tree-sitter/releases), or you can
compile it yourself (see [Build from source](docs/Contributing.md#build-from-source) .)

In that case, you'd have to point your `Gemfile` to the `gem` as such:

``` ruby
gem 'tree_sitter', path: 'path/to/native/tree_sitter.gem'
```

⚠️ We're currently missing a lot of platforms and architectures. Cross-build
will come back in the near future.

### Parsers

You will have to install parsers yourself, either by:

1. Downloading and building from source.
1. Downloading from your package manager, if available.
1. Downloading a pre-built binary from
   [Faveod/tree-sitter-parsers](https://github.com/Faveod/tree-sitter-parsers)
   which supports numerous architectures.

### A note on static vs dynamic linking

This extension will statically link against a downloaded version of
`tree-sitter` when you use the `--disable-sys-lib`.  So any installed version of
`tree-sitter` will not be loaded.

The native gems are also statically linked.

All other methods will dynamically link against the installed `tree-sitter`.

## Examples

See `examples` directory.

## Development

See [`docs/Contributing.md`](docs/Contributing.md).

## 🚧 👷‍♀️ Notes 👷 🚧

Since we're doing a 1:1 mapping between the `tree-sitter` API and the bindings,
you need to be extra-careful when playing with the provided objects.  Some of
them have their underlying `C` data-structure automatically freed, so you might
get yourself in undesirable situations if you don't pay attention to what you're
doing.

We're only talking about `Tree`, `TreeCursor`, `Query`, and `QueryCursor`.  Just
don't copy them left and right, and then expect them to work without
`SEGFAULT`ing and creating a black-hole in your living-room.  Assume that you
have to work locally with them. If you get a `SEGFAULT`, you can debug the
native `C` code using `gdb`.  You can read more on `SEGFAULT`s
[here](docs/SIGSEGV.md), and debugging [here](docs/Contributing#Debugging.md).

That said, we do aim at providing an idiomatic `Ruby` interface.  It should also
provide a _safer_ interface, where you don't have to worry about when and how
resources are freed.

To See a full list of the ruby-specific APIs, see [here](lib/README.md).

## Sponsors

<img src="img/faveod.jpg" width="75%">
