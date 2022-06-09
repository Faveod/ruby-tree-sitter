#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryCursor;

TSQueryCursor *value_to_query_cursor(VALUE self) {
  TSQueryCursor *cursor;

  Data_Get_Struct(self, TSQueryCursor, cursor);

  return cursor;
}

static void query_cursor_free(TSQueryCursor *cursor) {
  ts_query_cursor_delete(cursor);
}

static VALUE query_cursor_allocate(VALUE klass) {
  TSQueryCursor *cursor = ts_query_cursor_new();

  return Data_Wrap_Struct(klass, NULL, query_cursor_free, cursor);
}

static VALUE query_cursor_exec(VALUE self, VALUE query, VALUE node) {
  TSQueryCursor *cursor = value_to_query_cursor(self);
  TSQuery *q = value_to_query(query);
  TSNode *n = value_to_node(node);

  ts_query_cursor_exec(cursor, q, *n);

  return Qnil;
}

void init_query_cursor(void) {
  cQueryCursor = rb_define_class_under(mTreeSitter, "QueryCursor", rb_cObject);

  rb_define_alloc_func(cQueryCursor, query_cursor_allocate);

  /* Class methods */
  rb_define_method(cQueryCursor, "allocate", query_cursor_exec, 2);
}
