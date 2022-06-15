# Notes

## Missing features

1. TSInput:
   It's implemented, alongside `ts_parser_pasrse`, and the latter will call a
   read function (with the appropriate signature) inside the passed object, but
   we haven't implemented anything yet that is usefule.  We need to have it in
   the test suite when done.

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
