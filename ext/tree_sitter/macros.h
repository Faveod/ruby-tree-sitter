#ifndef _RB_TREE_SITTER_MACROS_H
#define _RB_TREE_SITTER_MACROS_H

// RB_* are for TypedData structs, reaching their top-level
// fields, and are of type VALUE
//
// DATA_* are for TypeData structs, raching their data field
// which can be of an arbitraty tuype.

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

#define DATA_GETTER(type, field, cast)                                         \
  static VALUE type##_get_##field(VALUE self) {                                \
    type##_t *ptr;                                                             \
    TypedData_Get_Struct(self, type##_t, &type##_data_type, ptr);              \
    return cast(ptr->data.field);                                              \
  }

#define DATA_SETTER(type, field, cast)                                         \
  static VALUE type##_set_##field(VALUE self, VALUE val) {                     \
    type##_t *ptr;                                                             \
    TypedData_Get_Struct(self, type##_t, &type##_data_type, ptr);              \
    ptr->data.field = cast(val);                                               \
    return Qnil;                                                               \
  }

#define DATA_ACCESSOR(type, field, cast_get, cast_set)                         \
  DATA_GETTER(type, field, cast_get)                                           \
  DATA_SETTER(type, field, cast_set)

#define DEFINE_GETTER(klass, type, field)                                      \
  rb_define_method(klass, #field, type##_get_##field, 0);

#define DEFINE_SETTER(klass, type, field)                                      \
  rb_define_method(klass, #field "=", type##_set_##field, 1);

#define DEFINE_ACCESSOR(klass, type, field)                                    \
  DEFINE_GETTER(klass, type, field)                                            \
  DEFINE_SETTER(klass, type, field)

#endif
