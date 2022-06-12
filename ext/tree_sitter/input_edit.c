#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cInputEdit;

DATA_WRAP(InputEdit, input_edit)
DATA_ACCESSOR(input_edit, start_byte, INT2NUM, NUM2INT)
DATA_ACCESSOR(input_edit, old_end_byte, INT2NUM, NUM2INT)
DATA_ACCESSOR(input_edit, new_end_byte, INT2NUM, NUM2INT)
DATA_ACCESSOR(input_edit, start_point, new_point_by_val, value_to_point)
DATA_ACCESSOR(input_edit, old_end_point, new_point_by_val, value_to_point)
DATA_ACCESSOR(input_edit, new_end_point, new_point_by_val, value_to_point)

static VALUE input_edit_inspect(VALUE self) {
  input_edit_t *input_edit = unwrap(self);
  return rb_sprintf("{start_byte=%i, old_end_byte=%i , new_end_byte=%i, "
                    "start_point=%+" PRIsVALUE ", old_end_point=%+" PRIsVALUE
                    ", new_end_point=%+" PRIsVALUE "}",
                    input_edit->data.start_byte, input_edit->data.old_end_byte,
                    input_edit->data.new_end_byte,
                    new_point_by_val(input_edit->data.start_point),
                    new_point_by_val(input_edit->data.old_end_point),
                    new_point_by_val(input_edit->data.new_end_point));
}

void init_input_edit(void) {
  cInputEdit = rb_define_class_under(mTreeSitter, "InputEdit", rb_cObject);

  rb_define_alloc_func(cInputEdit, input_edit_allocate);

  /* Class methods */
  DEFINE_ACCESSOR(cInputEdit, input_edit, start_byte)
  DEFINE_ACCESSOR(cInputEdit, input_edit, old_end_byte)
  DEFINE_ACCESSOR(cInputEdit, input_edit, new_end_byte)
  DEFINE_ACCESSOR(cInputEdit, input_edit, start_point)
  DEFINE_ACCESSOR(cInputEdit, input_edit, old_end_point)
  DEFINE_ACCESSOR(cInputEdit, input_edit, new_end_point)

  rb_define_method(cInputEdit, "inspect", input_edit_inspect, 0);
  rb_define_method(cInputEdit, "to_s", input_edit_inspect, 0);
}
