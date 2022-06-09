#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cLogger;

void logger_free(TSLogger *logger) { free(logger); }

static VALUE logger_allocate(VALUE klass) {
  TSLogger *logger = (TSLogger *)malloc(sizeof(TSLogger));
  return Data_Wrap_Struct(klass, NULL, logger_free, logger);
}

VALUE new_logger(const TSLogger *logger) {
  VALUE res = logger_allocate(cLogger);
  TSLogger *ptr;
  Data_Get_Struct(res, TSLogger, ptr);
  memcpy(ptr, logger, sizeof(TSLogger));
  return res;
}

void init_logger(void) {
  cLogger = rb_define_class_under(mTreeSitter, "Logger", rb_cObject);

  rb_define_alloc_func(cLogger, logger_allocate);
}
