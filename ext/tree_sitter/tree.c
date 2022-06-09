#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTree;

/*
** TSTree is special. You cannot construct it with ts_tree_new for example, so
** we can't just * assign a free method to its Ruby wrapper.
**
** However, it has a ts_tree_delete! So we're going to include it because it's
** int he public * API, but not as a normal Ruby method `delete` instead of a
** Ruby Object free hook.
*/

TSTree *value_to_tree(VALUE self) {
  TSTree *tree = NULL;

  if (!NIL_P(self)) {
    Data_Get_Struct(self, TSTree, tree);
  }

  return tree;
}

VALUE new_tree(const TSTree *tree) {
  return Data_Wrap_Struct(cTree, NULL, NULL, (void *)tree);
}

VALUE tree_copy(VALUE self) { return Qnil; }

void init_tree(void) {
  cTree = rb_define_class_under(mTreeSitter, "Tree", rb_cObject);

  /* Class methods */
  rb_define_method(cTree, "copy", tree_copy, 0);
}
