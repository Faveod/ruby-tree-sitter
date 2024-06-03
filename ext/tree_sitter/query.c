#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQuery;

DATA_PTR_WRAP(Query, query);

/**
 * Get the number of captures literals in the query.
 *
 * @return [Integer]
 */
static VALUE query_capture_count(VALUE self) {
  return UINT2NUM(ts_query_capture_count(SELF));
}

/**
 * Get the name and length of one of the query's captures, or one of the
 * query's string literals. Each capture and string is associated with a
 * numeric id based on the order that it appeared in the query's source.
 *
 * @raise [IndexError] if out of range.
 *
 * @param index [Integer]
 *
 * @return [String]
 */
static VALUE query_capture_name_for_id(VALUE self, VALUE index) {
  const TSQuery *query = SELF;
  uint32_t idx = NUM2UINT(index);
  uint32_t range = ts_query_capture_count(query);

  if (idx >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", idx, range);
  } else {
    uint32_t length;
    const char *name = ts_query_capture_name_for_id(query, idx, &length);
    return safe_str2(name, length);
  }
}

/**
 * Get the quantifier of the query's captures. Each capture is associated
 * with a numeric id based on the order that it appeared in the query's source.
 *
 * @raise [IndexError] if out of range.
 *
 * @param query_idx   [Integer]
 * @param capture_idx [Integer]
 *
 * @return [Integer]
 */
static VALUE query_capture_quantifier_for_id(VALUE self, VALUE query_idx,
                                             VALUE capture_idx) {
  const TSQuery *query = SELF;
  uint32_t pattern = NUM2UINT(query_idx);
  uint32_t index = NUM2UINT(capture_idx);
  uint32_t range = ts_query_capture_count(query);

  if (index >= range) {
    rb_raise(rb_eIndexError, "Capture ID %d out of range (len = %d)", index,
             range);
  } else {
    return UINT2NUM(ts_query_capture_quantifier_for_id(query, pattern, index));
  }
}

/**
 * Disable a certain capture within a query.
 *
 * This prevents the capture from being returned in matches, and also avoids
 * any resource usage associated with recording the capture. Currently, there
 * is no way to undo this.
 *
 * @param capture [String]
 *
 * @return [nil]
 */
static VALUE query_disable_capture(VALUE self, VALUE capture) {
  const char *cap = StringValuePtr(capture);
  uint32_t length = (uint32_t)RSTRING_LEN(capture);
  ts_query_disable_capture(SELF, cap, length);
  return Qnil;
}

/**
 * Disable a certain pattern within a query.
 *
 * This prevents the pattern from matching and removes most of the overhead
 * associated with the pattern. Currently, there is no way to undo this.
 *
 * @raise [IndexError] if out of range.
 *
 * @param pattern [Integer]
 *
 * @return [nil]
 */
static VALUE query_disable_pattern(VALUE self, VALUE pattern) {
  TSQuery *query = SELF;
  uint32_t index = NUM2UINT(pattern);
  uint32_t range = ts_query_pattern_count(query);

  if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  } else {
    ts_query_disable_pattern(query, index);
    return Qnil;
  }
}

/**
 * Create a new query from a string containing one or more S-expression
 * patterns. The query is associated with a particular language, and can
 * only be run on syntax nodes parsed with that language.
 *
 * If all of the given patterns are valid, this returns a {Query}.
 *
 * @raise [RuntimeError]
 *
 * @param language [Language]
 * @param source   [String]
 *
 * @return [Query]
 */
static VALUE query_initialize(VALUE self, VALUE language, VALUE source) {
  // FIXME: should we raise an exception here?
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

  rb_iv_set(self, "@text_predicates", rb_ary_new());
  rb_iv_set(self, "@property_predicates", rb_ary_new());
  rb_iv_set(self, "@property_settings", rb_ary_new());
  rb_iv_set(self, "@general_predicates", rb_ary_new());

  rb_funcall(self, rb_intern("process"), 1, source);

  return self;
}

/**
 * Get the number of patterns in the query.
 *
 * @return [Integer]
 */
static VALUE query_pattern_count(VALUE self) {
  return UINT2NUM(ts_query_pattern_count(SELF));
}

/**
 * Check if a given pattern is guaranteed to match once a given step is reached.
 * The step is specified by its byte offset in the query's source code.
 *
 * @param byte_offset [Integer]
 *
 * @return [Integer]
 */
static VALUE query_pattern_guaranteed_at_step(VALUE self, VALUE byte_offset) {
  return UINT2NUM(
      ts_query_is_pattern_guaranteed_at_step(SELF, NUM2UINT(byte_offset)));
}

/**
 * Get all of the predicates for the given pattern in the query.
 *
 * The predicates are represented as a single array of steps. There are three
 * types of steps in this array, which correspond to the three legal values for
 * the +type+ field:
 * - {QueryPredicateStep::CAPTURE}: Steps with this type represent names
 *   of captures. Their +value_id+ can be used with the
 *   {Query#capture_name_for_id} function to obtain the name of the capture.
 * - {QueryPredicateStep::STRING}: Steps with this type represent literal
 *   strings. Their +value_id+ can be used with the
 *   {Query#string_value_for_id} function to obtain their string value.
 * - {QueryPredicateStep::DONE}: Steps with this type are *sentinels*
 *   that represent the end of an individual predicate. If a pattern has two
 *   predicates, then there will be two steps with this +type+ in the array.
 *
 * @param pattern_index [Integer]
 *
 * @return [Array<QueryPredicateStep>]
 */
static VALUE query_predicates_for_pattern(VALUE self, VALUE pattern_index) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(pattern_index);
  uint32_t length;
  const TSQueryPredicateStep *steps =
      ts_query_predicates_for_pattern(query, index, &length);
  VALUE res = rb_ary_new_capa(length);

  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_query_predicate_step(&steps[i]));
  }

  return res;
}

/**
 * Get the byte offset where the given pattern starts in the query's source.
 *
 * This can be useful when combining queries by concatenating their source
 * code strings.
 *
 * @raise [IndexError] if out of range.
 *
 * @param pattern_index [Integer]
 *
 * @return [Integer]
 */
static VALUE query_start_byte_for_pattern(VALUE self, VALUE pattern_index) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(pattern_index);
  uint32_t range = ts_query_pattern_count(query);

  if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  } else {
    return UINT2NUM(ts_query_start_byte_for_pattern(SELF, index));
  }
}

/**
 * Get the number of string literals in the query.
 *
 * @return [Integer]
 */
static VALUE query_string_count(VALUE self) {
  return UINT2NUM(ts_query_string_count(SELF));
}

/**
 * @raise [IndexError] if out of range.
 *
 * @param id [Integer]
 *
 * @return [String]
 */
static VALUE query_string_value_for_id(VALUE self, VALUE id) {
  const TSQuery *query = SELF;
  uint32_t index = NUM2UINT(id);
  uint32_t range = ts_query_string_count(query);

  if (index >= range) {
    rb_raise(rb_eIndexError, "Index %d out of range (len = %d)", index, range);
  } else {
    uint32_t length;
    const char *string = ts_query_string_value_for_id(query, index, &length);
    return safe_str2(string, length);
  }
}

// FIXME: missing:
// 1. ts_query_is_pattern_rooted
// 1. ts_query_is_pattern_non_local
void init_query(void) {
  cQuery = rb_define_class_under(mTreeSitter, "Query", rb_cObject);

  rb_define_alloc_func(cQuery, query_allocate);

  /* Class methods */
  rb_define_method(cQuery, "capture_count", query_capture_count, 0);
  rb_define_method(cQuery, "capture_name_for_id", query_capture_name_for_id, 1);
  rb_define_method(cQuery, "capture_quantifier_for_id",
                   query_capture_quantifier_for_id, 2);
  rb_define_method(cQuery, "disable_capture", query_disable_capture, 1);
  rb_define_method(cQuery, "disable_pattern", query_disable_pattern, 1);
  rb_define_method(cQuery, "initialize", query_initialize, 2);
  rb_define_method(cQuery, "pattern_count", query_pattern_count, 0);
  rb_define_method(cQuery, "pattern_guaranteed_at_step?",
                   query_pattern_guaranteed_at_step, 1);
  rb_define_method(cQuery, "predicates_for_pattern",
                   query_predicates_for_pattern, 1);
  rb_define_method(cQuery, "start_byte_for_pattern",
                   query_start_byte_for_pattern, 1);
  rb_define_method(cQuery, "string_count", query_string_count, 0);
  rb_define_method(cQuery, "string_value_for_id", query_string_value_for_id, 1);
}
