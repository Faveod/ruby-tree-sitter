#include "tree_sitter.h"

VALUE mTreeSitter;

void Init_tree_sitter() {
  mTreeSitter = rb_define_module("TreeSitter");

  init_parser();
  init_language();
  init_range();
}
