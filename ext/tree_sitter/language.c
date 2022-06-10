#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cLanguage;

TSLanguage *value_to_language(VALUE self) {
  TSLanguage *language;

  Data_Get_Struct(self, TSLanguage, language);

  return language;
}

VALUE new_language(const TSLanguage *language) {
  return Data_Wrap_Struct(cLanguage, NULL, NULL, (void *)language);
}

static VALUE language_symbol_count(VALUE self) {
  TSLanguage *language = value_to_language(self);
  return INT2NUM(ts_language_symbol_count(language));
}

void init_language(void) {
  cLanguage = rb_define_class_under(mTreeSitter, "Language", rb_cObject);

  /* Class methods */
  rb_define_method(cLanguage, "symbol_count", language_symbol_count, 0);
}
