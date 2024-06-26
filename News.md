# News

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
