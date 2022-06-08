#include "tree_sitter.h"

static VALUE hello_world(VALUE mod) { return rb_str_new2("hello world"); }

void Init_tree_sitter() {
  TreeSitter = rb_define_module("TreeSitter");
  rb_define_singleton_method(TreeSitter, "hello_world", hello_world, 0);
}
