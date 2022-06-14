#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryMatch;

DATA_WRAP(QueryMatch, query_match)
DATA_DEFINE_GETTER(query_match, id, UINT2NUM)
DATA_DEFINE_GETTER(query_match, pattern_index, INT2FIX)
DATA_DEFINE_GETTER(query_match, capture_count, INT2FIX)

static VALUE query_match_get_captures(VALUE self) {
  query_match_t *query_match = unwrap(self);

  uint16_t length = query_match->data.capture_count;
  VALUE res = rb_ary_new_capa(length);
  const TSQueryCapture *captures = query_match->data.captures;
  for (int i = 0; i < length; i++) {
    rb_ary_push(res, new_query_capture(&captures[i]));
  }

  return res;
}

static VALUE query_match_inspect(VALUE self) {
  TSQueryMatch query_match = SELF;
  return rb_sprintf("{id=%d, pattern_inex=%d, capture_count=%d}",
                    query_match.id, query_match.pattern_index,
                    query_match.capture_count);
}

void init_query_match(void) {
  cQueryMatch = rb_define_class_under(mTreeSitter, "QueryMatch", rb_cObject);

  rb_define_alloc_func(cQueryMatch, query_match_allocate);

  /* Class methods */
  DECLARE_GETTER(cQueryMatch, query_match, id)
  DECLARE_GETTER(cQueryMatch, query_match, pattern_index)
  DECLARE_GETTER(cQueryMatch, query_match, capture_count)
  DECLARE_GETTER(cQueryMatch, query_match, captures)
  rb_define_method(cQueryMatch, "inspect", query_match_inspect, 0);
  rb_define_method(cQueryMatch, "to_s", query_match_inspect, 0);
}
