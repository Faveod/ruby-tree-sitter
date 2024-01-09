# Contributting to tree-sitter

If you want to hack on this gem, please follow [Build from
Source](#build-from-source), and then you only have to work with `rake compile`
and `rake clean`.

It's advised to run `bundle rake clean compile` everytime you modify `C` code.
We've run into trouble several times by not doing so.

You can jump into a REPL and start experimenting with:

```sh
bundle exec rake console
```

## Build from source

### Dependencies

To work on this gem you'll need the tree-sitter CLI tool. See the [offical
documentation](https://github.com/tree-sitter/tree-sitter/blob/master/cli/README.md#tree-sitter-cli) for installation
instructions.

Clone the repository and run the setup script.

### Clone and Build
```sh
git clone https://github.com/Faveod/ruby-tree-sitter
bin/setup
```

If you chose not to bother with `tree-sitter` installation:

```sh
bundle exec rake compile -- --disable-sys-libs
```

## Testing

```
bundle exec rake test
```

## Typechecking

```
bundle exec srb tc
```

## Documentation

To run the documentation server, execute the following command and open [localhost:8808](http://localhost:8808).

```
bundle exec yard server --reload
```

To get statistics about documentation coverage and which items are missing documentation run the following command.

```
bundle exec yard stats --list-undoc
# Example output:
#
# Files:          10
# Modules:         2 (    0 undocumented)
# Classes:        11 (    0 undocumented)
# Constants:       1 (    0 undocumented)
# Attributes:     14 (    0 undocumented)
# Methods:        34 (    0 undocumented)
#  100.00% documented
```

## Pushing a new Version

Create a new PR to bump the version number in `lib/tree_sitter/version.rb`.

Once that PR is merged, tag the latest commit with the format `v#{TreeSitter::VERSION}` and push the new tag.

```sh
git tag v1.0.0
git push --tags
```

Draft a new Release [on Github](https://github.com/Faveod/ruby-tree-sitter/releases).

## Advanced topics

⚠️  ASAN and Valgrind are not currently passing the CI, but maybe they would on your local machine.

### Native gems

To produce a gem that compiles on installation:

```sh
rake gem
```

To produce a native gem, which will not compile on installation:

```sh
rake native gem
```

### ASAN

You can enable `asan` by setting the `SANITIZE` environment variable before building:

```sh
SANITIZE=address,undefined bundle exec rake compile
```

On linux:

```sh
LD_PRELOAD=libasan.so.6 bundle exec rake test
```

If you're on a mac, or if you don't want to have a headache running `asan`
locally, you can run `asan` in the provided docker image:

```sh
./bin/memcheck address,undefined
```

The [dockerfile](../docker/asan.dockerfile) contains more details on how to
set-up `asan` and filter out the noise.

### Valgrind

If you're on linux, you can simply run:

```sh
bundle exec rake test:valgrind
```

Which will run the tests with `valgrind` and report any memory leaks.

If you're on a mac, or if you don't want to install `valgrind` locally, you can run
`valgrind` in the provided docker image:

```sh
./bin/memcheck valgrind
```

The [dockerfile](../docker/valgrind.dockerfile) contains more details.

### Debugging

If you have issues in `ruby` code, use `rdbg` (from
[ruby/debug](https://github.com/ruby/debug) .)

But if you're running into trouble with the `C` bindings, which usually
manifests itself as a `SEGFAULT`, you can debug using `gdb` (more details in
this [blogpost](https://blog.wataash.com/ruby-c-extension/))

1. Install ruby with sources:

```sh
rbenv install --keep --verbose 3.1.2
```

2. Launch `gdb`:

```sh
bundle exec gdb -q -ex 'set breakpoint pending on' -ex 'b node_string' -ex run --args ruby examples/01-json.rb
```

This will stop at calls of `node_string` from `C` sources (in
`ext/tree_sitter/node.c`).

If you want to stop at a location causing a `SEGFAULT`, add `-ex 'handle SIGSEGV stop nopass'`.

**NOTE**: following the same instructions for `lldb` on `macos` doesn't work. We
will update this section if we figured it out.
