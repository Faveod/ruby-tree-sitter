#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cParser;

void parser_free(TSParser *parser) { ts_parser_delete(parser); }

static VALUE parser_allocate(VALUE klass) {
  TSParser *parser;
  parser = ts_parser_new();
  return Data_Wrap_Struct(klass, NULL, parser_free, parser);
}

static VALUE parser_get_language(VALUE self) {
  TSParser *parser;
  Data_Get_Struct(self, TSParser, parser);

  return new_language(ts_parser_language(parser));
}

static VALUE parser_get_included_ranges(VALUE self) {
  TSParser *parser;
  Data_Get_Struct(self, TSParser, parser);
  uint32_t length;

  const TSRange *ranges = ts_parser_included_ranges(parser, &length);

  VALUE res = rb_ary_new_capa(length);
  for (uint32_t i = 0; i < length; i++) {
    rb_ary_store(res, i, new_range(&ranges[i]));
  }

  return res;
}

static VALUE parser_get_timeout_micros(VALUE self) {
  TSParser *parser;
  Data_Get_Struct(self, TSParser, parser);

  uint64_t timeout = ts_parser_timeout_micros(parser);
  VALUE res = ULL2NUM(timeout);

  return res;
}

static VALUE parser_set_language(VALUE self, VALUE lang) {
  TSParser *parser;
  TSLanguage *language;

  Data_Get_Struct(self, TSParser, parser);
  Data_Get_Struct(self, TSLanguage, language);

  return ts_parser_set_language(parser, language) ? Qtrue : Qfalse;
}

static VALUE parser_set_included_ranges(VALUE self, VALUE array) {
  Check_Type(array, T_ARRAY);

  TSParser *parser;
  Data_Get_Struct(self, TSParser, parser);

  long length = rb_array_len(array);
  TSRange *ranges = (TSRange *)malloc(length * sizeof(TSRange));
  for (int i = 0; i < length; i++) {
    TSRange *range;
    Data_Get_Struct(rb_ary_entry(array, i), TSRange, range);

    memcpy(&ranges[i], (void *)range, sizeof(TSRange));
  }

  bool res = ts_parser_set_included_ranges(parser, ranges, (uint32_t)length);
  free(ranges);

  return res ? Qtrue : Qfalse;
}

static VALUE parser_set_timeout_micros(VALUE self, VALUE timeout) {
  TSParser *parser;
  Data_Get_Struct(self, TSParser, parser);

  uint64_t t = NUM2ULL(timeout);
  ts_parser_set_timeout_micros(parser, t);

  return Qnil;
}

static VALUE parser_parse(VALUE self, VALUE old_tree, VALUE input) {
  TSParser *parser;
  TSTree *tree = NULL;
  TSInput *in;
  Data_Get_Struct(self, TSParser, parser);
  if (!NIL_P(old_tree)) {
    Data_Get_Struct(old_tree, TSTree, tree);
  }
  Data_Get_Struct(input, TSInput, in);

  return new_tree(ts_parser_parse(parser, tree, *in));
}

static VALUE parser_parse_string(VALUE self, VALUE old_tree, VALUE string) {
  TSParser *parser;
  TSTree *tree = NULL;
  Data_Get_Struct(self, TSParser, parser);
  if (!NIL_P(old_tree)) {
    Data_Get_Struct(old_tree, TSTree, tree);
  }

  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);

  return new_tree(ts_parser_parse_string(parser, tree, str, len));
}

static VALUE parser_parse_string_encoding(VALUE self, VALUE old_tree,
                                          VALUE string, VALUE encoding) {
  TSParser *parser;
  TSTree *tree = NULL;
  TSInputEncoding *enc;
  Data_Get_Struct(self, TSParser, parser);
  if (!NIL_P(old_tree)) {
    Data_Get_Struct(old_tree, TSTree, tree);
  }
  Data_Get_Struct(encoding, TSInputEncoding, enc);

  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);

  return new_tree(
      ts_parser_parse_string_encoding(parser, tree, str, len, *enc));
}

static VALUE parser_reset(VALUE self) {
  TSParser *parser;
  Data_Get_Struct(self, TSParser, parser);

  ts_parser_reset(parser);

  return Qnil;
}

void init_parser(void) {
  cParser = rb_define_class_under(mTreeSitter, "Parser", rb_cObject);

  /* Class methods */
  rb_define_alloc_func(cParser, parser_allocate);
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
}
