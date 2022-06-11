#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cNode;

DATA_WRAP(cNode, TSNode, node)

static VALUE node_type(VALUE self) {
  node_t *node = unwrap(self);
  return rb_str_new_cstr(ts_node_type(node->data));
}

static VALUE node_symbol(VALUE self) {
  node_t *node = unwrap(self);

  return INT2NUM(ts_node_symbol(node->data));
}

static VALUE node_start_byte(VALUE self) {
  node_t *node = unwrap(self);

  return INT2NUM(ts_node_start_byte(node->data));
}

static VALUE node_start_point(VALUE self) {
  node_t *node = unwrap(self);
  TSPoint point = ts_node_start_point(node->data);

  return new_point(&point);
}

static VALUE node_end_byte(VALUE self) {
  node_t *node = unwrap(self);

  return INT2NUM(ts_node_end_byte(node->data));
}

static VALUE node_end_point(VALUE self) {
  node_t *node = unwrap(self);
  TSPoint point = ts_node_end_point(node->data);

  return new_point(&point);
}

static VALUE node_string(VALUE self) {
  node_t *node = unwrap(self);

  return rb_str_new_cstr(ts_node_string(node->data));
}

static VALUE node_is_null(VALUE self) {
  node_t *node = unwrap(self);

  return ts_node_is_null(node->data) ? Qtrue : Qfalse;
}

static VALUE node_is_named(VALUE self) {
  node_t *node = unwrap(self);

  return ts_node_is_named(node->data) ? Qtrue : Qfalse;
}

static VALUE node_is_missing(VALUE self) {
  node_t *node = unwrap(self);

  return ts_node_is_missing(node->data) ? Qtrue : Qfalse;
}

static VALUE node_is_extra(VALUE self) {
  node_t *node = unwrap(self);

  return ts_node_is_extra(node->data) ? Qtrue : Qfalse;
}

static VALUE node_has_changes(VALUE self) {
  node_t *node = unwrap(self);

  return ts_node_has_changes(node->data) ? Qtrue : Qfalse;
}

static VALUE node_has_error(VALUE self) {
  node_t *node = unwrap(self);

  return ts_node_has_error(node->data) ? Qtrue : Qfalse;
}

static VALUE node_parent(VALUE self) {
  node_t *node = unwrap(self);
  TSNode parent = ts_node_parent(node->data);

  return new_node(&parent);
}

static VALUE node_child(VALUE self, VALUE index) {
  node_t *node = unwrap(self);
  uint32_t idx = NUM2INT(index);
  TSNode child = ts_node_child(node->data, idx);

  return new_node(&child);
}

static VALUE node_field_name_for_child(VALUE self, VALUE index) {
  node_t *node = unwrap(self);
  uint32_t idx = NUM2INT(index);
  const char *name = ts_node_field_name_for_child(node->data, idx);
  if (name == NULL) {
    return Qnil;
  } else {
    return rb_str_new_cstr(name);
  }
}

static VALUE node_child_count(VALUE self) {
  node_t *node = unwrap(self);

  return INT2NUM(ts_node_child_count(node->data));
}

static VALUE node_named_child(VALUE self, VALUE index) {
  node_t *node = unwrap(self);
  uint32_t idx = NUM2INT(index);
  TSNode child = ts_node_named_child(node->data, idx);

  return new_node(&child);
}

static VALUE node_named_child_count(VALUE self) {
  node_t *node = unwrap(self);

  return INT2NUM(ts_node_named_child_count(node->data));
}

static VALUE node_child_by_field_name(VALUE self, VALUE field_name) {
  node_t *node = unwrap(self);
  const char *name = StringValuePtr(field_name);
  uint32_t length = (uint32_t)RSTRING_LEN(field_name);
  TSNode child = ts_node_child_by_field_name(node->data, name, length);

  return new_node(&child);
}

static VALUE node_child_by_field_id(VALUE self, VALUE field_id) {
  node_t *node = unwrap(self);
  uint16_t id = (uint16_t)NUM2INT(field_id);
  TSNode child = ts_node_child_by_field_id(node->data, id);

  return new_node(&child);
}

static VALUE node_next_sibling(VALUE self) {
  node_t *node = unwrap(self);
  TSNode sibling = ts_node_next_sibling(node->data);

  return new_node(&sibling);
}

static VALUE node_prev_sibling(VALUE self) {
  node_t *node = unwrap(self);
  TSNode sibling = ts_node_prev_sibling(node->data);

  return new_node(&sibling);
}

static VALUE node_next_named_sibling(VALUE self) {
  node_t *node = unwrap(self);
  TSNode sibling = ts_node_next_named_sibling(node->data);

  return new_node(&sibling);
}

static VALUE node_prev_named_sibling(VALUE self) {
  node_t *node = unwrap(self);
  TSNode sibling = ts_node_prev_named_sibling(node->data);

  return new_node(&sibling);
}

static VALUE node_first_child_for_byte(VALUE self, VALUE byte) {
  node_t *node = unwrap(self);
  uint32_t b = NUM2INT(byte);
  TSNode child = ts_node_first_child_for_byte(node->data, b);

  return new_node(&child);
}

static VALUE node_first_named_child_for_byte(VALUE self, VALUE byte) {
  node_t *node = unwrap(self);
  uint32_t b = NUM2INT(byte);
  TSNode child = ts_node_first_named_child_for_byte(node->data, b);

  return new_node(&child);
}

static VALUE node_descendant_for_byte_range(VALUE self, VALUE from, VALUE to) {
  node_t *node = unwrap(self);
  uint32_t f = NUM2INT(from);
  uint32_t t = NUM2INT(to);
  TSNode child = ts_node_descendant_for_byte_range(node->data, f, t);

  return new_node(&child);
}

static VALUE node_descendant_for_point_range(VALUE self, VALUE from, VALUE to) {
  node_t *node = unwrap(self);
  TSPoint f = value_to_point(from);
  TSPoint t = value_to_point(to);
  TSNode child = ts_node_descendant_for_point_range(node->data, f, t);

  return new_node(&child);
}

static VALUE node_named_descendant_for_byte_range(VALUE self, VALUE from,
                                                  VALUE to) {
  node_t *node = unwrap(self);
  uint32_t f = NUM2INT(from);
  uint32_t t = NUM2INT(to);
  TSNode child = ts_node_named_descendant_for_byte_range(node->data, f, t);

  return new_node(&child);
}

static VALUE node_named_descendant_for_point_range(VALUE self, VALUE from,
                                                   VALUE to) {
  node_t *node = unwrap(self);
  TSPoint f = value_to_point(from);
  TSPoint t = value_to_point(to);
  TSNode child = ts_node_named_descendant_for_point_range(node->data, f, t);

  return new_node(&child);
}

static VALUE node_edit(VALUE self, VALUE input_edit) {
  node_t *node = unwrap(self);
  TSInputEdit in = value_to_input_edit(input_edit);

  ts_node_edit(&node->data, &in);

  return Qnil;
}

static VALUE node_eq(VALUE self, VALUE other) {
  node_t *node = unwrap(self);
  node_t *edon = unwrap(other);
  return ts_node_eq(node->data, edon->data) ? Qtrue : Qfalse;
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
  rb_define_method(cNode, "string", node_string, 0);
  rb_define_method(cNode, "to_s", node_string, 0);
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
  rb_define_method(cNode, "edit", node_edit, 1);
  rb_define_method(cNode, "eq?", node_eq, 1);
}
