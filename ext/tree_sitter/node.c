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

void init_node(void) {
  cNode = rb_define_class_under(mTreeSitter, "Node", rb_cObject);
}
