# News

# [unreleaseed]

# v1.11.1 (02-01-2025)

- Fix:
  - precompiled gem problem with ruby 3.3. See [rake-compiler-dock](https://github.com/rake-compiler/rake-compiler-dock/blob/3811c31917a9dcb9cb139c0841f420c82663ae89/History.md?plain=1#L35)
  - tree-sitter version: we declared v0.24.6, but we were on v0.24.5!

# v1.11.0 (02-01-2025)

- Use tree-sitter v0.24.6.
- Added new `rbts` executable to aide with writing tree-sitter query's. It will watch a source & query file then print the match & capture nodes to the screen. See `rbts --help` for more details.
- TreeSitter: better erorr message in `Node#[]`.
- Cross-Compile:
  - build native ruby 3.4 gems.
  - restore cross-compilation tests.
- TreeSitter|TreeStand: add `Node#sexpr`. It's a better alternative to
  tree-sitter's native `ts_node_string` which can always be reached via
  `Node#to_s` or `Node#to_string`. For instance, for the expression `1 + x * 3`,
  `ts_node_string` always prints:
  ```
    (expression (sum left: (number) right: (product left: (variable) right: (number))))
  ```
  `Node#sexpr` is still capable of doing the same, but if we do
  `node.sexpr(width: 40)` we get:
  ```
    (expression
      (sum
        left: (number)
        (+)
        right:
          (product
            left: (variable)
            (*)
          right: (number))))"
  ```
  We can even print the named leaf nodes:
  ```
    (expression           |
      (sum                |
        left:             |
          (number)        | 1
        (+)               | +
        right:            |
          (product        |
            left:         |
              (variable)  | x
            (*)           | *
            right:        |
              (number)))) | 3
  ```

# v1.10.0 (10-12-2024)

- Make `TreeSitter::TreeSitterError < Exception` instead of `StandardErorr`;
  we don't want them to be handled by default `rescue`.

# v1.9.1 (05-12-2024)

- Add custom errors for language loading:
  ```md
  - LanguageLoadError
  - ParserNotFoundError
  - ParserVersionError
  - SymbolNotFoundError
  ```
- Add custom `QueryCreationError` for query creation.

# v1.9.0 (21-11-2024)

- Use tree-sitter v0.24.4.

# v1.8.0 (06-11-2024)

- Use tree-sitter v0.24.3.

# v1.7.0

- Use tree-sitter v0.23.0.

# v1.6.0

- Cross-compilation is now working for most targets:
  + `aarch64-linux-gnu`
  + `aarch64-linux-musl`
  + `arm-linux-gnu`
  + `arm-linux-musl`
  + `x86_64-linux-gnu`
  + `x86_64-linux-musl`
  + `x86-linux-musl`
  + `arm64-darwin`
  + `x86_64-darwin`
  We now produce fat native gems so you don't have to install tree-sitter on your machine,
  and not even compile it if you don't need to.

# v1.5.1

- Language loading, e.g. `TreeSitter.lang`, is now case insensitive for path lookup only:
  loading `TreeStand.lang('COBOL')` will look for the correct `COBOL` symbol in the parser,
  wheter it's stored in `cobol.so`, `COBOL.so`, etc.
- Fixed a bug that caused an exception when reporting an exception in language loading.

# v1.5.0

- Cross-compilation support is dropped because it doesn't work with `--disable-sys-lib`.
  We need a better understanding of rake-compiler-dock and rake-compiler.
  _v1.4.2 is especially broken_.
  **Skip all v1.4**.

# v1.4.2

- Remove sorbet's `T.unsafe`. This prevented `TreeSitter.language` to function outside of `TreeStand`.
# v1.4.1

v1.4.0 had issues publishing to [rubygems.org](https://rubygems.org/gems/ruby_tree_sitter).

This version is identical to the previous one.

# v1.4.0

- `TreeSitter::Node` is enumerable.
- `TreeSitter::{QueryCaptures, QueryMatches}` are enumerable.
- `TreeStand::Node` now supports query predicates from `TreeSitter`.
- `TreeSitter::QueryMatches` now has a `each_capture_hash` method returning an `Enumerator<Hash<String, Node>>`,
  the rough equivalent of what `TreeStand::Node#query` returns.
- TreeSitter and TreeStand now share the same parser (`dylib` or `so`) loading mechanism:
  - `TreeSitter.language('language')` or `TreeSitter.lang('language')`
  - `TreeStand::Parser.new('language')`

# v1.3.0

- Query Predicates landed. See https://tree-sitter.github.io/tree-sitter/using-parsers#predicates.

# v1.2.0

## TreeSitter

- `Node#field?` accepts symbols and strings.
- `Node#child_by_filed_name`
  - no longer SEGFAULTs when the field name does not exist, returning `nil` instead.
  - accepts symbols and strings.
- `fetch` is `fetch_all` now, and `fetch_all` is removed. The API was confusing at best.

## TreeStand

- `Parser.language`
  - Automatic loading of parsers if installed on the system, or in a local `tree-sitter-parsers` directory.
  - Handle mac and linux (dylib and so).
- Expose more thing from `TreeSitter::Node` to `TreeStand::Node`, notably:
  ```
  # TreeStand      TreeSitter
    []             []
    fetch          fetch
    field          child_by_field_name
    fields         each_field
    named          each_named
    next           next_sibling
    prev           prev_sibling
    next_named     next_named_sibling
    prev_named     prev_named_sibling
    field_names    fields
  ```
- `Node#text` now correctly fetches the text according to byte ranges.

# v1.1.0

- Support for v0.20.9.

## v1.0.0

- Support for v0.20.9.
- Integration of the TreeStand gem https://github.com/Shopify/tree_stand/.
- [Derek Stride](https://github.com/DerekStride/) joins as maintainer.

## v0.20.8.2

1. When you use `--disable-sys-lib` this extension will:
  1. download `tree-sitter` via `git`, `curl`, or `wget`.
  1. statically link against downloaded `tree-sitter`.
1. The native gems are also statically linked.

With static linking, any installed version of `tree-sitter` will not be loaded.

All other methods will dynamically link against the installed `tree-sitter`.
