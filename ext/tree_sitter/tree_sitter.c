#include "tree_sitter.h"

VALUE rb_mTreeSitter;

void Init_tree_sitter() {
  rb_mTreeSitter = rb_define_module("TreeSitter");

  init_parser();
}
