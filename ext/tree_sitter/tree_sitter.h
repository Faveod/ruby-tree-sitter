#ifndef TREE_SITTER_H
#define TREE_SITTER_H

#include "ruby.h"

VALUE TreeSitter = Qnil;

static VALUE hello_world(VALUE mod);

void Init_tree_sitter();

#endif
