#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cInput;

VALUE new_input(const TSInput *tree) {
  return Data_Wrap_Struct(cInput, NULL, NULL, (void *)tree);
}

void init_input(void) {
  cInput = rb_define_class_under(mTreeSitter, "Input", rb_cObject);
}
