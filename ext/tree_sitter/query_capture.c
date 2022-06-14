#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryCapture;

DATA_WRAP(QueryCapture, query_capture)
DATA_DEFINE_GETTER(query_capture, index, INT2NUM)
DATA_DEFINE_GETTER(query_capture, node, new_node_by_val)

static VALUE query_capture_inspect(VALUE self) {
  TSQueryCapture query_capture = SELF;
  return rb_sprintf("{index=%d, node=%+" PRIsVALUE "}", query_capture.index,
                    new_node(&query_capture.node));
}

void init_query_capture(void) {
  cQueryCapture =
      rb_define_class_under(mTreeSitter, "QueryCapture", rb_cObject);

  rb_define_alloc_func(cQueryCapture, query_capture_allocate);

  /* Class methods */
  DECLARE_GETTER(cQueryCapture, query_capture, index)
  DECLARE_GETTER(cQueryCapture, query_capture, node)
  rb_define_method(cQueryCapture, "inspect", query_capture_inspect, 0);
  rb_define_method(cQueryCapture, "to_s", query_capture_inspect, 0);
}
