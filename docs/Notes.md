# Notes

## Sanitizing

To enable compilation with ASAN do:

```console
SANITIZE=1 rake compile
```

And then make sure to build the gem and install it:

```console
gem build tree_sitter.gemspec
gem install tree_sitter-version.gem
```

And finally you can launch it:

1. On Mac OSX:

```console
DYLD_INSERT_LIBRARIES=/full/path/to/asan /full/path/to/ruby ...
```

2. On Linux:
```console
LD_LOAD=/full/path/to/asan /full/path/to/ruby ...
```

It's very important to specify the full path to the ruby executable, otherswise
ASAN will fail to load.

To get the full address of LLVM's ASAN:

1. On Mac OSX:

```console
clang -print-file-name=libclang_rt.asan_osx_dynamic.dylib
```

2. On Linux:

```console
TODO
```
