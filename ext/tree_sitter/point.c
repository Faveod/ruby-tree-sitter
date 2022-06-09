#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cPoint;

TSPoint *value_to_point(VALUE self) {
  TSPoint *point;

  Data_Get_Struct(self, TSPoint, point);

  return point;
}

void point_free(TSPoint *point) { free(point); }

static VALUE point_allocate(VALUE klass) {
  TSPoint *point = (TSPoint *)malloc(sizeof(TSPoint));
  return Data_Wrap_Struct(klass, NULL, point_free, point);
}

VALUE new_point(const TSPoint *point) {
  VALUE res = point_allocate(cPoint);
  TSPoint *ptr = value_to_point(res);

  memcpy(ptr, point, sizeof(TSPoint));

  return res;
}

void init_point(void) {
  cPoint = rb_define_class_under(mTreeSitter, "Point", rb_cObject);

  rb_define_alloc_func(cPoint, point_allocate);
}
