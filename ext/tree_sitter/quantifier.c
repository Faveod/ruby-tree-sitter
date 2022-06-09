#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE mQuantifier;

TSQuantifier value_to_quantifier(VALUE quantifier) {
  return NUM2INT(quantifier);
}

const char *quantifier_name(TSQuantifier error) {
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
  rb_define_const(mQuantifier, "Zero", INT2NUM(0));
  rb_define_const(mQuantifier, "ZeroOrOne", INT2NUM(1));
  rb_define_const(mQuantifier, "ZeroOrMore", INT2NUM(2));
  rb_define_const(mQuantifier, "One", INT2NUM(3));
  rb_define_const(mQuantifier, "OneOrMore", INT2NUM(4));
}
