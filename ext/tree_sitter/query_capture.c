#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryCapture;

DATA_WRAP(QueryCapture, query_capture)
DATA_GETTER(query_capture, index, INT2NUM)
DATA_GETTER(query_capture, node, new_node_by_val)

void init_query_capture(void) {
  cQueryCapture =
      rb_define_class_under(mTreeSitter, "QueryCapture", rb_cObject);

  rb_define_alloc_func(cQueryCapture, query_capture_allocate);

  /* Class methods */
  DEFINE_GETTER(cQueryCapture, query_capture, index)
  DEFINE_GETTER(cQueryCapture, query_capture, node)
}
