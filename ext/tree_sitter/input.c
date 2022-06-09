#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cInput;

TSInput *value_to_input(VALUE self) {
  TSInput *input;

  Data_Get_Struct(self, TSInput, input);

  return input;
}

VALUE new_input(const TSInput *tree) {
  return Data_Wrap_Struct(cInput, NULL, NULL, (void *)tree);
}

void init_input(void) {
  cInput = rb_define_class_under(mTreeSitter, "Input", rb_cObject);
}
