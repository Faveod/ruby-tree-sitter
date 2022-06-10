#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cPoint;

// This wrapper's raison d'etre is to avoid conversion and construction of Ruby
// VALUEs when accessing members.
typedef struct {
  TSPoint data;
} point_t;

static size_t point_memsize(const void *ptr) {
  point_t *point = (point_t *)ptr;
  return sizeof(point);
}

static void point_free(void *ptr) { xfree(ptr); }

const rb_data_type_t point_data_type = {
    .wrap_struct_name = "point",
    .function =
        {
            .dmark = NULL,
            .dfree = point_free,
            .dsize = point_memsize,
            .dcompact = NULL,
        },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE point_allocate(VALUE klass) {
  point_t *point;
  return TypedData_Make_Struct(klass, point_t, &point_data_type, point);
}

TSPoint value_to_point(VALUE self) {
  point_t *point;
  TypedData_Get_Struct(self, point_t, &point_data_type, point);

  return point->data;
}

static VALUE point_inspect(VALUE self) {
  point_t *point;

  TypedData_Get_Struct(self, point_t, &point_data_type, point);

  return rb_sprintf("{row=%i, column=%i}", point->data.row, point->data.column);
}

DATA_NEW(cPoint, TSPoint, point)
DATA_ACCESSOR(point, row, INT2NUM, NUM2INT)
DATA_ACCESSOR(point, column, INT2NUM, NUM2INT)

void init_point(void) {
  cPoint = rb_define_class_under(mTreeSitter, "Point", rb_cObject);

  rb_define_alloc_func(cPoint, point_allocate);

  /* Class methods */
  DEFINE_ACCESSOR(cPoint, point, row)
  DEFINE_ACCESSOR(cPoint, point, column)
  rb_define_method(cPoint, "inspect", point_inspect, 0);
  rb_define_method(cPoint, "to_s", point_inspect, 0);
}
