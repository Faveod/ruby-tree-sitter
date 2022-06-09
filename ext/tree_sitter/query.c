#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQuery;

TSQuery *value_to_query(VALUE self) {
  TSQuery *query;

  Data_Get_Struct(self, TSQuery, query);

  return query;
}

void query_free(TSQuery *query) { ts_query_delete(query); }

static VALUE query_initialize(VALUE self, VALUE language, VALUE source) {
  TSQuery *ptr = value_to_query(self);
  TSLanguage *lang = value_to_language(language);
  const char *src = StringValuePtr(source);
  uint32_t len = (uint32_t)RSTRING_LEN(source);
  uint32_t error_offset = 0;
  TSQueryError error_type;

  TSQuery *res = ts_query_new(lang, src, len, &error_offset, &error_type);

  if (res == NULL || error_offset > 0) {
    rb_raise(rb_eRuntimeError, "Could not create query: TSQueryError%s",
             query_error_name(error_type));
  }
  ptr = res;

  return self;
}

static VALUE query_pattern_count(VALUE self) {
  TSQuery *query = value_to_query(self);

  return INT2NUM(ts_query_pattern_count(query));
}

static VALUE query_capture_count(VALUE self) {
  TSQuery *query = value_to_query(self);

  return INT2NUM(ts_query_capture_count(query));
}

static VALUE query_string_count(VALUE self) {
  TSQuery *query = value_to_query(self);

  return INT2NUM(ts_query_string_count(query));
}

static VALUE query_start_byte_for_pattern(VALUE self, VALUE byte) {
  TSQuery *query = value_to_query(self);

  return INT2NUM(ts_query_start_byte_for_pattern(query, NUM2INT(byte)));
}

static VALUE query_predicates_for_pattern(VALUE self, VALUE pattern_index) {
  TSQuery *query = value_to_query(self);
  uint32_t length;
  const TSQueryPredicateStep *steps =
      ts_query_predicates_for_pattern(query, NUM2INT(pattern_index), &length);

  VALUE res = rb_ary_new_capa(length);

  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_query_predicate_step(&steps[i])); // must free
  }

  return res;
}

void init_query(void) {
  cQuery = rb_define_class_under(mTreeSitter, "Query", rb_cObject);

  /* Class methods */
  rb_define_method(cQuery, "initialize", query_initialize, 2);
  rb_define_method(cQuery, "pattern_count", query_pattern_count, 0);
  rb_define_method(cQuery, "capture_count", query_capture_count, 0);
  rb_define_method(cQuery, "string_count", query_string_count, 0);
  rb_define_method(cQuery, "start_byte_for_pattern",
                   query_start_byte_for_pattern, 1);
  rb_define_method(cQuery, "predicates_for_pattern",
                   query_predicates_for_pattern, 1);
}
