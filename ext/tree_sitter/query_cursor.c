#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryCursor;

DATA_TYPE(TSQueryCursor *, query_cursor)
DATA_FREE_PTR(query_cursor)
DATA_MEMSIZE(query_cursor)
DATA_DECLARE_DATA_TYPE(query_cursor)
static VALUE query_cursor_allocate(VALUE klass) {
  query_cursor_t *query_cursor;
  VALUE res = TypedData_Make_Struct(klass, query_cursor_t,
                                    &query_cursor_data_type, query_cursor);
  query_cursor->data = ts_query_cursor_new();
  return res;
}
DATA_UNWRAP(query_cursor)
DATA_PTR_NEW(cQueryCursor, TSQueryCursor, query_cursor)
DATA_FROM_VALUE(TSQueryCursor *, query_cursor)

static VALUE query_cursor_exec(VALUE self, VALUE query, VALUE node) {
  VALUE res = query_cursor_allocate(cQueryCursor);
  query_cursor_t *query_cursor = unwrap(res);
  ts_query_cursor_exec(query_cursor->data, value_to_query(query),
                       value_to_node(node));
  return res;
}

static VALUE query_cursor_did_exceed_match_limit(VALUE self) {
  return ts_query_cursor_did_exceed_match_limit(SELF) ? Qtrue : Qfalse;
}

static VALUE query_cursor_get_match_limit(VALUE self) {
  return UINT2NUM(ts_query_cursor_match_limit(SELF));
}

static VALUE query_cursor_set_match_limit(VALUE self, VALUE limit) {
  ts_query_cursor_set_match_limit(SELF, NUM2UINT(limit));
  return Qnil;
}

static VALUE query_cursor_set_byte_range(VALUE self, VALUE from, VALUE to) {
  ts_query_cursor_set_byte_range(SELF, NUM2UINT(from), NUM2UINT(to));
  return Qnil;
}

static VALUE query_cursor_set_point_range(VALUE self, VALUE from, VALUE to) {
  ts_query_cursor_set_point_range(SELF, value_to_point(from),
                                  value_to_point(to));
  return Qnil;
}

static VALUE query_cursor_next_match(VALUE self) {
  TSQueryMatch match;
  if (ts_query_cursor_next_match(SELF, &match)) {
    return new_query_match(&match);
  } else {
    return Qnil;
  }
}

static VALUE query_cursor_remove_match(VALUE self, VALUE id) {
  ts_query_cursor_remove_match(SELF, NUM2UINT(id));
  return Qnil;
}

// NOTE: maybe this is the limit of how "transparent" the bindings need to be.
// Pending benchmarks, this can be very inefficient because obviously
// ts_query_cursor_next_capture is intended to be used in a loop.  Creating an
// array of two values and returning them, intuitively speaking, seem very
// inefficient.
static VALUE query_cursor_next_capture(VALUE self) {
  TSQueryMatch match;
  uint32_t index;
  if (ts_query_cursor_next_capture(SELF, &match, &index)) {
    VALUE res = rb_ary_new_capa(2);
    rb_ary_push(res, UINT2NUM(index));
    rb_ary_push(res, new_query_match(&match));
    return res;
  } else {
    return Qnil;
  }
}

void init_query_cursor(void) {
  cQueryCursor = rb_define_class_under(mTreeSitter, "QueryCursor", rb_cObject);

  rb_define_alloc_func(cQueryCursor, query_cursor_allocate);

  /* Class methods */
  DECLARE_ACCESSOR(cQueryCursor, query_cursor, match_limit)
  rb_define_module_function(cQueryCursor, "exec", query_cursor_exec, 2);
  rb_define_method(cQueryCursor, "exceed_match_limit?",
                   query_cursor_did_exceed_match_limit, 0);
  rb_define_method(cQueryCursor, "byte_range=", query_cursor_set_byte_range, 2);
  rb_define_method(cQueryCursor, "point_range=", query_cursor_set_point_range,
                   2);
  rb_define_method(cQueryCursor, "next_match", query_cursor_next_match, 0);
  rb_define_method(cQueryCursor, "remove_match", query_cursor_remove_match, 1);
  rb_define_method(cQueryCursor, "next_capture", query_cursor_next_capture, 0);
}
