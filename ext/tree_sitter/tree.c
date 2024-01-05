#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTree;

int tree_rc_free(const TSTree *tree) {
  VALUE ptr = ULONG2NUM((uintptr_t)tree);
  VALUE rc = rb_cv_get(cTree, "@@rc");
  VALUE val = rb_hash_lookup(rc, ptr);

  if (!NIL_P(val)) {
    unsigned int count = NUM2UINT(val);
    --count;
    if (count < 1) {
      rb_hash_delete(rc, ptr);
      ts_tree_delete((TSTree *)tree);
      return 1;
    } else {
      rb_hash_aset(rc, ptr, ULONG2NUM(count));
      return 0;
    }
  } else {
    return 1;
  }
}

void tree_rc_new(const TSTree *tree) {
  VALUE ptr = ULONG2NUM((uintptr_t)tree);
  VALUE rc = rb_cv_get(cTree, "@@rc");
  VALUE val = rb_hash_lookup(rc, ptr);

  if (NIL_P(val)) {
    rb_hash_aset(rc, ptr, UINT2NUM(1));
  } else {
    rb_hash_aset(rc, ptr, UINT2NUM(NUM2UINT(val) + 1));
  }
}

DATA_TYPE(TSTree *, tree)
static void tree_free(void *ptr) {
  tree_t *type = (tree_t *)ptr;
  if (tree_rc_free(type->data)) {
    xfree(ptr);
  }
}

DATA_MEMSIZE(tree)
DATA_DECLARE_DATA_TYPE(tree)
DATA_ALLOCATE(tree)
DATA_UNWRAP(tree)

VALUE new_tree(TSTree *ptr) {
  if (ptr == NULL) {
    return Qnil;
  }
  VALUE res = tree_allocate(cTree);
  tree_t *type = unwrap(res);
  type->data = ptr;
  tree_rc_new(ptr);
  return res;
}

DATA_FROM_VALUE(TSTree *, tree)

/**
 * Create a shallow copy of the syntax tree. This is very fast.
 *
 * You need to copy a syntax tree in order to use it on more than one thread at
 * a time, as syntax trees are not thread safe.
 *
 * @return [Tree]
 */
static VALUE tree_copy(VALUE self) { return new_tree(ts_tree_copy(SELF)); }

/**
 * Get the root node of the syntax tree.
 *
 * @return [Node]
 */
static VALUE tree_root_node(VALUE self) {
  return new_node_by_val(ts_tree_root_node(SELF));
}

/**
 * Get the language that was used to parse the syntax tree.
 *
 * @return [Language]
 */
static VALUE tree_language(VALUE self) {
  return new_language(ts_tree_language(SELF));
}

/**
 * Edit the syntax tree to keep it in sync with source code that has been
 * edited.
 *
 * You must describe the edit both in terms of byte offsets and in terms of
 * (row, column) coordinates.
 *
 * @param edit [InputEdit]
 *
 * @return [nil]
 */
static VALUE tree_edit(VALUE self, VALUE edit) {
  TSInputEdit in = value_to_input_edit(edit);
  ts_tree_edit(SELF, &in);
  return Qnil;
}

/**
 * Compare an old edited syntax tree to a new syntax tree representing the same
 * document, returning an array of ranges whose syntactic structure has changed.
 *
 * For this to work correctly, the old syntax tree must have been edited such
 * that its ranges match up to the new tree. Generally, you'll want to call
 * this function right after calling one of the {Parser#parse} functions.
 * You need to pass the old tree that was passed to parse, as well as the new
 * tree that was returned from that function.
 *
 * @param old_tree [Tree]
 * @param new_tree [Tree]
 *
 * @return [Array<Range>]
 */
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

/**
 * Write a DOT graph describing the syntax tree to the given file.
 *
 * @param file [String]
 *
 * @return [nil]
 */
static VALUE tree_print_dot_graph(VALUE self, VALUE file) {
  Check_Type(file, T_STRING);
  char *path = StringValueCStr(file);
  int fd = open(path, O_CREAT | O_WRONLY | O_TRUNC,
                S_IWUSR | S_IRUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
  if (fd < 0) {
    rb_raise(rb_eRuntimeError, "Could not open file `%s'.\nReason:\n%s", path,
             strerror(fd));
    return Qnil;
  }
  ts_tree_print_dot_graph(SELF, fd);
  close(fd);
  return Qnil;
}

static VALUE tree_finalizer(VALUE _self) {
  VALUE rc = rb_cv_get(cTree, "@@rc");
  VALUE keys = rb_funcall(rc, rb_intern("keys"), 0);
  long len = RARRAY_LEN(keys);

  for (long i = 0; i < len; ++i) {
    VALUE curr = RARRAY_AREF(keys, i);
    unsigned int val = NUM2UINT(rb_hash_lookup(rc, curr));
    if (val > 0) {
      ts_tree_delete((TSTree *)NUM2ULONG(curr));
    }

    rb_hash_delete(rc, curr);
  }

  return Qnil;
}

// FIXME: missing:
// 1. ts_tree_root_node_with_offset
// 1. ts_tree_included_ranges
void init_tree(void) {
  cTree = rb_define_class_under(mTreeSitter, "Tree", rb_cObject);

  rb_undef_alloc_func(cTree);

  /* Class methods */
  rb_define_method(cTree, "copy", tree_copy, 0);
  rb_define_method(cTree, "root_node", tree_root_node, 0);
  rb_define_method(cTree, "language", tree_language, 0);
  rb_define_method(cTree, "edit", tree_edit, 1);
  rb_define_module_function(cTree, "changed_ranges", tree_changed_ranges, 2);
  rb_define_method(cTree, "print_dot_graph", tree_print_dot_graph, 1);
  rb_define_module_function(cTree, "finalizer", tree_finalizer, 0);

  // Reference-count created trees
  VALUE rc = rb_hash_new();
  rb_cv_set(cTree, "@@rc", rc);
}
