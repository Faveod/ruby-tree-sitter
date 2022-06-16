#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cNode;

DATA_WRAP(Node, node)

static VALUE node_type(VALUE self) { return safe_str(ts_node_type(SELF)); }

static VALUE node_symbol(VALUE self) { return UINT2NUM(ts_node_symbol(SELF)); }

static VALUE node_start_byte(VALUE self) {
  return UINT2NUM(ts_node_start_byte(SELF));
}

static VALUE node_start_point(VALUE self) {
  return new_point_by_val(ts_node_start_point(SELF));
}

static VALUE node_end_byte(VALUE self) {
  return UINT2NUM(ts_node_end_byte(SELF));
}

static VALUE node_end_point(VALUE self) {
  return new_point_by_val(ts_node_end_point(SELF));
}

static VALUE node_string(VALUE self) {
  char *str = ts_node_string(SELF);
  VALUE res = safe_str(str);
  free(str);
  return res;
}

static VALUE node_is_null(VALUE self) {
  return ts_node_is_null(SELF) ? Qtrue : Qfalse;
}

static VALUE node_is_named(VALUE self) {
  return ts_node_is_named(SELF) ? Qtrue : Qfalse;
}

static VALUE node_is_missing(VALUE self) {
  return ts_node_is_missing(SELF) ? Qtrue : Qfalse;
}

static VALUE node_is_extra(VALUE self) {
  return ts_node_is_extra(SELF) ? Qtrue : Qfalse;
}

static VALUE node_has_changes(VALUE self) {
  return ts_node_has_changes(SELF) ? Qtrue : Qfalse;
}

static VALUE node_has_error(VALUE self) {
  return ts_node_has_error(SELF) ? Qtrue : Qfalse;
}

static VALUE node_parent(VALUE self) {
  return new_node_by_val(ts_node_parent(SELF));
}

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

static VALUE node_field_name_for_child(VALUE self, VALUE idx) {
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

static VALUE node_child_count(VALUE self) {
  return UINT2NUM(ts_node_child_count(SELF));
}

static VALUE node_named_child(VALUE self, VALUE idx) {
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

static VALUE node_named_child_count(VALUE self) {
  return UINT2NUM(ts_node_named_child_count(SELF));
}

static VALUE node_child_by_field_name(VALUE self, VALUE field_name) {
  const char *name = StringValuePtr(field_name);
  uint32_t length = (uint32_t)RSTRING_LEN(field_name);
  return new_node_by_val(ts_node_child_by_field_name(SELF, name, length));
}

static VALUE node_child_by_field_id(VALUE self, VALUE field_id) {
  return new_node_by_val(ts_node_child_by_field_id(SELF, NUM2UINT(field_id)));
}

static VALUE node_next_sibling(VALUE self) {
  return new_node_by_val(ts_node_next_sibling(SELF));
}

static VALUE node_prev_sibling(VALUE self) {
  return new_node_by_val(ts_node_prev_sibling(SELF));
}

static VALUE node_next_named_sibling(VALUE self) {
  return new_node_by_val(ts_node_next_named_sibling(SELF));
}

static VALUE node_prev_named_sibling(VALUE self) {
  return new_node_by_val(ts_node_prev_named_sibling(SELF));
}

static VALUE node_first_child_for_byte(VALUE self, VALUE byte) {
  return new_node_by_val(ts_node_first_child_for_byte(SELF, NUM2UINT(byte)));
}

static VALUE node_first_named_child_for_byte(VALUE self, VALUE byte) {
  return new_node_by_val(
      ts_node_first_named_child_for_byte(SELF, NUM2UINT(byte)));
}

static VALUE node_descendant_for_byte_range(VALUE self, VALUE from, VALUE to) {
  uint32_t from_b = NUM2UINT(from);
  uint32_t to_b = NUM2UINT(to);

  if (from_b < to_b) {
    rb_raise(rb_eIndexError, "From < To: %d < %d", from_b, to_b);
  } else {
    return new_node_by_val(
        ts_node_descendant_for_byte_range(SELF, from_b, to_b));
  }
}

static VALUE node_descendant_for_point_range(VALUE self, VALUE from, VALUE to) {
  return new_node_by_val(ts_node_descendant_for_point_range(
      SELF, value_to_point(from), value_to_point(to)));
}

static VALUE node_named_descendant_for_byte_range(VALUE self, VALUE from,
                                                  VALUE to) {
  uint32_t from_b = NUM2UINT(from);
  uint32_t to_b = NUM2UINT(to);

  if (from_b < to_b) {
    rb_raise(rb_eIndexError, "From < To: %d < %d", from_b, to_b);
  } else {
    return new_node_by_val(
        ts_node_named_descendant_for_byte_range(SELF, from_b, to_b));
  }
}

static VALUE node_named_descendant_for_point_range(VALUE self, VALUE from,
                                                   VALUE to) {
  return new_node_by_val(ts_node_named_descendant_for_point_range(
      SELF, value_to_point(from), value_to_point(to)));
}

static VALUE node_edit(VALUE self, VALUE input_edit) {
  TSNode node = SELF;
  TSInputEdit edit = value_to_input_edit(input_edit);
  ts_node_edit(&node, &edit);

  return Qnil;
}

static VALUE node_eq(VALUE self, VALUE other) {
  return ts_node_eq(SELF, unwrap(other)->data) ? Qtrue : Qfalse;
}

void init_node(void) {
  cNode = rb_define_class_under(mTreeSitter, "Node", rb_cObject);

  /* Class methods */
  rb_define_method(cNode, "type", node_type, 0);
  rb_define_method(cNode, "symbol", node_symbol, 0);
  rb_define_method(cNode, "start_byte", node_start_byte, 0);
  rb_define_method(cNode, "start_point", node_start_point, 0);
  rb_define_method(cNode, "end_byte", node_end_byte, 0);
  rb_define_method(cNode, "end_point", node_end_point, 0);
  rb_define_method(cNode, "null?", node_is_null, 0);
  rb_define_method(cNode, "named?", node_is_named, 0);
  rb_define_method(cNode, "missing?", node_is_missing, 0);
  rb_define_method(cNode, "extra?", node_is_extra, 0);
  rb_define_method(cNode, "changes?", node_has_changes, 0);
  rb_define_method(cNode, "error?", node_has_error, 0);
  rb_define_method(cNode, "parent", node_parent, 0);
  rb_define_method(cNode, "child", node_child, 1);
  rb_define_method(cNode, "field_name_for_child", node_field_name_for_child, 1);
  rb_define_method(cNode, "child_count", node_child_count, 0);
  rb_define_method(cNode, "named_child", node_named_child, 1);
  rb_define_method(cNode, "named_child_count", node_named_child_count, 0);
  rb_define_method(cNode, "child_by_field_name", node_child_by_field_name, 1);
  rb_define_method(cNode, "child_by_field_id", node_child_by_field_id, 1);
  rb_define_method(cNode, "next_sibling", node_next_sibling, 0);
  rb_define_method(cNode, "prev_sibling", node_prev_sibling, 0);
  rb_define_method(cNode, "next_named_sibling", node_next_named_sibling, 0);
  rb_define_method(cNode, "prev_named_sibling", node_prev_named_sibling, 0);
  rb_define_method(cNode, "first_child_for_byte", node_first_child_for_byte, 1);
  rb_define_method(cNode, "first_named_child_for_byte",
                   node_first_named_child_for_byte, 1);
  rb_define_method(cNode, "descendant_for_byte_range",
                   node_descendant_for_byte_range, 2);
  rb_define_method(cNode, "descendant_for_point_range",
                   node_descendant_for_point_range, 2);
  rb_define_method(cNode, "named_descendant_for_byte_range",
                   node_named_descendant_for_byte_range, 2);
  rb_define_method(cNode, "named_descendant_for_point_range",
                   node_named_descendant_for_point_range, 2);
  rb_define_method(cNode, "eq?", node_eq, 1);
  rb_define_method(cNode, "edit", node_edit, 1);
  rb_define_method(cNode, "to_s", node_string, 0);
  rb_define_method(cNode, "to_str", node_string, 0);
  rb_define_method(cNode, "inspect", node_string, 0);
  rb_define_method(cNode, "==", node_eq, 1);
}
