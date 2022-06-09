#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE mQueryError;

TSQueryError value_to_query_error(VALUE query_error) {
  return NUM2INT(query_error);
}

const char *query_error_name(TSQueryError error) {
  switch (error) {
  case TSQueryErrorNone:
    return "None";
  case TSQueryErrorSyntax:
    return "Syntax";
  case TSQueryErrorNodeType:
    return "Node Type";
  case TSQueryErrorField:
    return "Field";
  case TSQueryErrorCapture:
    return "Capture";
  case TSQueryErrorStructure:
    return "Structure";
  case TSQueryErrorLanguage:
    return "Language";
  default:
    return "??";
  }
}

void init_query_error(void) {
  mQueryError = rb_define_module_under(mTreeSitter, "QueryError");
  rb_define_const(mQueryError, "NONE", INT2NUM(0));
  rb_define_const(mQueryError, "Syntax", INT2NUM(1));
  rb_define_const(mQueryError, "NodeType", INT2NUM(2));
  rb_define_const(mQueryError, "Field", INT2NUM(3));
  rb_define_const(mQueryError, "Capture", INT2NUM(4));
  rb_define_const(mQueryError, "Structure", INT2NUM(5));
  rb_define_const(mQueryError, "Language", INT2NUM(6));
}
