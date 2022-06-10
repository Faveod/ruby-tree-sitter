#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cPoint;

TSPoint *value_to_point(VALUE self) {
  TSPoint *point;

  Data_Get_Struct(self, TSPoint, point);

  return point;
}

static void point_free(TSPoint *point) { free(point); }

static VALUE point_allocate(VALUE klass) {
  TSPoint *point = (TSPoint *)malloc(sizeof(TSPoint));
  return Data_Wrap_Struct(klass, NULL, point_free, point);
}

VALUE new_point(const TSPoint *point) {
  VALUE res = point_allocate(cPoint);
  TSPoint *ptr = value_to_point(res);

  *ptr = *point;

  return res;
}

static VALUE point_row(VALUE self) {
  TSPoint *point = value_to_point(self);

  return INT2NUM(point->row);
}

static VALUE point_column(VALUE self) {
  TSPoint *point = value_to_point(self);

  return INT2NUM(point->column);
}

static VALUE point_inspect(VALUE self) {
  TSPoint *point = value_to_point(self);

  return rb_sprintf("{row=%d, column=%d}", point->row, point->column);
}

void init_point(void) {
  cPoint = rb_define_class_under(mTreeSitter, "Point", rb_cObject);

  rb_define_alloc_func(cPoint, point_allocate);

  /* Class methods */
  rb_define_method(cPoint, "row", point_row, 0);
  rb_define_method(cPoint, "column", point_column, 0);
  rb_define_method(cPoint, "inspect", point_inspect, 0);
  rb_define_method(cPoint, "to_s", point_inspect, 0);
}
