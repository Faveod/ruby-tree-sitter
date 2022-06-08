
#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cRange;

VALUE new_range(const TSRange *range) {
  return Data_Wrap_Struct(cRange, NULL, NULL, (void *)range);
}

void init_range(void) {
  cRange = rb_define_class_under(mTreeSitter, "Range", rb_cObject);
}
