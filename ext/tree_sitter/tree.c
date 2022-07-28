#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTree;

DATA_PTR_WRAP(Tree, tree)

static VALUE tree_copy(VALUE self) { return new_tree(ts_tree_copy(SELF)); }

static VALUE tree_root_node(VALUE self) {
  return new_node_by_val(ts_tree_root_node(SELF));
}

static VALUE tree_language(VALUE self) {
  return new_language(ts_tree_language(SELF));
}

static VALUE tree_edit(VALUE self, VALUE edit) {
  TSInputEdit in = value_to_input_edit(edit);
  ts_tree_edit(SELF, &in);
  return Qnil;
}

static VALUE tree_changed_ranges(VALUE _self, VALUE old_tree, VALUE new_tree) {
  TSTree *old = unwrap(old_tree)->data;
  TSTree *new = unwrap(new_tree)->data;
  uint32_t length;
  TSRange *ranges = ts_tree_get_changed_ranges(old, new, &length);
  VALUE res = rb_ary_new_capa(length);

  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_range(&ranges[i]));
  }

  if (ranges) {
    free(ranges);
  }

  return res;
}

static VALUE tree_print_dot_graph(VALUE self, VALUE file) {
  Check_Type(file, T_STRING);
  char *path = StringValueCStr(file);
  FILE *fd = fopen(path, "w+");
  ts_tree_print_dot_graph(SELF, fd);
  fclose(fd);
  return Qnil;
}

void init_tree(void) {
  cTree = rb_define_class_under(mTreeSitter, "Tree", rb_cObject);

  /* Class methods */
  rb_define_method(cTree, "copy", tree_copy, 0);
  rb_define_method(cTree, "root_node", tree_root_node, 0);
  rb_define_method(cTree, "language", tree_language, 0);
  rb_define_method(cTree, "edit", tree_edit, 1);
  rb_define_module_function(cTree, "changed_ranges", tree_changed_ranges, 2);
  rb_define_method(cTree, "print_dot_graph", tree_print_dot_graph, 1);
}
