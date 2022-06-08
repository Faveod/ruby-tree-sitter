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

static VALUE parser_set_language(VALUE self, VALUE lang) {
  TSParser *parser;
  TSLanguage *language;

  Data_Get_Struct(self, TSParser, parser);
  Data_Get_Struct(self, TSLanguage, language);

  return ts_parser_set_language(parser, language) ? Qtrue : Qfalse;
}

void init_parser(void) {
  cParser = rb_define_class_under(mTreeSitter, "Parser", rb_cObject);

  /* Class methods */
  rb_define_alloc_func(cParser, parser_allocate);
  rb_define_method(cParser, "language", parser_get_language, 0);
  rb_define_method(cParser, "language=", parser_set_language, 1);
}
