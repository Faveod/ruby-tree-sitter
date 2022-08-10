# Development

If you want to hack on this gem, please follow [Build from
Source](#build-from-source), and then you only have to work with `rake compile`
and `rake clean`.

It's advised to run `bundle rake clean compile` everytime you modify `C` code.
We've run into trouble several times by not doing so.

You can jump into a REPL and start experimenting with:

```console
bundle exec rake console
```

### Build from source

```console
git clone https://github.com/Faveod/ruby-tree-sitter
bundle install
bundle exec rake compile
```

If you chose not to bother with `tree-sitter` installation:

``` console
bundle exec rake compile -- --disable-sys-libs
```

### Native gems

To produce a gem that compiles on installation:

``` console
rake gem
```

To produce a native gem, which will not compile on installation:

``` console
rake native gem
```

### ASAN

You can enable `asan` by setting the `SANITIZE` environment variable before building:

```console
SANITIZE=1 bundle exec rake compile
```

On linux:

``` console
LD_PRELOAD=libasan.so.6 bundle exec rake test
```

### Valgrind

If you're on linux, you can simply run:

```console
bundle exec rake test:valgrind
```

Which will run the tests with valgrind and report any memory leaks.

If you're on a mac, or if you don't want to install valgrind locally, you can run
valgrind in the provided docker image:

```console
./bin/valgrind
```

### Debugging

If you have issues in `ruby` code, use `rdbg` (from
[ruby/debug](https://github.com/ruby/debug) .)

But if you're running into trouble with the `C` bindings, which usually
manifests itself as a `SEGFAULT`, you can debug using `gdb` (more details in
this [blogpost](https://blog.wataash.com/ruby-c-extension/))

1. Install ruby with sources:

``` console
rbenv install --keep --verbose 3.1.2
```

2. Launch `gdb`:

``` console
bundle exec gdb -q -ex 'set breakpoint pending on' -ex 'b node_string' -ex run --args ruby examples/01-json.rb
```

This will stop at calls of `node_string` from `C` sources (in
`ext/tree_sitter/node.c`).

If you want to stop at a location causing a `SEGFAULT`, add `-ex 'handle SIGSEGV stop nopass'`.

**NOTE**: following the same instructions for `lldb` on `macos` doesn't work. We
will update this section if we figured it out.
