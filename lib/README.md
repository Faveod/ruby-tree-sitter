# Ruby-Specific API

This is not a comprehensive list, but a curated list of examples to showcase the
ruby-specific API.

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

We're oftern interested in accessing the children `name` and `parameters` field
names.  Unnamed children usually represent tokens of syntax. If you're writing a
syntax highlighter, then yes this is very important. But if you're producing an
AST from the parse tree, then you're more interested in the named children which
are _usually attached to fields_.

### Iterating over children
You can use vanilla `each` to iterate over all childre, with no distinction
between named or anonymous one.

It's often more interesting to iterate over named nodes, so use `each_named` for that.

``` ruby
node.each do |c| ... end
node.each_named do |c| ... end
```

You can also iterate of children attached to fields with `each_fields`.

``` ruby
node.each_field do |f, c| ... end
```

The difference between a named child and a field is that the former is the
result of a named rule in the grammar while the latter is an explicit field
inside the AST (that the grammar tags as a field).

### Accessing children by field name

You can call `[]` or just `node.field_name`; we use `mehod_missing` to allow you
to access a `child_by_field_name` to enable the latter syntax.

``` ruby
node[:name] # or even
node.name
```

### Pattern matching

Sometimes it's nice to do:

``` ruby
a, b, c = *node
```

Here, the splat operator will return all the children.

But what's more intersting is to be able to dig a children by keys.

``` ruby
a, b = node.fetch(:lhs, :rhs)
```

