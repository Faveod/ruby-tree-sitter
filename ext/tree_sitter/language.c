#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cLanguage;

VALUE new_language(const TSLanguage *language) {
  return Data_Wrap_Struct(cLanguage, NULL, NULL, (void *)language);
}

void init_language(void) {
  cLanguage = rb_define_class_under(mTreeSitter, "Language", rb_cObject);
}
