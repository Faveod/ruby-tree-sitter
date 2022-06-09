#include "tree_sitter.h"

VALUE mTreeSitter;

void Init_tree_sitter() {
  mTreeSitter = rb_define_module("TreeSitter");

  init_encoding();
  init_input();
  init_logger();
  init_language();
  init_parser();
  init_range();
  init_tree();
}
