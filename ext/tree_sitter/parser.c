#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cParser;

TSParser *value_to_parser(VALUE self) {
  TSParser *parser;

  Data_Get_Struct(self, TSParser, parser);

  return parser;
}

static void parser_free(TSParser *parser) { ts_parser_delete(parser); }

static VALUE parser_allocate(VALUE klass) {
  TSParser *parser = ts_parser_new();

  return Data_Wrap_Struct(klass, NULL, parser_free, parser);
}

static VALUE parser_get_language(VALUE self) {
  TSParser *parser = value_to_parser(self);

  return new_language(ts_parser_language(parser));
}

static VALUE parser_get_included_ranges(VALUE self) {
  TSParser *parser = value_to_parser(self);
  uint32_t length;
  const TSRange *ranges = ts_parser_included_ranges(parser, &length);
  VALUE res = rb_ary_new_capa(length);

  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_range(&ranges[i]));
  }

  return res;
}

static VALUE parser_get_timeout_micros(VALUE self) {
  TSParser *parser = value_to_parser(self);
  uint64_t timeout = ts_parser_timeout_micros(parser);
  VALUE res = ULL2NUM(timeout);

  return res;
}

static VALUE parser_get_logger(VALUE self) {
  TSParser *parser = value_to_parser(self);
  TSLogger logger = ts_parser_logger(parser);

  return new_logger(&logger);
}

static VALUE parser_set_language(VALUE self, VALUE language) {
  TSParser *parser = value_to_parser(self);
  TSLanguage *lang = value_to_language(language);

  return ts_parser_set_language(parser, lang) ? Qtrue : Qfalse;
}

static VALUE parser_set_included_ranges(VALUE self, VALUE array) {
  Check_Type(array, T_ARRAY);

  TSParser *parser = value_to_parser(self);
  long length = rb_array_len(array);
  TSRange *ranges = (TSRange *)malloc(length * sizeof(TSRange));

  for (int i = 0; i < length; i++) {
    ranges[i] = value_to_range(rb_ary_entry(array, i));
  }

  bool res = ts_parser_set_included_ranges(parser, ranges, (uint32_t)length);
  free(ranges);

  return res ? Qtrue : Qfalse;
}

static VALUE parser_set_timeout_micros(VALUE self, VALUE timeout) {
  TSParser *parser = value_to_parser(self);
  uint64_t t = NUM2ULL(timeout);

  ts_parser_set_timeout_micros(parser, t);

  return Qnil;
}

static VALUE parser_set_logger(VALUE self, VALUE logger) {
  TSParser *parser = value_to_parser(self);
  TSLogger *l = value_to_logger(logger);

  ts_parser_set_logger(parser, *l);

  return Qnil;
}

static VALUE parser_parse(VALUE self, VALUE old_tree, VALUE input) {
  TSParser *parser = value_to_parser(self);
  TSTree *tree = value_to_tree(old_tree);
  TSInput *in = value_to_input(input);

  return new_tree(ts_parser_parse(parser, tree, *in));
}

static VALUE parser_parse_string(VALUE self, VALUE old_tree, VALUE string) {
  TSParser *parser = value_to_parser(self);
  TSTree *tree = value_to_tree(old_tree);
  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);

  return new_tree(ts_parser_parse_string(parser, tree, str, len));
}

static VALUE parser_parse_string_encoding(VALUE self, VALUE old_tree,
                                          VALUE string, VALUE encoding) {
  TSParser *parser = value_to_parser(self);
  TSTree *tree = value_to_tree(old_tree);
  TSInputEncoding enc = value_to_encoding(encoding);
  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);

  return new_tree(ts_parser_parse_string_encoding(parser, tree, str, len, enc));
}

static VALUE parser_reset(VALUE self) {
  TSParser *parser = value_to_parser(self);

  ts_parser_reset(parser);

  return Qnil;
}

static VALUE parser_print_dot_graphs(VALUE self, VALUE file) {
  Check_Type(file, T_STRING);

  TSParser *parser = value_to_parser(self);
  char *path = StringValueCStr(file);
  int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC,
                0644); // 0644 = all read + user write

  ts_parser_print_dot_graphs(parser, fd);
  close(fd);

  return Qnil;
}

void init_parser(void) {
  cParser = rb_define_class_under(mTreeSitter, "Parser", rb_cObject);

  rb_define_alloc_func(cParser, parser_allocate);

  /* Class methods */
  rb_define_method(cParser, "language", parser_get_language, 0);
  rb_define_method(cParser, "language=", parser_set_language, 1);
  rb_define_method(cParser, "included_ranges", parser_get_included_ranges, 0);
  rb_define_method(cParser, "included_ranges=", parser_set_included_ranges, 1);
  rb_define_method(cParser, "parse", parser_parse, 2);
  rb_define_method(cParser, "parse_string", parser_parse_string, 2);
  rb_define_method(cParser, "parse_string_encoding",
                   parser_parse_string_encoding, 3);
  rb_define_method(cParser, "reset", parser_reset, 0);
  rb_define_method(cParser, "timeout_micros", parser_get_timeout_micros, 0);
  rb_define_method(cParser, "timeout_micros=", parser_set_timeout_micros, 1);
  // TODO: How do we work with cancellation pointers? Do we need to expose them?
  // rb_define_method(cParser, "cancellation_flag",
  // parser_get_cancellation_flag, 0);
  // rb_define_method(cParser, "cancellation_flag=",
  // parser_set_cancellation_flag, 1);
  rb_define_method(cParser, "logger", parser_get_logger, 0);
  rb_define_method(cParser, "logger", parser_set_logger, 1);
  rb_define_method(cParser, "print_dot_graphs", parser_print_dot_graphs, 1);
}
