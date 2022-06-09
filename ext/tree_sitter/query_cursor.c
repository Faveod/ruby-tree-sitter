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

static VALUE query_cursor_did_exceed_match_limit(VALUE self) {
  TSQueryCursor *cursor = value_to_query_cursor(self);
  return ts_query_cursor_did_exceed_match_limit(cursor) ? Qtrue : Qfalse;
}

static VALUE query_cursor_get_match_limit(VALUE self) {
  TSQueryCursor *cursor = value_to_query_cursor(self);
  return INT2NUM(ts_query_cursor_match_limit(cursor));
}

static VALUE query_cursor_set_match_limit(VALUE self, VALUE limit) {
  TSQueryCursor *cursor = value_to_query_cursor(self);

  ts_query_cursor_set_match_limit(cursor, NUM2INT(limit));

  return Qnil;
}

static VALUE query_cursor_set_byte_range(VALUE self, VALUE from, VALUE to) {
  TSQueryCursor *cursor = value_to_query_cursor(self);

  ts_query_cursor_set_byte_range(cursor, NUM2INT(from), NUM2INT(to));

  return Qnil;
}

static VALUE query_cursor_set_point_range(VALUE self, VALUE from, VALUE to) {
  TSQueryCursor *cursor = value_to_query_cursor(self);
  TSPoint *f = value_to_point(from);
  TSPoint *t = value_to_point(to);

  ts_query_cursor_set_point_range(cursor, *f, *t);

  return Qnil;
}

void init_query_cursor(void) {
  cQueryCursor = rb_define_class_under(mTreeSitter, "QueryCursor", rb_cObject);

  rb_define_alloc_func(cQueryCursor, query_cursor_allocate);

  /* Class methods */
  rb_define_method(cQueryCursor, "exec", query_cursor_exec, 2);
  rb_define_method(cQueryCursor, "exceed_match_limit?",
                   query_cursor_did_exceed_match_limit, 0);
  rb_define_method(cQueryCursor, "match_limit", query_cursor_get_match_limit,
                   0);
  rb_define_method(cQueryCursor, "match_limit=", query_cursor_set_match_limit,
                   1);
  rb_define_method(cQueryCursor, "byte_range=", query_cursor_set_byte_range, 2);
  rb_define_method(cQueryCursor, "point_range=", query_cursor_set_point_range,
                   2);
}
