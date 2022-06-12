#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cParser;

typedef struct {
  TSParser *data;
  size_t cancellation_flag;
} parser_t;

static void parser_free(void *ptr) {
  ts_parser_delete(((parser_t *)ptr)->data);
  xfree(ptr);
}

static size_t parser_memsize(const void *ptr) {
  parser_t *type = (parser_t *)ptr;
  return sizeof(type);
}

const rb_data_type_t parser_data_type = {
    .wrap_struct_name = "parser",
    .function =
        {
            .dmark = NULL,
            .dfree = parser_free,
            .dsize = parser_memsize,
            .dcompact = NULL,
        },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

DATA_UNWRAP(parser)

static VALUE parser_allocate(VALUE klass) {
  parser_t *parser;
  VALUE res = TypedData_Make_Struct(klass, parser_t, &parser_data_type, parser);
  parser->data = ts_parser_new();
  return res;
}

static VALUE parser_get_language(VALUE self) {
  return new_language(ts_parser_language(SELF));
}

static VALUE parser_get_included_ranges(VALUE self) {
  uint32_t length;
  const TSRange *ranges = ts_parser_included_ranges(SELF, &length);
  VALUE res = rb_ary_new_capa(length);
  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_range(&ranges[i]));
  }
  return res;
}

static VALUE parser_get_timeout_micros(VALUE self) {
  return ULL2NUM(ts_parser_timeout_micros(SELF));
}

static VALUE parser_get_logger(VALUE self) {
  return new_logger_by_val(ts_parser_logger(SELF));
}

static VALUE parser_get_cancellation_flag(VALUE self) {
  return SIZET2NUM(*ts_parser_cancellation_flag(SELF));
}

static VALUE parser_set_language(VALUE self, VALUE language) {
  return ts_parser_set_language(SELF, value_to_language(language)) ? Qtrue
                                                                   : Qfalse;
}

static VALUE parser_set_included_ranges(VALUE self, VALUE array) {
  Check_Type(array, T_ARRAY);

  long length = rb_array_len(array);
  TSRange *ranges = (TSRange *)malloc(length * sizeof(TSRange));
  for (long i = 0; i < length; i++) {
    ranges[i] = value_to_range(rb_ary_entry(array, i));
  }
  bool res = ts_parser_set_included_ranges(SELF, ranges, (uint32_t)length);
  free(ranges);
  return res ? Qtrue : Qfalse;
}

static VALUE parser_set_timeout_micros(VALUE self, VALUE timeout) {
  ts_parser_set_timeout_micros(SELF, NUM2ULL(timeout));
  return Qnil;
}

static VALUE parser_set_cancellation_flag(VALUE self, VALUE flag) {
  unwrap(self)->cancellation_flag = NUM2SIZET(flag);
  ts_parser_set_cancellation_flag(SELF, &unwrap(self)->cancellation_flag);
  return Qnil;
}

static VALUE parser_set_logger(VALUE self, VALUE logger) {
  ts_parser_set_logger(SELF, value_to_logger(logger));
  return Qnil;
}

static VALUE parser_parse(VALUE self, VALUE old_tree, VALUE input) {
  return new_tree(
      ts_parser_parse(SELF, value_to_tree(old_tree), value_to_input(input)));
}

static VALUE parser_parse_string(VALUE self, VALUE old_tree, VALUE string) {
  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);
  return new_tree(
      ts_parser_parse_string(SELF, value_to_tree(old_tree), str, len));
}

static VALUE parser_parse_string_encoding(VALUE self, VALUE old_tree,
                                          VALUE string, VALUE encoding) {
  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);
  return new_tree(ts_parser_parse_string_encoding(
      SELF, value_to_tree(old_tree), str, len, value_to_encoding(encoding)));
}

static VALUE parser_reset(VALUE self) {
  ts_parser_reset(SELF);
  return Qnil;
}

static VALUE parser_print_dot_graphs(VALUE self, VALUE file) {
  Check_Type(file, T_STRING);
  char *path = StringValueCStr(file);
  int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC,
                0644); // 0644 = all read + user write
  ts_parser_print_dot_graphs(SELF, fd);
  close(fd);
  return Qnil;
}

void init_parser(void) {
  cParser = rb_define_class_under(mTreeSitter, "Parser", rb_cObject);

  rb_define_alloc_func(cParser, parser_allocate);

  /* Class methods */
  DEFINE_ACCESSOR(cParser, parser, language)
  DEFINE_ACCESSOR(cParser, parser, included_ranges)
  DEFINE_ACCESSOR(cParser, parser, timeout_micros)
  DEFINE_ACCESSOR(cParser, parser, logger)
  DEFINE_ACCESSOR(cParser, parser, cancellation_flag)
  rb_define_method(cParser, "parse", parser_parse, 2);
  rb_define_method(cParser, "parse_string", parser_parse_string, 2);
  rb_define_method(cParser, "parse_string_encoding",
                   parser_parse_string_encoding, 3);
  rb_define_method(cParser, "reset", parser_reset, 0);
  rb_define_method(cParser, "print_dot_graphs", parser_print_dot_graphs, 1);
}
