// Include the Ruby headers and goodies
#include "ruby.h"

VALUE Grenadier = Qnil;

static VALUE hello_world(VALUE mod) { return rb_str_new2("hello world"); }

// The initialization method for this module
void Init_grenadier() {
  Grenadier = rb_define_module("Grenadier");
  rb_define_singleton_method(Grenadier, "hello_world", hello_world, 0);
}
