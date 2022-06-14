#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE mQuantifier;

TSQuantifier value_to_quantifier(VALUE quantifier) {
  return NUM2INT(quantifier);
}

const char *quantifier_str(TSQuantifier error) {
  switch (error) {
  case TSQuantifierZero:
    return "Zero";
  case TSQuantifierZeroOrOne:
    return "ZeroOrOne";
  case TSQuantifierZeroOrMore:
    return "ZeroOrMore";
  case TSQuantifierOne:
    return "One";
  case TSQuantifierOneOrMore:
    return "OneOrMore";
  default:
    return "??";
  }
}

void init_quantifier(void) {
  mQuantifier = rb_define_module_under(mTreeSitter, "Quantifier");
  rb_define_const(mQuantifier, "ZERO", INT2NUM(0));
  rb_define_const(mQuantifier, "ZERO_OR_ONE", INT2NUM(1));
  rb_define_const(mQuantifier, "ZERO_OR_MORE", INT2NUM(2));
  rb_define_const(mQuantifier, "ONE", INT2NUM(3));
  rb_define_const(mQuantifier, "ONE_OR_MORE", INT2NUM(4));
}
