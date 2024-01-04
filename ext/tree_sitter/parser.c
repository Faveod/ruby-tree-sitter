#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cParser;

typedef struct {
  TSParser *data;
  size_t cancellation_flag;
} parser_t;

static void parser_free(void *ptr) {
  ts_parser_delete(((parser_t *)ptr)->data);
  xfree(ptr);
}

static size_t parser_memsize(const void *ptr) {
  parser_t *type = (parser_t *)ptr;
  return sizeof(type);
}

const rb_data_type_t parser_data_type = {
    .wrap_struct_name = "parser",
    .function =
        {
            .dmark = NULL,
            .dfree = parser_free,
            .dsize = parser_memsize,
            .dcompact = NULL,
        },
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

DATA_UNWRAP(parser)

static VALUE parser_allocate(VALUE klass) {
  parser_t *parser;
  VALUE res = TypedData_Make_Struct(klass, parser_t, &parser_data_type, parser);
  parser->data = ts_parser_new();
  return res;
}

/**
 * Get the parser's current language.
 */
static VALUE parser_get_language(VALUE self) {
  return new_language(ts_parser_language(SELF));
}

/**
 * Get the ranges of text that the parser will include when parsing.
 *
 * @return [Array<Range>]
 */
static VALUE parser_get_included_ranges(VALUE self) {
  uint32_t length;
  const TSRange *ranges = ts_parser_included_ranges(SELF, &length);
  VALUE res = rb_ary_new_capa(length);
  for (uint32_t i = 0; i < length; i++) {
    rb_ary_push(res, new_range(&ranges[i]));
  }
  return res;
}

/**
 * Get the duration in microseconds that parsing is allowed to take.
 *
 * @return [Integer]
 */
static VALUE parser_get_timeout_micros(VALUE self) {
  return ULL2NUM(ts_parser_timeout_micros(SELF));
}

/**
 * Get the parser's current logger.
 *
 * @return [Logger]
 */
static VALUE parser_get_logger(VALUE self) {
  return new_logger_by_val(ts_parser_logger(SELF));
}

/**
 * Get the parser's current cancellation flag pointer.
 *
 * @return [Integer]
 */
static VALUE parser_get_cancellation_flag(VALUE self) {
  return SIZET2NUM(*ts_parser_cancellation_flag(SELF));
}

/**
 * Set the language that the parser should use for parsing.
 *
 * Returns a boolean indicating whether or not the language was successfully
 * assigned. True means assignment succeeded. False means there was a version
 * mismatch: the language was generated with an incompatible version of the
 * Tree-sitter CLI. Check the language's version using {Language#version}
 * and compare it to this library's {TreeSitter::LANGUAGE_VERSION} and
 * {TreeSitter::MIN_COMPATIBLE_LANGUAGE_VERSION} constants.
 *
 * @return [Boolean]
 */
static VALUE parser_set_language(VALUE self, VALUE language) {
  return ts_parser_set_language(SELF, value_to_language(language)) ? Qtrue
                                                                   : Qfalse;
}

/**
 * Set the ranges of text that the parser should include when parsing.
 *
 * By default, the parser will always include entire documents. This function
 * allows you to parse only a *portion* of a document but still return a syntax
 * tree whose ranges match up with the document as a whole. You can also pass
 * multiple disjoint ranges.
 *
 * The second and third parameters specify the location and length of an array
 * of ranges. The parser does *not* take ownership of these ranges; it copies
 * the data, so it doesn't matter how these ranges are allocated.
 *
 * If +length+ is zero, then the entire document will be parsed. Otherwise,
 * the given ranges must be ordered from earliest to latest in the document,
 * and they must not overlap. That is, the following must hold for all
 *
 *   i < length - 1: ranges[i].end_byte <= ranges[i + 1].start_byte
 *
 * If this requirement is not satisfied, the operation will fail, the ranges
 * will not be assigned, and this function will return +false+. On success,
 * this function returns +true+
 *
 * @param array [Array<Range>]
 *
 * @return [Boolean]
 */
static VALUE parser_set_included_ranges(VALUE self, VALUE array) {
  Check_Type(array, T_ARRAY);

  long length = rb_array_len(array);
  TSRange *ranges = (TSRange *)malloc(length * sizeof(TSRange));
  for (long i = 0; i < length; i++) {
    ranges[i] = value_to_range(rb_ary_entry(array, i));
  }
  bool res = ts_parser_set_included_ranges(SELF, ranges, (uint32_t)length);
  if (ranges) {
    free(ranges);
  }
  return res ? Qtrue : Qfalse;
}

/**
 * Set the maximum duration in microseconds that parsing should be allowed to
 * take before halting.
 *
 * If parsing takes longer than this, it will halt early, returning +nil+.
 *
 * @see parse
 *
 * @param timeout [Integer]
 *
 * @return [nil]
 */
static VALUE parser_set_timeout_micros(VALUE self, VALUE timeout) {
  ts_parser_set_timeout_micros(SELF, NUM2ULL(timeout));
  return Qnil;
}

/**
 * Set the parser's current cancellation flag pointer.
 *
 * If a non-null pointer is assigned, then the parser will periodically read
 * from this pointer during parsing. If it reads a non-zero value, it will
 * halt early, returning +nil+.
 *
 * @see parse
 *
 * @note This is not well-tested in the bindings.
 *
 * @return nil
 */
static VALUE parser_set_cancellation_flag(VALUE self, VALUE flag) {
  unwrap(self)->cancellation_flag = NUM2SIZET(flag);
  ts_parser_set_cancellation_flag(SELF, &unwrap(self)->cancellation_flag);
  return Qnil;
}

/**
 * Set the logger that a parser should use during parsing.
 *
 * The parser does not take ownership over the logger payload. If a logger was
 * previously assigned, the caller is responsible for releasing any memory
 * owned by the previous logger.
 *
 * @param logger [Logger] or any object that has a +printf+, +puts+, or +write+.
 *
 * @return nil
 */
static VALUE parser_set_logger(VALUE self, VALUE logger) {
  ts_parser_set_logger(SELF, value_to_logger(logger));
  return Qnil;
}

/**
 * Use the parser to parse some source code and create a syntax tree.
 *
 * If you are parsing this document for the first time, pass +nil+ for the
 * +old_tree+ parameter. Otherwise, if you have already parsed an earlier
 * version of this document and the document has since been edited, pass the
 * previous syntax tree so that the unchanged parts of it can be reused.
 * This will save time and memory. For this to work correctly, you must have
 * already edited the old syntax tree using the {Tree#edit} function in a
 * way that exactly matches the source code changes.
 *
 * The input parameter lets you specify how to read the text. It has the
 * following three fields:
 * 1. +read+: A function to retrieve a chunk of text at a given byte offset
 *    and (row, column) position. The function should return a pointer to the
 *    text and write its length to the +bytes_read+ pointer. The parser does
 *    not take ownership of this buffer; it just borrows it until it has
 *    finished reading it. The function should write a zero value to the
 *    +bytes_read+ pointer to indicate the end of the document.
 * 2. +payload+: An arbitrary pointer that will be passed to each invocation
 *    of the +read+ function.
 * 3. +encoding+: An indication of how the text is encoded. Either
 *    {Encoding::UTF8} or {Encoding::UTF16}.
 *
 * This function returns a syntax tree on success, and +nil+ on failure. There
 * are three possible reasons for failure:
 * 1. The parser does not have a language assigned. Check for this using the
 *    {Parser#language} function.
 * 2. Parsing was cancelled due to a timeout that was set by an earlier call to
 *    the {Parser#timeout_micros=} function. You can resume parsing from
 *    where the parser left out by calling {Parser#parse} again with the
 *    same arguments. Or you can start parsing from scratch by first calling
 *    {Parser#reset}.
 * 3. Parsing was cancelled using a cancellation flag that was set by an
 *    earlier call to {Parsert#cancellation_flag=}. You can resume parsing
 *    from where the parser left out by calling {Parser#parse} again with
 *    the same arguments.
 *
 * @note this is curently incomplete, as the {Input} class is incomplete.
 *
 * @param old_tree [Tree]
 * @param input    [Input]
 *
 * @return [Tree, nil] A parse tree if parsing was successful.
 */
static VALUE parser_parse(VALUE self, VALUE old_tree, VALUE input) {
  if (NIL_P(input)) {
    return Qnil;
  }

  TSTree *tree = NULL;
  if (!NIL_P(old_tree)) {
    tree = value_to_tree(old_tree);
  }

  TSTree *ret = ts_parser_parse(SELF, tree, value_to_input(input));
  if (ret == NULL) {
    return Qnil;
  } else {
    return new_tree(ret);
  }
}

/**
 * Use the parser to parse some source code stored in one contiguous buffer.
 * The first two parameters are the same as in the {Parser#parse} function
 * above. The second two parameters indicate the location of the buffer and its
 * length in bytes.
 *
 * @param old_tree [Tree]
 * @param string   [String]
 *
 * @return [Tree, nil] A parse tree if parsing was successful.
 */
static VALUE parser_parse_string(VALUE self, VALUE old_tree, VALUE string) {
  if (NIL_P(string)) {
    return Qnil;
  }

  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);
  TSTree *tree = NULL;
  if (!NIL_P(old_tree)) {
    tree = value_to_tree(old_tree);
  }

  TSTree *ret = ts_parser_parse_string(SELF, tree, str, len);
  if (ret == NULL) {
    return Qnil;
  } else {
    return new_tree(ret);
  }
}

/**
 * Use the parser to parse some source code stored in one contiguous buffer with
 * a given encoding. The first four parameters work the same as in the
 * {Parser#parse_string} method above. The final parameter indicates whether
 * the text is encoded as {Encoding::UTF8} or {Encoding::UTF16}.
 *
 * @param old_tree [Tree]
 * @param string   [String]
 * @param encoding [Encoding]
 *
 * @return [Tree, nil] A parse tree if parsing was successful.
 */
static VALUE parser_parse_string_encoding(VALUE self, VALUE old_tree,
                                          VALUE string, VALUE encoding) {
  if (NIL_P(string)) {
    return Qnil;
  }

  const char *str = StringValuePtr(string);
  uint32_t len = (uint32_t)RSTRING_LEN(string);
  TSTree *tree = NULL;
  if (!NIL_P(old_tree)) {
    tree = value_to_tree(old_tree);
  }

  TSTree *ret = ts_parser_parse_string_encoding(SELF, tree, str, len,
                                                value_to_encoding(encoding));

  if (ret == NULL) {
    return Qnil;
  } else {
    return new_tree(ret);
  }
}

/**
 * Instruct the parser to start the next parse from the beginning.
 *
 * If the parser previously failed because of a timeout or a cancellation, then
 * by default, it will resume where it left off on the next call to
 * {Parser#parse} or other parsing functions. If you don't want to resume,
 * and instead intend to use this parser to parse some other document, you must
 * call {Parser#reset} first.
 *
 * @return nil
 */
static VALUE parser_reset(VALUE self) {
  ts_parser_reset(SELF);
  return Qnil;
}

/**
 * Set the file descriptor to which the parser should write debugging graphs
 * during parsing. The graphs are formatted in the DOT language. You may want
 * to pipe these graphs directly to a +dot(1)+ process in order to generate
 * SVG output. You can turn off this logging by passing a negative number.
 *
 * @param file [Integer, String, nil] a file name to print, or turn off by
 * passing +nil+ or +-1+
 *
 * @return nil
 */
static VALUE parser_print_dot_graphs(VALUE self, VALUE file) {
  if (NIL_P(file)) {
    ts_parser_print_dot_graphs(SELF, -1);
  } else if (rb_integer_type_p(file) && NUM2INT(file) < 0) {
    ts_parser_print_dot_graphs(SELF, NUM2INT(file));
  } else {
    Check_Type(file, T_STRING);
    char *path = StringValueCStr(file);
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC,
                  0644); // 0644 = all read + user write
    ts_parser_print_dot_graphs(SELF, fd);
  }
  return Qnil;
}

void init_parser(void) {
  cParser = rb_define_class_under(mTreeSitter, "Parser", rb_cObject);

  rb_define_alloc_func(cParser, parser_allocate);

  /* Class methods */
  rb_define_method(cParser, "language", parser_get_language, 0);
  rb_define_method(cParser, "language=", parser_set_language, 1);
  rb_define_method(cParser, "included_ranges", parser_get_included_ranges, 0);
  rb_define_method(cParser, "included_ranges=", parser_set_included_ranges, 1);
  rb_define_method(cParser, "timeout_micros", parser_get_timeout_micros, 0);
  rb_define_method(cParser, "timeout_micros=", parser_set_timeout_micros, 1);
  rb_define_method(cParser, "logger", parser_get_logger, 0);
  rb_define_method(cParser, "logger=", parser_set_logger, 1);
  rb_define_method(cParser, "cancellation_flag", parser_get_cancellation_flag,
                   0);
  rb_define_method(cParser, "cancellation_flag=", parser_set_cancellation_flag,
                   1);
  rb_define_method(cParser, "parse", parser_parse, 2);
  rb_define_method(cParser, "parse_string", parser_parse_string, 2);
  rb_define_method(cParser, "parse_string_encoding",
                   parser_parse_string_encoding, 3);
  rb_define_method(cParser, "reset", parser_reset, 0);
  rb_define_method(cParser, "print_dot_graphs", parser_print_dot_graphs, 1);
}
