#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cRange;

// This wrapper's raison d'etre is to avoid conversion and construction of Ruby
// VALUEs when accessing members.
typedef struct {
  VALUE start_point;
  VALUE end_point;
  VALUE start_byte;
  VALUE end_byte;
} range_t;

static size_t range_memsize(const void *ptr) {
  range_t *range = (range_t *)ptr;
  return sizeof(range);
}

static void range_mark(void *ptr) {
  range_t *range = (range_t *)ptr;
  rb_gc_mark_movable(range->start_point);
  rb_gc_mark_movable(range->end_point);
  rb_gc_mark_movable(range->start_byte);
  rb_gc_mark_movable(range->end_byte);
}

static void range_free(void *ptr) { xfree(ptr); }

const rb_data_type_t range_data_type = {
    .wrap_struct_name = "range",
    .function =
        {
            .dmark = range_mark,
            .dfree = range_free,
            .dsize = range_memsize,
            .dcompact = NULL,
        },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE range_allocate(VALUE klass) {
  range_t *range;

  VALUE res = TypedData_Make_Struct(klass, range_t, &range_data_type, range);

  range->start_point = Qnil;
  range->end_point = Qnil;
  range->start_byte = Qnil;
  range->end_byte = Qnil;

  return res;
}

TSRange value_to_range(VALUE self) {
  range_t *range;

  TypedData_Get_Struct(self, range_t, &range_data_type, range);

  TSRange res = {
      .start_point = *value_to_point(range->start_point),
      .end_point = *value_to_point(range->end_point),
      .start_byte = NUM2INT(range->start_byte),
      .end_byte = NUM2INT(range->end_byte),
  };

  return res;
}

VALUE new_range(const TSRange *range) {
  VALUE val = range_allocate(cRange);
  range_t *obj;

  TypedData_Get_Struct(cRange, range_t, &range_data_type, obj);

  obj->start_point = new_point(&range->start_point);
  obj->end_point = new_point(&range->end_point);
  obj->start_byte = NUM2INT(range->start_byte);
  obj->end_byte = NUM2INT(range->end_byte);

  return val;
}

static VALUE range_inspect(VALUE self) {
  range_t *range;

  TypedData_Get_Struct(self, range_t, &range_data_type, range);
  return rb_sprintf("{start_point= %+" PRIsVALUE ", end_point=%+" PRIsVALUE
                    ", start_byte=%+" PRIsVALUE ", end_byte=%+" PRIsVALUE "}",
                    range->start_point, range->end_point, range->start_byte,
                    range->end_byte);
}

void init_range(void) {
  cRange = rb_define_class_under(mTreeSitter, "Range", rb_cObject);

  rb_define_alloc_func(cRange, range_allocate);

  /* Class methods */
  rb_define_method(cRange, "inspect", range_inspect, 0);
  rb_define_method(cRange, "to_s", range_inspect, 0);
}
