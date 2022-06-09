#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cRange;

TSRange *value_to_range(VALUE self) {
  TSRange *range;

  Data_Get_Struct(self, TSRange, range);

  return range;
}

void range_free(TSRange *range) { free(range); }

VALUE new_range(const TSRange *range, bool must_free) {
  return Data_Wrap_Struct(cRange, NULL, must_free ? range_free : NULL,
                          (void *)range);
}

void init_range(void) {
  cRange = rb_define_class_under(mTreeSitter, "Range", rb_cObject);
}
