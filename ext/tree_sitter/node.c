#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cNode;

void node_free(TSNode *node) { free(node); }

TSNode *value_to_node(VALUE self) {
  TSNode *node;

  Data_Get_Struct(self, TSNode, node);

  return node;
}

VALUE new_node(const TSNode *node) {
  TSNode *ptr = (TSNode *)malloc(sizeof(TSNode));
  memcpy(ptr, node, sizeof(TSNode));
  return Data_Wrap_Struct(cNode, NULL, node_free, ptr);
}

VALUE node_type(VALUE self) {
  TSNode *node = value_to_node(self);

  return rb_str_new_cstr(ts_node_type(*node));
}

VALUE node_symbol(VALUE self) {
  TSNode *node = value_to_node(self);

  return INT2NUM(ts_node_symbol(*node));
}

VALUE node_start_byte(VALUE self) {
  TSNode *node = value_to_node(self);

  return INT2NUM(ts_node_start_byte(*node));
}

void init_node(void) {
  cNode = rb_define_class_under(mTreeSitter, "Node", rb_cObject);

  /* Class methods */
  rb_define_method(cNode, "type", node_type, 0);
  rb_define_method(cNode, "symbol", node_symbol, 0);
  rb_define_method(cNode, "start_byte", node_start_byte, 0);
}
