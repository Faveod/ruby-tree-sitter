#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cInputEdit;

// This wrapper's raison d'etre is to avoid conversion and construction of Ruby
// VALUEs when accessing members.
typedef struct {
  VALUE start_byte;
  VALUE old_end_byte;
  VALUE new_end_byte;
  VALUE start_point;
  VALUE old_end_point;
  VALUE new_end_point;
} input_edit_t;

static size_t input_edit_memsize(const void *ptr) {
  input_edit_t *input_edit = (input_edit_t *)ptr;
  return sizeof(input_edit);
}

static void input_edit_mark(void *ptr) {
  input_edit_t *input_edit = (input_edit_t *)ptr;
  rb_gc_mark_movable(input_edit->start_byte);
  rb_gc_mark_movable(input_edit->old_end_byte);
  rb_gc_mark_movable(input_edit->new_end_byte);
  rb_gc_mark_movable(input_edit->start_point);
  rb_gc_mark_movable(input_edit->old_end_point);
  rb_gc_mark_movable(input_edit->new_end_point);
}

static void input_edit_free(void *ptr) { xfree(ptr); }

const rb_data_type_t input_edit_data_type = {
    .wrap_struct_name = "input_edit",
    .function =
        {
            .dmark = input_edit_mark,
            .dfree = input_edit_free,
            .dsize = input_edit_memsize,
            .dcompact = NULL,
        },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE input_edit_allocate(VALUE klass) {
  input_edit_t *input_edit;

  VALUE res = TypedData_Make_Struct(klass, input_edit_t, &input_edit_data_type,
                                    input_edit);

  input_edit->start_byte = Qnil;
  input_edit->old_end_byte = Qnil;
  input_edit->new_end_byte = Qnil;
  input_edit->start_point = Qnil;
  input_edit->old_end_point = Qnil;
  input_edit->new_end_point = Qnil;

  return res;
}

TSInputEdit value_to_input_edit(VALUE self) {
  input_edit_t *input_edit;

  TypedData_Get_Struct(self, input_edit_t, &input_edit_data_type, input_edit);

  TSInputEdit res = {
      .start_byte = NUM2INT(input_edit->start_byte),
      .old_end_byte = NUM2INT(input_edit->old_end_byte),
      .new_end_byte = NUM2INT(input_edit->new_end_byte),
      .start_point = *value_to_point(input_edit->start_point),
      .old_end_point = *value_to_point(input_edit->old_end_point),
      .new_end_point = *value_to_point(input_edit->new_end_point),
  };

  return res;
}

VALUE new_input_edit(const TSInputEdit *input_edit) {
  VALUE val = input_edit_allocate(cInputEdit);
  input_edit_t *obj;

  TypedData_Get_Struct(cInputEdit, input_edit_t, &input_edit_data_type, obj);

  obj->start_byte = NUM2INT(input_edit->start_byte);
  obj->old_end_byte = NUM2INT(input_edit->old_end_byte);
  obj->new_end_byte = NUM2INT(input_edit->new_end_byte);
  obj->start_point = new_point(&input_edit->start_point);
  obj->old_end_point = new_point(&input_edit->old_end_point);
  obj->new_end_point = new_point(&input_edit->new_end_point);

  return val;
}

static VALUE input_edit_inspect(VALUE self) {
  input_edit_t *input_edit;

  TypedData_Get_Struct(self, input_edit_t, &input_edit_data_type, input_edit);
  return rb_sprintf("{start_byte=%+" PRIsVALUE ", old_end_byte=%+" PRIsVALUE
                    ", new_end_byte=%+" PRIsVALUE ", start_point=%+" PRIsVALUE
                    ", old_end_point=%+" PRIsVALUE
                    ", new_end_point=%+" PRIsVALUE "}",
                    input_edit->start_byte, input_edit->old_end_byte,
                    input_edit->new_end_byte, input_edit->start_point,
                    input_edit->old_end_point, input_edit->new_end_byte);
}

ACCESSOR(input_edit, start_byte)
ACCESSOR(input_edit, old_end_byte)
ACCESSOR(input_edit, new_end_byte)
ACCESSOR(input_edit, start_point)
ACCESSOR(input_edit, old_end_point)
ACCESSOR(input_edit, new_end_point)

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
