# Notes

## Missing

1. Logger support. Don't use methods that do logging for now.

## Tree-Sitter API

We provide direct translation for tree-sitter's `C` public API.

Pros: No hidden functionality. Ruby code can be a direct translation of `C`
code.

Cons: Performance.

Some of the APIs return `C` structs and we do a `C -> Ruby` struct conversion
(copying).  However, these objects will be useful on other parts of the API
where they need to be consumed.  This requires another conversion `Ruby -> C`.

One notable example is the `Range` class and
`ts_included_ranges`/`ts_set_includedranges`. The getter returns an array of
`Range`, and the setter sets another one.

In our bindings, the getter will copy the `C` API `TSRange` struct data into the
binding's `range_t` struct.  The setter, will ask the bindings to copy `range_t`
struct data into `TSRange`.

While This seems inefficient, this allows for better flexibility when
experimenting with the API in `Ruby`.

If performance turns out to be an issue (for example in some hot-loops), then
the logci needs to be implemented in the extension, and using tree-sitter's `C`
API directly.
