# News

## next

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
