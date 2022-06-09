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

void init_query_cursor(void) {
  cQueryCursor = rb_define_class_under(mTreeSitter, "QueryCursor", rb_cObject);

  rb_define_alloc_func(cQueryCursor, query_cursor_allocate);
}
