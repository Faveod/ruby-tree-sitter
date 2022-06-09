#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE mEncoding;

const char *utf8 = "UTF8";
const char *utf16 = "UTF16";

TSInputEncoding value_to_encoding(VALUE encoding) {
  VALUE enc = SYM2ID(encoding);
  /* VALUE u8 = rb_const_get_at(mEncoding, rb_intern(utf8)); */
  VALUE u16 = rb_const_get_at(mEncoding, rb_intern(utf16));

  // NOTE: should we emit a warning instead of defaulting to UTF8?
  if (enc == u16) {
    return TSInputEncodingUTF16;
  } else {
    return TSInputEncodingUTF8;
  }
}

void init_encoding(void) {
  mEncoding = rb_define_module_under(mTreeSitter, "Encoding");
  rb_define_const(mEncoding, utf8, ID2SYM(rb_intern(utf8)));
  rb_define_const(mEncoding, utf16, ID2SYM(rb_intern(utf16)));
}
