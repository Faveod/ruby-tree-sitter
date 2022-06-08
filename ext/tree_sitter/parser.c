#include "tree_sitter.h"

extern VALUE rb_mTreeSitter;

VALUE rb_cParser;

void rb_parser_free(TSParser *parser) { ts_parser_delete(parser); }

static VALUE rb_parser_allocate(VALUE klass) {
  TSParser *parser;
  parser = ts_parser_new();
  return Data_Wrap_Struct(klass, NULL, rb_parser_free, parser);
}

/* static VALUE rb_parser_initialize(int argc, VALUE *argv, VALUE self) { */

/* } */

void init_parser(void) {
  rb_cParser = rb_define_class_under(rb_mTreeSitter, "Parser", rb_cObject);

  /* Class methods */
  rb_define_alloc_func(rb_cParser, rb_parser_allocate);
  /* Initialize method */
  /* rb_define_method(rb_cParser, "initialize", rb_parser_initialize, -1); */
}
