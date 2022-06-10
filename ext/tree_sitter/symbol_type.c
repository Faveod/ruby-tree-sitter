#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE mSymbolType;

const char *regular = "regular";
const char *anonymous = "anonymous";
const char *auxiliary = "auxiliary";

TSSymbolType value_to_symbol_type(VALUE symbol_type) {
  VALUE sym = SYM2ID(symbol_type);
  VALUE anon = rb_const_get_at(mSymbolType, rb_intern(anonymous));
  VALUE aux = rb_const_get_at(mSymbolType, rb_intern(auxiliary));

  // NOTE: should we emit a warning instead of defaulting to regular?
  if (sym == anon) {
    return TSSymbolTypeAnonymous;
  } else if (sym == aux) {
    return TSSymbolTypeAuxiliary;
  } else {
    return TSSymbolTypeRegular;
  }
}

VALUE new_symbol_type(TSSymbolType symbol_type) {
  switch (symbol_type) {
  case TSSymbolTypeRegular:
    return ID2SYM(rb_intern(regular));
  case TSSymbolTypeAnonymous:
    return ID2SYM(rb_intern(anonymous));
  case TSSymbolTypeAuxiliary:
    return ID2SYM(rb_intern(auxiliary));
  default:
    return ID2SYM(rb_intern("this_should_never_get_reached"));
  }
}

void init_symbol_type(void) {
  mSymbolType = rb_define_module_under(mTreeSitter, "SymbolType");

  /* Constants */
  rb_define_const(mSymbolType, "REGULAR", ID2SYM(rb_intern(regular)));
  rb_define_const(mSymbolType, "ANONYMOUS", ID2SYM(rb_intern(anonymous)));
  rb_define_const(mSymbolType, "AUXILIARY", ID2SYM(rb_intern(auxiliary)));
}
