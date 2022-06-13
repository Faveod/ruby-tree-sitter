#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTreeCursor;

DATA_WRAP(TreeCursor, tree_cursor)

static VALUE tree_cursor_initialize(VALUE self, VALUE node) {
  TSNode n = value_to_node(self);
  tree_cursor_t *ptr = unwrap(self);
  ptr->data = ts_tree_cursor_new(n);
  return self;
}

static VALUE tree_cursor_reset(VALUE self, VALUE node) {
  TSNode n = value_to_node(self);
  ts_tree_cursor_reset(&SELF, n);
  return Qnil;
}

static VALUE tree_cursor_current_node(VALUE self) {
  TSNode node = ts_tree_cursor_current_node(&SELF);
  return new_node(&node);
}

static VALUE tree_cursor_current_field_name(VALUE self) {
  return safe_str(ts_tree_cursor_current_field_name(&SELF));
}

static VALUE tree_cursor_current_field_id(VALUE self) {
  return INT2NUM(ts_tree_cursor_current_field_id(&SELF));
}

static VALUE tree_cursor_goto_parent(VALUE self) {
  return ts_tree_cursor_goto_parent(&SELF) ? Qtrue : Qfalse;
}

static VALUE tree_cursor_goto_next_sibling(VALUE self) {
  return ts_tree_cursor_goto_next_sibling(&SELF) ? Qtrue : Qfalse;
}

static VALUE tree_cursor_goto_first_child(VALUE self) {
  return ts_tree_cursor_goto_first_child(&SELF) ? Qtrue : Qfalse;
}

static VALUE tree_cursor_goto_first_child_for_byte(VALUE self, VALUE byte) {
  return LL2NUM(ts_tree_cursor_goto_first_child_for_byte(&SELF, NUM2INT(byte)));
}

static VALUE tree_cursor_goto_first_child_for_point(VALUE self, VALUE point) {
  return LL2NUM(
      ts_tree_cursor_goto_first_child_for_point(&SELF, value_to_point(point)));
}

static VALUE tree_cursor_copy(VALUE self) {
  VALUE res = tree_cursor_allocate(cTreeCursor);
  tree_cursor_t *ptr = unwrap(res);
  ptr->data = ts_tree_cursor_copy(&SELF);
  return res;
}

void init_tree_cursor(void) {
  cTreeCursor = rb_define_class_under(mTreeSitter, "TreeCursor", rb_cObject);

  rb_define_alloc_func(cTreeCursor, tree_cursor_allocate);

  /* Class methods */
  rb_define_method(cTreeCursor, "initialize", tree_cursor_initialize, 1);
  rb_define_method(cTreeCursor, "reset", tree_cursor_reset, 1);
  rb_define_method(cTreeCursor, "current_node", tree_cursor_current_node, 0);
  rb_define_method(cTreeCursor, "current_field_name",
                   tree_cursor_current_field_name, 0);
  rb_define_method(cTreeCursor, "current_field_id",
                   tree_cursor_current_field_id, 0);
  rb_define_method(cTreeCursor, "goto_parent", tree_cursor_goto_parent, 0);
  rb_define_method(cTreeCursor, "goto_next_sibling",
                   tree_cursor_goto_next_sibling, 0);
  rb_define_method(cTreeCursor, "goto_first_child",
                   tree_cursor_goto_first_child, 0);
  rb_define_method(cTreeCursor, "goto_first_child_for_byte",
                   tree_cursor_goto_first_child_for_byte, 1);
  rb_define_method(cTreeCursor, "goto_first_child_for_point",
                   tree_cursor_goto_first_child_for_point, 1);
  rb_define_method(cTreeCursor, "copy", tree_cursor_copy, 0);
}
