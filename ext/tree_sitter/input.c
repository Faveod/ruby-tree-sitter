#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cInput;

typedef struct {
  TSInput data;
  VALUE payload;
  VALUE last_result;
} input_t;

const char *input_read(void *payload, uint32_t byte_index, TSPoint position,
                       uint32_t *bytes_read) {
  input_t *input = (input_t *)payload;
  VALUE read = rb_funcall(input->payload, rb_intern("read"), 2,
                          INT2NUM(byte_index), new_point(&position));
  if (NIL_P(read)) {
    *bytes_read = 0;
    input->last_result = Qnil;
    return NULL;
  }

  VALUE size = rb_funcall(read, rb_intern("bytesize"), 0);
  *bytes_read = NUM2INT(size);
  input->last_result = rb_funcall(read, rb_intern("to_str"), 0);

  return StringValueCStr(input->last_result);
}

static void input_payload_set(input_t *input, VALUE value) {
  input->payload = value;
  input->last_result = Qnil;
  input->data.payload = (void *)input;
  input->data.read = input_read;
}

static void input_free(void *ptr) { xfree(ptr); }

static size_t input_memsize(const void *ptr) {
  input_t *type = (input_t *)ptr;
  return sizeof(type);
}

static void input_mark(void *ptr) {
  input_t *input = (input_t *)ptr;
  rb_gc_mark_movable(input->payload);
  // we don't want last_result to move because its const char* content will be
  // consumed by the parser.
  //
  // No funny things please.
  rb_gc_mark(input->last_result);
}

static void input_compact(void *ptr) {
  input_t *input = (input_t *)ptr;
  input->payload = rb_gc_location(input->payload);
}

const rb_data_type_t input_data_type = {
    .wrap_struct_name = "input",
    .function =
        {
            .dmark = input_mark,
            .dfree = input_free,
            .dsize = input_memsize,
            .dcompact = input_compact,
        },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

DATA_UNWRAP(input)

static VALUE input_allocate(VALUE klass) {
  input_t *input;
  return TypedData_Make_Struct(klass, input_t, &input_data_type, input);
}

TSInput value_to_input(VALUE self) { return SELF; }

VALUE new_input(const TSInput *ptr) {
  if (ptr != NULL) {
    VALUE res = input_allocate(cInput);
    input_t *input = unwrap(res);
    VALUE payload = Qnil;
    if (ptr->payload != NULL) {
      input_t *old_input = (input_t *)ptr->payload;
      payload = old_input->payload;
    }
    input_payload_set(input, payload);
    return res;
  } else {
    return Qnil;
  }
}

static VALUE input_initialize(int argc, VALUE *argv, VALUE self) {
  input_t *input = unwrap(self);
  VALUE payload;
  rb_scan_args(argc, argv, "01", &payload);
  input_payload_set(input, payload);
  return self;
}

static VALUE input_inspect(VALUE self) {
  return rb_sprintf("{payload=%+" PRIsVALUE "}", unwrap(self)->payload);
}

GETTER(input, payload)

static VALUE input_set_payload(VALUE self, VALUE payload) {
  input_payload_set(unwrap(self), payload);
  return Qnil;
}

void init_input(void) {
  cInput = rb_define_class_under(mTreeSitter, "Input", rb_cObject);

  rb_define_alloc_func(cInput, input_allocate);

  /* Class methods */
  DEFINE_ACCESSOR(cInput, input, payload)
  rb_define_method(cInput, "initialize", input_initialize, -1);
  rb_define_method(cInput, "inspect", input_inspect, 0);
  rb_define_method(cInput, "to_s", input_inspect, 0);
}
