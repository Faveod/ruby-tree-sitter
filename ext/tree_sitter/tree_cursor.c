#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTreeCursor;

TSTreeCursor *value_to_tree_cursor(VALUE self) {
  TSTreeCursor *tree_cursor;

  Data_Get_Struct(self, TSTreeCursor, tree_cursor);

  return tree_cursor;
}

void tree_cursor_free(TSTreeCursor *tree_cursor) {
  ts_tree_cursor_delete(tree_cursor);
  free(tree_cursor);
}

static VALUE tree_cursor_allocate(VALUE klass) {
  TSTreeCursor *tree_cursor = (TSTreeCursor *)malloc(sizeof(TSTreeCursor));

  return Data_Wrap_Struct(klass, NULL, tree_cursor_free, tree_cursor);
}

static VALUE tree_cursor_initialize(VALUE self, VALUE node) {
  TSNode *n = value_to_node(self);
  TSTreeCursor *ptr = value_to_tree_cursor(self);

  *ptr = ts_tree_cursor_new(*n);

  return self;
}

static VALUE tree_cursor_reset(VALUE self, VALUE node) {
  TSNode *n = value_to_node(self);
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);

  ts_tree_cursor_reset(tree_cursor, *n);

  return Qnil;
}

static VALUE tree_cursor_current_node(VALUE self) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  TSNode node = ts_tree_cursor_current_node(tree_cursor);
  return new_node(&node);
}

static VALUE tree_cursor_current_field_name(VALUE self) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  return rb_str_new_cstr(ts_tree_cursor_current_field_name(tree_cursor));
}

static VALUE tree_cursor_current_field_id(VALUE self) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  return INT2NUM(ts_tree_cursor_current_field_id(tree_cursor));
}

static VALUE tree_cursor_goto_parent(VALUE self) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  return ts_tree_cursor_goto_parent(tree_cursor) ? Qtrue : Qfalse;
}

static VALUE tree_cursor_goto_next_sibling(VALUE self) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  return ts_tree_cursor_goto_next_sibling(tree_cursor) ? Qtrue : Qfalse;
}

static VALUE tree_cursor_goto_first_child(VALUE self) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  return ts_tree_cursor_goto_first_child(tree_cursor) ? Qtrue : Qfalse;
}

static VALUE tree_cursor_goto_first_child_for_byte(VALUE self, VALUE byte) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  uint32_t b = NUM2INT(byte);
  return LL2NUM(ts_tree_cursor_goto_first_child_for_byte(tree_cursor, b));
}

static VALUE tree_cursor_goto_first_child_for_point(VALUE self, VALUE point) {
  TSTreeCursor *tree_cursor = value_to_tree_cursor(self);
  TSPoint *p = value_to_point(point);
  return LL2NUM(ts_tree_cursor_goto_first_child_for_point(tree_cursor, *p));
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
}
