#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE mEncoding;

const char *utf8 = "utf8";
const char *utf16 = "utf16";

TSInputEncoding value_to_encoding(VALUE encoding) {
  VALUE enc = SYM2ID(encoding);
  /* VALUE u8 = rb_const_get_at(mEncoding, rb_intern(utf8)); */
  VALUE u16 = SYM2ID(rb_const_get_at(mEncoding, rb_intern("UTF16")));

  // NOTE: should we emit a warning instead of defaulting to UTF8?
  if (enc == u16) {
    // tree-sitter 0.26+ split UTF16 into UTF16LE and UTF16BE
    return TSInputEncodingUTF16LE;
  } else {
    return TSInputEncodingUTF8;
  }
}

void init_encoding(void) {
  mEncoding = rb_define_module_under(mTreeSitter, "Encoding");

  /* Constants */
  rb_define_const(mEncoding, "UTF8", ID2SYM(rb_intern(utf8)));
  rb_define_const(mEncoding, "UTF16", ID2SYM(rb_intern(utf16)));
}
