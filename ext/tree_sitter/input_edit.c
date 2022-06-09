#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cInputEdit;

TSInputEdit *value_to_input_edit(VALUE self) {
  TSInputEdit *input_edit;

  Data_Get_Struct(self, TSInputEdit, input_edit);

  return input_edit;
}

void input_edit_free(TSInputEdit *input_edit) { free(input_edit); }

static VALUE input_edit_allocate(VALUE klass) {
  TSInputEdit *input_edit = (TSInputEdit *)malloc(sizeof(TSInputEdit));

  return Data_Wrap_Struct(klass, NULL, input_edit_free, input_edit);
}

VALUE new_input_edit(const TSInputEdit *input_edit) {
  TSInputEdit *ptr = (TSInputEdit *)malloc(sizeof(TSInputEdit));
  memcpy(ptr, input_edit, sizeof(TSInputEdit));
  return Data_Wrap_Struct(cInputEdit, NULL, input_edit_free, ptr);
}

void init_input_edit(void) {
  cInputEdit = rb_define_class_under(mTreeSitter, "InputEdit", rb_cObject);

  rb_define_alloc_func(cInputEdit, input_edit_allocate);
}
