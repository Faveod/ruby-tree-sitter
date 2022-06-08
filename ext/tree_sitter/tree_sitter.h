#ifndef _RB_TREE_SITTER_H
#define _RB_TREE_SITTER_H

#include "tree_sitter/api.h"
#include <ruby.h>

// All new_* functions create ruby objects from a TS* ptr
VALUE new_language(const TSLanguage *);

// All init_* functions are called from Init_tree_sitter
void init_language(void);
void init_parser(void);

// This is a special entry-point for the extension
void Init_tree_sitter(void);

#endif
