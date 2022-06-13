#ifndef _RB_TREE_SITTER_MACROS_H
#define _RB_TREE_SITTER_MACROS_H

#define DECLARE_GETTER(klass, type, field)                                     \
  rb_define_method(klass, #field, type##_get_##field, 0);

#define DECLARE_SETTER(klass, type, field)                                     \
  rb_define_method(klass, #field "=", type##_set_##field, 1);

#define DECLARE_ACCESSOR(klass, type, field)                                   \
  DECLARE_GETTER(klass, type, field)                                           \
  DECLARE_SETTER(klass, type, field)

// Plain DEFINE_GETTER/DEFINE_SETTER/etc are for TypedData structs, reaching
// their top-level fields, and are of type VALUE
//
// DATA_* are for TypeData structs, raching their data field
// which can be of an arbitraty tuype.

#define DEFINE_GETTER(type, field)                                             \
  static VALUE type##_get_##field(VALUE self) { return (unwrap(self))->field; }

#define DEFINE_SETTER(type, field)                                             \
  static VALUE type##_set_##field(VALUE self, VALUE val) {                     \
    unwrap(self)->field = val;                                                 \
    return Qnil;                                                               \
  }

#define DEFINE_ACCESSOR(type, field)                                           \
  DEFINE_GETTER(type, field)                                                   \
  DEFINE_SETTER(type, field)

#define DATA_WRAP(base, type)                                                  \
  DATA_TYPE(TS##base, type)                                                    \
  DATA_FREE(type)                                                              \
  DATA_MEMSIZE(type)                                                           \
  DATA_DECLARE_DATA_TYPE(type)                                                 \
  DATA_ALLOCATE(type)                                                          \
  DATA_UNWRAP(type)                                                            \
  DATA_NEW(c##base, TS##base, type)                                            \
  DATA_FROM_VALUE(TS##base, type)

#define DATA_TYPE(klass, type)                                                 \
  typedef struct {                                                             \
    klass data;                                                                \
  } type##_t;

#define DATA_FREE(type)                                                        \
  static void type##_free(void *ptr) { xfree(ptr); }

#define DATA_MEMSIZE(type)                                                     \
  static size_t type##_memsize(const void *ptr) {                              \
    type##_t *type = (type##_t *)ptr;                                          \
    return sizeof(type);                                                       \
  }

#define DATA_DECLARE_DATA_TYPE(type)                                           \
  const rb_data_type_t type##_data_type = {                                    \
      .wrap_struct_name = #type "",                                            \
      .function =                                                              \
          {                                                                    \
              .dmark = NULL,                                                   \
              .dfree = type##_free,                                            \
              .dsize = type##_memsize,                                         \
              .dcompact = NULL,                                                \
          },                                                                   \
      .flags = RUBY_TYPED_FREE_IMMEDIATELY,                                    \
  };

#define DATA_ALLOCATE(type)                                                    \
  static VALUE type##_allocate(VALUE klass) {                                  \
    type##_t *type;                                                            \
    return TypedData_Make_Struct(klass, type##_t, &type##_data_type, type);    \
  }

#define DATA_UNWRAP(type)                                                      \
  static type##_t *unwrap(VALUE self) {                                        \
    type##_t *type;                                                            \
    TypedData_Get_Struct(self, type##_t, &type##_data_type, type);             \
    return type;                                                               \
  }

#define SELF unwrap(self)->data

#define DATA_NEW(klass, struct, type)                                          \
  VALUE new_##type(const struct *ptr) {                                        \
    if (ptr == NULL) {                                                         \
      return Qnil;                                                             \
    }                                                                          \
    VALUE res = type##_allocate(klass);                                        \
    type##_t *type = unwrap(res);                                              \
    type->data = *ptr;                                                         \
    return res;                                                                \
  }                                                                            \
  VALUE new_##type##_by_val(struct ptr) {                                      \
    VALUE res = type##_allocate(klass);                                        \
    type##_t *type = unwrap(res);                                              \
    type->data = ptr;                                                          \
    return res;                                                                \
  }

#define DATA_FROM_VALUE(struct, type)                                          \
  struct value_to_##type(VALUE self) {                                         \
    return (unwrap(self))->data;                                               \
  }

#define DATA_DEFINE_GETTER(type, field, cast)                                  \
  static VALUE type##_get_##field(VALUE self) {                                \
    return cast((unwrap(self))->data.field);                                   \
  }

#define DATA_DEFINE_SETTER(type, field, cast)                                  \
  static VALUE type##_set_##field(VALUE self, VALUE val) {                     \
    type##_t *type = unwrap(self);                                             \
    type->data.field = cast(val);                                              \
    return Qnil;                                                               \
  }

#define DATA_DEFINE_ACCESSOR(type, field, cast_get, cast_set)                  \
  DATA_DEFINE_GETTER(type, field, cast_get)                                    \
  DATA_DEFINE_SETTER(type, field, cast_set)

#define DATA_FAST_FORWARD_FNV(type, fn, field)                                 \
  static VALUE type##_##fn(int argc, VALUE *argv, VALUE self) {                \
    type##_t *type = unwrap(self);                                             \
    if (!NIL_P(type->field)) {                                                 \
      return rb_funcallv(type->field, rb_intern(#fn ""), argc, argv);          \
    } else {                                                                   \
      return Qnil;                                                             \
    }                                                                          \
  }

#endif
