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

static VALUE query_pattern_guaranteed_at_step(VALUE self, VALUE byte_offset) {
  TSQuery *query = value_to_query(self);

  return INT2NUM(
      ts_query_is_pattern_guaranteed_at_step(query, NUM2INT(byte_offset)));
}

static VALUE query_capture_name_for_id(VALUE self, VALUE id) {
  TSQuery *query = value_to_query(self);
  uint32_t length;
  const char *name = ts_query_capture_name_for_id(query, NUM2INT(id), &length);

  return rb_str_new(name, length);
}

static VALUE query_capture_quantifier_for_id(VALUE self, VALUE id,
                                             VALUE capture_id) {
  TSQuery *query = value_to_query(self);

  return INT2NUM(ts_query_capture_quantifier_for_id(query, NUM2INT(id),
                                                    NUM2INT(capture_id)));
}

static VALUE query_string_value_for_id(VALUE self, VALUE id) {
  TSQuery *query = value_to_query(self);
  uint32_t length;
  const char *string =
      ts_query_string_value_for_id(query, NUM2INT(id), &length);

  return rb_str_new(string, length);
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
  rb_define_method(cQuery, "pattern_guaranteed_at_step?",
                   query_pattern_guaranteed_at_step, 1);
  rb_define_method(cQuery, "capture_name_for_id", query_capture_name_for_id, 1);
  rb_define_method(cQuery, "capture_quantifier_for_id",
                   query_capture_quantifier_for_id, 2);
  rb_define_method(cQuery, "string_value_for_id", query_string_value_for_id, 1);
}
