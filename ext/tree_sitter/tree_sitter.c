#include "tree_sitter.h"

VALUE mTreeSitter;

void Init_tree_sitter() {
  mTreeSitter = rb_define_module("TreeSitter");

  init_encoding();
  init_input();
  init_logger();
  init_language();
  init_parser();
  init_quantifier();
  init_query();
  init_query_cursor();
  init_query_predicate_step();
  init_query_error();
  init_range();
  init_tree();
  init_tree_cursor();
}
