#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTree;

VALUE new_tree(const TSTree *tree) {
  return Data_Wrap_Struct(cTree, NULL, NULL, (void *)tree);
}

void init_tree(void) {
  cTree = rb_define_class_under(mTreeSitter, "Tree", rb_cObject);
}
