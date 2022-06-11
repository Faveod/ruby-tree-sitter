#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryMatch;

DATA_WRAP(cQueryMatch, TSQueryMatch, query_match)
DATA_GETTER(query_match, id, INT2NUM)
DATA_GETTER(query_match, pattern_index, INT2FIX)
DATA_GETTER(query_match, capture_count, INT2FIX)

static VALUE query_match_get_captures(VALUE self) {
  query_match_t *query_match = unwrap(self);

  int length = NUM2INT(query_match->data.capture_count);
  VALUE res = rb_ary_new_capa(length);
  const TSQueryCapture *captures = query_match->data.captures;
  for (int i = 0; i < length; i++) {
    rb_ary_push(res, new_query_capture(&captures[i]));
  }

  return res;
}

void init_query_match(void) {
  cQueryMatch = rb_define_class_under(mTreeSitter, "QueryMatch", rb_cObject);

  rb_define_alloc_func(cQueryMatch, query_match_allocate);

  /* Class methods */
  DEFINE_GETTER(cQueryMatch, query_match, id)
  DEFINE_GETTER(cQueryMatch, query_match, pattern_index)
  DEFINE_GETTER(cQueryMatch, query_match, capture_count)
  DEFINE_GETTER(cQueryMatch, query_match, captures)
}
