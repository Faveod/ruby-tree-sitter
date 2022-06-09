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

void init_tree_cursor(void) {
  cTreeCursor = rb_define_class_under(mTreeSitter, "TreeCursor", rb_cObject);

  rb_define_alloc_func(cTreeCursor, tree_cursor_allocate);

  /* Class methods */
  rb_define_method(cTreeCursor, "initialize", tree_cursor_initialize, 1);
  rb_define_method(cTreeCursor, "reset", tree_cursor_reset, 1);
  rb_define_method(cTreeCursor, "current_node", tree_cursor_current_node, 0);
  rb_define_method(cTreeCursor, "current_field_name",
                   tree_cursor_current_field_name, 0);
}