# Ruby-Specific API

This is not a comprehensive list, but a curated list of examples to showcase the ruby-specific API.

## IMPORTANT

As of today, there's a
[bug](https://github.com/tree-sitter/tree-sitter/issues/1642) in `tree-sitter`
that prevents correct access to a node's child `field_name` correctly.

Keep that in mind while reading the next sections.

## Node

For a give parse tree, that looks something like:

```
(method name: (identifier) parameters: (method_parameters (identifier) (identifier)) ...
```

We're oftern interested in accessing the children `name` and `parameters` field names.
Unnamed children usually represent tokens of syntax. If you're writing a syntax highlighter,
then yes this is very important. But if you're producing an AST from the parse tree, then
you're more interested in the named children which are usually attached to fields.

### Iterating over children

It's often more interesting to iterate over named node so:

``` ruby
node.each do |field, child|
  puts "#{field}: #{child}"
end

# => name: (identifier)
# => parameters: (method_parameters ...
```

Will iterate through named childs, and send back the attached field name.

See: `each_child`, `each_named_child`.

### Accessing children by field name

You can call `[]` or just `node.field_name`; we use `mehod_missing` to allow you
to access a `child_by_field_name` to enable the latter syntax.

``` ruby
node[:name] # or even
node.name
```

