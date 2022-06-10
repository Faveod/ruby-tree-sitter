#ifndef _RB_TREE_SITTER_H
#define _RB_TREE_SITTER_H

#include <fcntl.h>
#include <ruby.h>
#include <stdio.h>
#include <tree_sitter/api.h>

// Macros for mechanical stuff
#define GETTER(type, field)                                                    \
  static VALUE type##_get_##field(VALUE self) {                                \
    type##_t *ptr;                                                             \
    TypedData_Get_Struct(self, type##_t, &type##_data_type, ptr);              \
    return ptr->field;                                                         \
  }

#define SETTER(type, field)                                                    \
  static VALUE type##_set_##field(VALUE self, VALUE val) {                     \
    type##_t *ptr;                                                             \
    TypedData_Get_Struct(self, type##_t, &type##_data_type, ptr);              \
    ptr->field = val;                                                          \
    return Qnil;                                                               \
  }

#define ACCESSOR(type, field)                                                  \
  GETTER(type, field)                                                          \
  SETTER(type, field)

#define DEFINE_GETTER(klass, type, field)                                      \
  rb_define_method(klass, #field, type##_get_##field, 0);

#define DEFINE_SETTER(klass, type, field)                                      \
  rb_define_method(klass, #field "=", type##_set_##field, 1);

#define DEFINE_ACCESSOR(klass, type, field)                                    \
  DEFINE_GETTER(klass, type, field)                                            \
  DEFINE_SETTER(klass, type, field)

// VALUE to TS* converters
TSInput *value_to_input(VALUE);
TSInputEncoding value_to_encoding(VALUE);
TSInputEdit value_to_input_edit(VALUE);
TSLanguage *value_to_language(VALUE);
TSLogger *value_to_logger(VALUE);
TSNode *value_to_node(VALUE);
TSPoint *value_to_point(VALUE);
TSQuantifier value_to_quantifier(VALUE);
TSQuery *value_to_query(VALUE);
TSQueryMatch *value_to_query_match(VALUE);
TSQueryCursor *value_to_query_cursor(VALUE);
TSQueryPredicateStep *value_to_query_predicate_step(VALUE);
TSQueryPredicateStepType value_to_query_predicate_step_type(VALUE);
TSQueryError value_to_query_error(VALUE);
TSRange value_to_range(VALUE);
TSSymbolType value_to_symbol_type(VALUE);
TSTree *value_to_tree(VALUE);
TSTreeCursor *value_to_tree_cursor(VALUE);

// TS* to VALUE converters
VALUE new_input(const TSInput *);
VALUE new_language(const TSLanguage *);
VALUE new_logger(const TSLogger *);
VALUE new_node(const TSNode *);
VALUE new_query_match(const TSQueryMatch *);
VALUE new_query_predicate_step(const TSQueryPredicateStep *);
VALUE new_range(const TSRange *);
VALUE new_point(const TSPoint *);
VALUE new_symbol_type(TSSymbolType);
VALUE new_tree(const TSTree *);

// All init_* functions are called from Init_tree_sitter
void init_encoding(void);
void init_input(void);
void init_input_edit(void);
void init_logger(void);
void init_language(void);
void init_parser(void);
void init_quantifier(void);
void init_query(void);
void init_query_cursor(void);
void init_query_match(void);
void init_query_predicate_step(void);
void init_query_error(void);
void init_range(void);
void init_symbol_type(void);
void init_tree(void);
void init_tree_cursor(void);

// Other helpers
const char *query_error_name(TSQueryError);
const char *quantifier_name(TSQuantifier);

// This is a special entry-point for the extension
void Init_tree_sitter(void);

#endif
