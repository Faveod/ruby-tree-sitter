#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryMatch;

TSQueryMatch *value_to_query_match(VALUE self) {
  TSQueryMatch *query_match;

  Data_Get_Struct(self, TSQueryMatch, query_match);

  return query_match;
}

VALUE new_query_match(const TSQueryMatch *tree) {
  return Data_Wrap_Struct(cQueryMatch, NULL, NULL, (void *)tree);
}

void init_query_match(void) {
  cQueryMatch = rb_define_class_under(mTreeSitter, "QueryMatch", rb_cObject);
}
