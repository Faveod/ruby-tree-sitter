#include "tree_sitter.h"
#include "tree_sitter/api.h"

extern VALUE mTreeSitter;

VALUE cNode;

DATA_TYPE(TSNode, node)

static void node_free(void *ptr) {
  node_t *type = (node_t *)ptr;
  tree_rc_free(type->data.tree);
  xfree(ptr);
}

DATA_MEMSIZE(node)
DATA_DECLARE_DATA_TYPE(node)
DATA_ALLOCATE(node)
DATA_UNWRAP(node)

VALUE new_node(const TSNode *ptr) {
  if (ptr == NULL) {
    return Qnil;
  }
  VALUE res = node_allocate(cNode);
  node_t *type = unwrap(res);
  type->data = *ptr;
  tree_rc_new(type->data.tree);
  return res;
}
VALUE new_node_by_val(TSNode ptr) {
  VALUE res = node_allocate(cNode);
  node_t *type = unwrap(res);
  type->data = ptr;
  tree_rc_new(type->data.tree);
  return res;
}

DATA_FROM_VALUE(TSNode, node)

/**
 * Check if two nodes are identical.
 *
 * @param other [Node]
 *
 * @return [Boolean]
 */
static VALUE node_eq(VALUE self, VALUE other) {
  return ts_node_eq(SELF, unwrap(other)->data) ? Qtrue : Qfalse;
}

/**
 * Get an S-expression representing the node as a string.
 *
 * @return [String]
 */
static VALUE node_string(VALUE self) {
  char *str = ts_node_string(SELF);
  VALUE res = safe_str(str);
  if (str) {
    free(str);
  }
  return res;
}

/**
 * Check if a syntax node has been edited.
 *
 * @return [Boolean]
 */
static VALUE node_has_changes(VALUE self) {
  return ts_node_has_changes(SELF) ? Qtrue : Qfalse;
}

/**
 * Check if the node is a syntax error or contains any syntax errors.
 *
 * @return [Boolean]
 */
static VALUE node_has_error(VALUE self) {
  return ts_node_has_error(SELF) ? Qtrue : Qfalse;
}

/**
 * Check if the node is a syntax error.
 *
 * @return [Boolean]
 */
VALUE node_is_error(VALUE self) {
  return ts_node_is_error(SELF) ? Qtrue : Qfalse;
}

/**
 * Check if the node is *named*. Named nodes correspond to named rules in the
 * grammar, whereas *anonymous* nodes correspond to string literals in the
 * grammar.
 *
 * @return [Boolean]
 */
static VALUE node_is_named(VALUE self) {
  return ts_node_is_named(SELF) ? Qtrue : Qfalse;
}

/**
 * Check if the node is null. Functions like {Node#child} and
 * {Node#next_sibling} will return a null node to indicate that no such node
 * was found.
 *
 * @return [Boolean]
 */
static VALUE node_is_null(VALUE self) {
  return ts_node_is_null(SELF) ? Qtrue : Qfalse;
}

/**
 * Check if the node is *extra*. Extra nodes represent things like comments,
 * which are not required the grammar, but can appear anywhere.
 *
 * @return [Boolean]
 */
static VALUE node_is_extra(VALUE self) {
  return ts_node_is_extra(SELF) ? Qtrue : Qfalse;
}
/**
 * Check if the node is *missing*. Missing nodes are inserted by the parser in
 * order to recover from certain kinds of syntax errors.
 *
 * @return [Boolean]
 */
static VALUE node_is_missing(VALUE self) {
  return ts_node_is_missing(SELF) ? Qtrue : Qfalse;
}

/**
 * Get the node's child at the given index, where zero represents the first
 * child.
 *
 * @raise [IndexError] if out of range.
 *
 * @return [Node]
 */
static VALUE node_child(VALUE self, VALUE idx) {
  TSNode node = SELF;
  uint32_t index = NUM2UINT(idx);
  uint32_t range = ts_node_child_count(node);

  if (index < range) {
    return new_node_by_val(ts_node_child(node, index));
  } else {
    rb_raise(rb_eIndexError, "Index %d is out of range (len = %d)", index,
             range);
  }
}

/**
 * Get the node's child with the given numerical field id.
 *
 * You can convert a field name to an id using {Language#field_id_for_name}.
 *
 * @return [Node]
 */
static VALUE node_child_by_field_id(VALUE self, VALUE field_id) {
  return new_node_by_val(ts_node_child_by_field_id(SELF, NUM2UINT(field_id)));
}

/**
 * Get the node's child with the given field name.
 *
 * @param field_name [String]
 *
 * @return [Node]
 */
static VALUE node_child_by_field_name(VALUE self, VALUE field_name) {
  const char *name = StringValuePtr(field_name);
  uint32_t length = (uint32_t)RSTRING_LEN(field_name);
  return new_node_by_val(ts_node_child_by_field_name(SELF, name, length));
}

/**
 * Get the node's number of children.
 *
 * @return [Integer]
 */
static VALUE node_child_count(VALUE self) {
  TSNode node = SELF;
  const char *type = ts_node_type(node);
  if (strcmp(type, "end") == 0) {
    return UINT2NUM(0);
  } else {
    return UINT2NUM(ts_node_child_count(SELF));
  }
}

/**
 * Get the node's number of descendants, including one for the node itself.
 *
 * @return [Integer]
 */
VALUE node_descendant_count(VALUE self) {
  return UINT2NUM(ts_node_descendant_count(SELF));
}

/**
 * Get the smallest node within this node that spans the given range of byte
 * positions.
 *
 * @raise [IndexError] if out of range.
 *
 * @param from [Integer]
 * @param to   [Integer]
 *
 * @return [Node]
 */
static VALUE node_descendant_for_byte_range(VALUE self, VALUE from, VALUE to) {
  uint32_t from_b = NUM2UINT(from);
  uint32_t to_b = NUM2UINT(to);

  if (from_b > to_b) {
    rb_raise(rb_eIndexError, "From > To: %d > %d", from_b, to_b);
  } else {
    return new_node_by_val(
        ts_node_descendant_for_byte_range(SELF, from_b, to_b));
  }
}

/**
 * Get the smallest node within this node that spans the given range of
 * (row, column) positions.
 *
 * @raise [IndexError] if out of range.
 *
 * @param from [Point]
 * @param to   [Point]
 *
 * @return [Node]
 */
static VALUE node_descendant_for_point_range(VALUE self, VALUE from, VALUE to) {
  TSNode node = SELF;
  TSPoint start = ts_node_start_point(node);
  TSPoint end = ts_node_end_point(node);
  TSPoint f = value_to_point(from);
  TSPoint t = value_to_point(to);

  if ((f.row < start.row) || (t.row > end.row) ||
      (f.row == start.row && (f.column < start.column)) ||
      (t.row == end.row && (t.column > end.column))) {
    rb_raise(rb_eIndexError,
             "Invalid point range: [%+" PRIsVALUE ", %+" PRIsVALUE
             "] is not in [%+" PRIsVALUE ", %+" PRIsVALUE "].",
             from, to, new_point(&start), new_point(&end));
  } else {
    return new_node_by_val(ts_node_descendant_for_point_range(node, f, t));
  }
}

/**
 * Edit the node to keep it in-sync with source code that has been edited.
 *
 * This function is only rarely needed. When you edit a syntax tree with the
 * {Tree#edit} function, all of the nodes that you retrieve from the tree
 * afterward will already reflect the edit. You only need to use {Node#edit}
 * when you have a {Node} instance that you want to keep and continue to use
 * after an edit.
 *
 * @param input_edit [InputEdit]
 *
 * @return [nil]
 */
static VALUE node_edit(VALUE self, VALUE input_edit) {
  TSNode node = SELF;
  TSInputEdit edit = value_to_input_edit(input_edit);
  ts_node_edit(&node, &edit);

  return Qnil;
}

/**
 * Get the node's end byte.
 *
 * @return [Integer]
 */
static VALUE node_end_byte(VALUE self) {
  return UINT2NUM(ts_node_end_byte(SELF));
}

/**
 * Get the node's end position in terms of rows and columns.
 *
 * @return [Point]
 */
static VALUE node_end_point(VALUE self) {
  return new_point_by_val(ts_node_end_point(SELF));
}

/**
 * Get the field name for node's child at the given index, where zero represents
 * the first child.
 *
 * @raise [IndexError] if out of range.
 *
 * @return [String]
 */
static VALUE node_field_name_for_child(VALUE self, VALUE idx) {
  // FIXME: the original API returns nil if no name was found, but I made it
  // raise an exception like `node_child` for consistency. The latter was made
  // this way to avoid segfault. Should we absolutely stick to the original API?
  TSNode node = SELF;
  uint32_t index = NUM2UINT(idx);
  uint32_t range = ts_node_child_count(node);

  if (index < range) {
    return safe_str(ts_node_field_name_for_child(node, index));
  } else {
    rb_raise(rb_eIndexError, "Index %d is out of range (len = %d)", index,
             range);
  }
}

/**
 * Get the node's first child that extends beyond the given byte offset.
 *
 * @param byte [Integer]
 *
 * @return [Node]
 */
static VALUE node_first_child_for_byte(VALUE self, VALUE byte) {
  return new_node_by_val(ts_node_first_child_for_byte(SELF, NUM2UINT(byte)));
}

/**
 * Get the node's first named child that extends beyond the given byte offset.
 *
 * @param byte [Integer]
 *
 * @return [Node]
 */
static VALUE node_first_named_child_for_byte(VALUE self, VALUE byte) {
  return new_node_by_val(
      ts_node_first_named_child_for_byte(SELF, NUM2UINT(byte)));
}

/**
 * Get the node's type as a numerical id as it appears in the grammar ignoring
 * aliases. This should be used in {Language#next_state} instead of
 * {Node#symbol}.
 *
 * @return [Integer]
 */
VALUE node_grammar_symbol(VALUE self) {
  return UINT2NUM(ts_node_grammar_symbol(SELF));
}

/**
 * Get the node's type as it appears in the grammar ignoring aliases as a
 * null-terminated string.
 *
 * @return String
 */
VALUE node_grammar_type(VALUE self) {
  return safe_str(ts_node_grammar_type(SELF));
}

/**
 * Get the node's language.
 *
 * @return [Language]
 */
static VALUE node_language(VALUE self) {
  return new_language(ts_node_language(SELF));
}

/**
 * Get the smallest *named* node within this node that spans the given range of
 * byte positions.
 *
 * @raise [IndexError] if out of range.
 *
 * @param from [Integer]
 * @param to   [Integer]
 *
 * @return [Node]
 */
static VALUE node_named_descendant_for_byte_range(VALUE self, VALUE from,
                                                  VALUE to) {
  uint32_t from_b = NUM2UINT(from);
  uint32_t to_b = NUM2UINT(to);

  if (from_b > to_b) {
    rb_raise(rb_eIndexError, "From > To: %d > %d", from_b, to_b);
  } else {
    return new_node_by_val(
        ts_node_named_descendant_for_byte_range(SELF, from_b, to_b));
  }
}

/**
 * Get the smallest *named* node within this node that spans the given range of
 * (row, column) positions.
 *
 * @raise [IndexError] if out of range.
 *
 * @param from [Point]
 * @param to   [Point]
 *
 * @return [Node]
 */
static VALUE node_named_descendant_for_point_range(VALUE self, VALUE from,
                                                   VALUE to) {
  TSNode node = SELF;
  TSPoint start = ts_node_start_point(node);
  TSPoint end = ts_node_end_point(node);
  TSPoint f = value_to_point(from);
  TSPoint t = value_to_point(to);

  if ((f.row < start.row) || (t.row > end.row) ||
      (f.row == start.row && (f.column < start.column)) ||
      (t.row == end.row && (t.column > end.column))) {
    rb_raise(rb_eIndexError,
             "Invalid point range: [%+" PRIsVALUE ", %+" PRIsVALUE
             "] is not in [%+" PRIsVALUE ", %+" PRIsVALUE "].",
             from, to, new_point(&start), new_point(&end));
  } else {
    return new_node_by_val(
        ts_node_named_descendant_for_point_range(node, f, t));
  }
}

/**
 * Get the node's *named* child at the given index.
 *
 * @see named?
 *
 * @param idx [Integer]
 *
 * @raise [IndexError] if out of range.
 *
 * @return [Node]
 */
static VALUE node_named_child(VALUE self, VALUE idx) {
  // FIXME: see notes in `node_field_name_for_child`
  TSNode node = SELF;
  uint32_t index = NUM2UINT(idx);
  uint32_t range = ts_node_named_child_count(node);

  if (index < range) {
    return new_node_by_val(ts_node_named_child(node, index));
  } else {
    rb_raise(rb_eIndexError, "Index %d is out of range (len = %d)", index,
             range);
  }
}

/**
 * Get the node's number of *named* children.
 *
 * @see named?
 *
 * @return [Integer]
 */
static VALUE node_named_child_count(VALUE self) {
  return UINT2NUM(ts_node_named_child_count(SELF));
}

/**
 * Get the node's next *named* sibling.
 *
 * @return [Node]
 */
static VALUE node_next_named_sibling(VALUE self) {
  return new_node_by_val(ts_node_next_named_sibling(SELF));
}

/**
 * Get the node's next sibling.
 *
 * @return [Node]
 */
static VALUE node_next_sibling(VALUE self) {
  return new_node_by_val(ts_node_next_sibling(SELF));
}

/**
 * Get the parse state after this node.
 *
 * @return [Integer]
 */
VALUE node_next_parse_state(VALUE self) {
  return UINT2NUM(ts_node_next_parse_state(SELF));
}

/**
 * Get the node's immediate parent.
 *
 * @return [Node]
 */
static VALUE node_parent(VALUE self) {
  return new_node_by_val(ts_node_parent(SELF));
}

/**
 * Get the node's previous *named* sibling.
 *
 * @return [Node]
 */
static VALUE node_prev_named_sibling(VALUE self) {
  return new_node_by_val(ts_node_prev_named_sibling(SELF));
}

/**
 * Get the node's previous sibling.
 *
 * @return [Node]
 */
static VALUE node_prev_sibling(VALUE self) {
  return new_node_by_val(ts_node_prev_sibling(SELF));
}

/**
 * Get the node's start byte.
 *
 * @return [Integer]
 */
static VALUE node_start_byte(VALUE self) {
  return UINT2NUM(ts_node_start_byte(SELF));
}

/**
 * Get the node's start position in terms of rows and columns.
 *
 * @return [Point]
 */
static VALUE node_start_point(VALUE self) {
  return new_point_by_val(ts_node_start_point(SELF));
}

/**
 * Get this node's parse state.
 *
 * @return [Integer]
 */
VALUE node_parse_state(VALUE self) {
  return UINT2NUM(ts_node_parse_state(SELF));
}

/**
 * Get the node's type as a numerical id.
 *
 * @return [Integer]
 */
static VALUE node_symbol(VALUE self) { return UINT2NUM(ts_node_symbol(SELF)); }

/**
 * Get the node's type as a null-terminated string.
 *
 * @return [Symbol]
 */
static VALUE node_type(VALUE self) { return safe_symbol(ts_node_type(SELF)); }

void init_node(void) {
  cNode = rb_define_class_under(mTreeSitter, "Node", rb_cObject);

  rb_undef_alloc_func(cNode);

  /* Builtins */
  rb_define_method(cNode, "eq?", node_eq, 1);
  rb_define_method(cNode, "to_s", node_string, 0);
  rb_define_method(cNode, "to_str", node_string, 0);
  rb_define_method(cNode, "inspect", node_string, 0);
  rb_define_method(cNode, "==", node_eq, 1);

  /* Class methods */
  // Predicates
  rb_define_method(cNode, "changed?", node_has_changes, 0);
  rb_define_method(cNode, "error?", node_is_error, 0);
  rb_define_method(cNode, "has_error?", node_has_error, 0);
  rb_define_method(cNode, "missing?", node_is_missing, 0);
  rb_define_method(cNode, "named?", node_is_named, 0);
  rb_define_method(cNode, "null?", node_is_null, 0);
  rb_define_method(cNode, "extra?", node_is_extra, 0);

  // Other
  rb_define_method(cNode, "child", node_child, 1);
  rb_define_method(cNode, "child_by_field_id", node_child_by_field_id, 1);
  rb_define_method(cNode, "child_by_field_name", node_child_by_field_name, 1);
  rb_define_method(cNode, "child_count", node_child_count, 0);
  rb_define_method(cNode, "descendant_count", node_descendant_count, 0);
  rb_define_method(cNode, "descendant_for_byte_range",
                   node_descendant_for_byte_range, 2);
  rb_define_method(cNode, "descendant_for_point_range",
                   node_descendant_for_point_range, 2);
  rb_define_method(cNode, "edit", node_edit, 1);
  rb_define_method(cNode, "end_byte", node_end_byte, 0);
  rb_define_method(cNode, "end_point", node_end_point, 0);
  rb_define_method(cNode, "field_name_for_child", node_field_name_for_child, 1);
  rb_define_method(cNode, "first_child_for_byte", node_first_child_for_byte, 1);
  rb_define_method(cNode, "first_named_child_for_byte",
                   node_first_named_child_for_byte, 1);
  rb_define_method(cNode, "grammar_symbol", node_grammar_symbol, 0);
  rb_define_method(cNode, "grammar_type", node_grammar_type, 0);
  rb_define_method(cNode, "language", node_language, 0);
  rb_define_method(cNode, "named_child", node_named_child, 1);
  rb_define_method(cNode, "named_child_count", node_named_child_count, 0);
  rb_define_method(cNode, "named_descendant_for_byte_range",
                   node_named_descendant_for_byte_range, 2);
  rb_define_method(cNode, "named_descendant_for_point_range",
                   node_named_descendant_for_point_range, 2);
  rb_define_method(cNode, "next_named_sibling", node_next_named_sibling, 0);
  rb_define_method(cNode, "next_parse_state", node_next_parse_state, 0);
  rb_define_method(cNode, "next_sibling", node_next_sibling, 0);
  rb_define_method(cNode, "parent", node_parent, 0);
  rb_define_method(cNode, "parse_state", node_parse_state, 0);
  rb_define_method(cNode, "prev_named_sibling", node_prev_named_sibling, 0);
  rb_define_method(cNode, "prev_sibling", node_prev_sibling, 0);
  rb_define_method(cNode, "start_byte", node_start_byte, 0);
  rb_define_method(cNode, "start_point", node_start_point, 0);
  rb_define_method(cNode, "symbol", node_symbol, 0);
  rb_define_method(cNode, "type", node_type, 0);
}
