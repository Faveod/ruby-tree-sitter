#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryPredicateStep;

const char *done = "Done";
const char *capture = "capture";
const char *string = "String";

DATA_WRAP(cQueryPredicateStep, TSQueryPredicateStep, query_predicate_step)

VALUE new_query_predicate_step_type(TSQueryPredicateStepType type) {
  switch (type) {
  case TSQueryPredicateStepTypeDone:
    return ID2SYM(rb_intern(done));
  case TSQueryPredicateStepTypeCapture:
    return ID2SYM(rb_intern(capture));
  case TSQueryPredicateStepTypeString:
    return ID2SYM(rb_intern(string));
  default:
    return Qnil;
  }
}

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

DATA_ACCESSOR(query_predicate_step, type, new_query_predicate_step_type,
              value_to_query_predicate_step_type)
DATA_ACCESSOR(query_predicate_step, value_id, INT2NUM, NUM2INT)

void init_query_predicate_step(void) {
  cQueryPredicateStep =
      rb_define_module_under(mTreeSitter, "QueryPredicateStep");

  /* Constants */
  rb_define_const(cQueryPredicateStep, "DONE", ID2SYM(rb_intern(done)));
  rb_define_const(cQueryPredicateStep, "CAPTURE", ID2SYM(rb_intern(capture)));
  rb_define_const(cQueryPredicateStep, "STRING", ID2SYM(rb_intern(string)));

  /* Class methods */
  DEFINE_ACCESSOR(cQueryPredicateStep, query_predicate_step, type)
  DEFINE_ACCESSOR(cQueryPredicateStep, query_predicate_step, value_id)
}
