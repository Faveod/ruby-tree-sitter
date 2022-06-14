#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQuery;

DATA_PTR_WRAP(Query, query);

static VALUE query_initialize(VALUE self, VALUE language, VALUE source) {
  TSLanguage *lang = value_to_language(language);
  const char *src = StringValuePtr(source);
  uint32_t len = (uint32_t)RSTRING_LEN(source);
  uint32_t error_offset = 0;
  TSQueryError error_type;

  TSQuery *res = ts_query_new(lang, src, len, &error_offset, &error_type);

  if (res == NULL || error_offset > 0) {
    rb_raise(rb_eRuntimeError, "Could not create query: TSQueryError%s",
             query_error_str(error_type));
  } else {
    SELF = res;
  }

  return self;
}

static VALUE query_pattern_count(VALUE self) {
  return INT2NUM(ts_query_pattern_count(SELF));
}

static VALUE query_capture_count(VALUE self) {
  return INT2NUM(ts_query_capture_count(SELF));
}

static VALUE query_string_count(VALUE self) {
  return INT2NUM(ts_query_string_count(SELF));
}

static VALUE query_start_byte_for_pattern(VALUE self, VALUE pattern_index) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(pattern_index);
  uint32_t range = ts_query_pattern_count(query);

  if (index < 0) {
    rb_raise(rb_eIndexError, "Byte index %d is negative", index);
  } else if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  }

  return INT2NUM(ts_query_start_byte_for_pattern(SELF, index));
}

static VALUE query_predicates_for_pattern(VALUE self, VALUE pattern_index) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(pattern_index);
  uint32_t range = ts_query_pattern_count(query);

  if (index < 0) {
    rb_raise(rb_eIndexError, "Index %d is negative (len = %d)", index, range);
  } else if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  }

  uint32_t length;
  const TSQueryPredicateStep *steps =
      ts_query_predicates_for_pattern(query, index, &length);
  VALUE res = rb_ary_new_capa(length);

  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_query_predicate_step(&steps[i]));
  }

  return res;
}

static VALUE query_pattern_guaranteed_at_step(VALUE self, VALUE byte_offset) {
  uint32_t index = NUM2UINT(byte_offset);

  if (index < 0) {
    rb_raise(rb_eIndexError, "Byte index %d is negative", index);
  }

  return INT2NUM(ts_query_is_pattern_guaranteed_at_step(SELF, index));
}

static VALUE query_capture_name_for_id(VALUE self, VALUE id) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(id);
  uint32_t range = ts_query_capture_count(query);

  if (index < 0) {
    rb_raise(rb_eIndexError, "Index %d is negative (len = %d)", index, range);
  } else if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  }

  uint32_t length;
  const char *name = ts_query_capture_name_for_id(query, index, &length);
  return safe_str2(name, length);
}

static VALUE query_capture_quantifier_for_id(VALUE self, VALUE id,
                                             VALUE capture_id) {
  const TSQuery *query = SELF;
  uint32_t pattern = NUM2UINT(id);
  uint32_t index = NUM2UINT(capture_id);
  uint32_t range = ts_query_capture_count(query);

  if (pattern < 0) {
    rb_raise(rb_eIndexError, "Pattern ID %d is negative", pattern);
  } else if (index < 0) {
    rb_raise(rb_eIndexError, "Capture ID %d is negative (len = %d)", index,
             range);
  } else if (index >= range) {
    rb_raise(rb_eIndexError, "Capture ID %d out of range (len = %d)", index,
             range);
  }

  return UINT2NUM(ts_query_capture_quantifier_for_id(query, pattern, index));
}

static VALUE query_string_value_for_id(VALUE self, VALUE id) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(id);
  uint32_t range = ts_query_string_count(query);

  if (index < 0) {
    rb_raise(rb_eIndexError, "Index %d is negative (len = %d)", index, range);
  } else if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  }

  uint32_t length;
  const char *string = ts_query_string_value_for_id(query, index, &length);
  return safe_str2(string, length);
}

static VALUE query_disable_capture(VALUE self, VALUE capture) {
  const char *cap = StringValuePtr(capture);
  uint32_t length = (uint32_t)RSTRING_LEN(capture);
  ts_query_disable_capture(SELF, cap, length);
  return Qnil;
}

static VALUE query_disable_pattern(VALUE self, VALUE pattern) {
  TSQuery *query = SELF;
  uint32_t index = NUM2UINT(pattern);
  uint32_t range = ts_query_pattern_count(query);

  if (index < 0) {
    rb_raise(rb_eIndexError, "Index %d is negative (len = %d)", index, range);
  } else if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  }

  ts_query_disable_pattern(query, index);
  return Qnil;
}

void init_query(void) {
  cQuery = rb_define_class_under(mTreeSitter, "Query", rb_cObject);

  rb_define_alloc_func(cQuery, query_allocate);

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
  rb_define_method(cQuery, "disable_capture", query_disable_capture, 1);
  rb_define_method(cQuery, "disable_pattern", query_disable_pattern, 1);
}
