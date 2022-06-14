#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cPoint;

DATA_WRAP(Point, point)
DATA_DEFINE_ACCESSOR(point, row, UINT2NUM, NUM2UINT)
DATA_DEFINE_ACCESSOR(point, column, UINT2NUM, NUM2UINT)

static VALUE point_inspect(VALUE self) {
  point_t *point = unwrap(self);
  return rb_sprintf("{row=%i, column=%i}", point->data.row, point->data.column);
}

void init_point(void) {
  cPoint = rb_define_class_under(mTreeSitter, "Point", rb_cObject);

  rb_define_alloc_func(cPoint, point_allocate);

  /* Class methods */
  DECLARE_ACCESSOR(cPoint, point, row)
  DECLARE_ACCESSOR(cPoint, point, column)
  rb_define_method(cPoint, "inspect", point_inspect, 0);
  rb_define_method(cPoint, "to_s", point_inspect, 0);
}
