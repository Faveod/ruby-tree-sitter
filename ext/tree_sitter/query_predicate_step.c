#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryPredicateStep;

const char *done = "Done";
const char *capture = "capture";
const char *string = "String";

TSQueryPredicateStepType value_to_query_predicate_step_type(VALUE step_type) {
  VALUE type = SYM2ID(step_type);
  VALUE c = rb_const_get_at(cQueryPredicateStep, rb_intern(capture));
  VALUE s = rb_const_get_at(cQueryPredicateStep, rb_intern(string));

  // NOTE: should we emit a warning instead of defaulting to done?
  if (type == c) {
    return TSQueryPredicateStepTypeCapture;
  } else if (type == s) {
    return TSQueryPredicateStepTypeString;
  } else {
    return TSQueryPredicateStepTypeDone;
  }
}

TSQueryPredicateStep *value_to_query_predicate_step(VALUE self) {
  TSQueryPredicateStep *step;

  Data_Get_Struct(self, TSQueryPredicateStep, step);

  return step;
}

VALUE new_query_predicate_step(const TSQueryPredicateStep *step) {
  return Data_Wrap_Struct(cQueryPredicateStep, NULL, NULL, (void *)step);
}

void init_query_predicate_step(void) {
  cQueryPredicateStep =
      rb_define_module_under(mTreeSitter, "QueryPredicateStep");

  /* Constants */
  rb_define_const(cQueryPredicateStep, "DONE", ID2SYM(rb_intern(done)));
  rb_define_const(cQueryPredicateStep, "CAPTURE", ID2SYM(rb_intern(capture)));
  rb_define_const(cQueryPredicateStep, "STRING", ID2SYM(rb_intern(string)));
}
