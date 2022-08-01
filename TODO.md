# TODO

1. Iterate on named children
   - I decided not to include names with `each_named_children` iterator for two
     main reasons:
     1. It's consitent with `each_children`
     1. It `field_name` has nothing to do with `named_children`.  It looks like
        a named children is one that has a named rule in the grammar, and a
        field is a literal field in the AST, so you can get into situations
        where you ask for `field_name` for a `named_child(x)`, and it will be
        `null`.
     For both those reasons, and to avoid further confusion, we'll keep it this
     way.
1. Pattern-matching:
   - deconstruct for `children`
   - deconstruct for `named_children`
