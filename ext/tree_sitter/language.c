#include "tree_sitter.h"
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>

// tree-sitter 0.26+ returns const TSLanguage*
typedef const TSLanguage *(tree_sitter_lang)(void);
const char *tree_sitter_prefix = "tree_sitter_";

extern VALUE mTreeSitter;

VALUE cLanguage;

DATA_TYPE(TSLanguage *, language)
DATA_FREE(language)
DATA_MEMSIZE(language)
DATA_DECLARE_DATA_TYPE(language)
DATA_ALLOCATE(language)
DATA_UNWRAP(language)

TSLanguage *value_to_language(VALUE self) { return SELF; }

VALUE new_language(const TSLanguage *language) {
  VALUE res = language_allocate(cLanguage);
  unwrap(res)->data = (TSLanguage *)language;
  return res;
}

/**
 * Load a language parser from disk.
 *
 * @raise [RuntimeError] if the parser was not found, or if it's incompatible
 * with this gem.
 *
 * @param name [String] the parser's name.
 * @param path [String, Pathname] the parser's shared library (so, dylib) path on disk.
 *
 * @return [Language]
 */
static VALUE language_load(VALUE self, VALUE name, VALUE path) {
  VALUE path_s = rb_funcall(path, rb_intern("to_s"), 0);
  char *path_cstr = StringValueCStr(path_s);
  void *lib = dlopen(path_cstr, RTLD_NOW);
  if (lib == NULL) {
    const char *err = dlerror();
    VALUE parser_not_found = rb_const_get(mTreeSitter, rb_intern("ParserNotFoundError"));
    rb_raise(parser_not_found,
             "Could not load shared library `%s'.\nReason: %s", path_cstr, err ? err : "unknown error");
  }

  char buf[256];
  snprintf(buf, sizeof(buf), "tree_sitter_%s", StringValueCStr(name));

  // Clear any previous error before dlsym (POSIX requirement)
  dlerror();

  tree_sitter_lang *make_ts_language = dlsym(lib, buf);

  // Only check dlerror if dlsym returned NULL
  if (make_ts_language == NULL) {
    const char *err = dlerror();
    dlclose(lib);
    VALUE symbol_not_found = rb_const_get(mTreeSitter, rb_intern("SymbolNotFoundError"));
    rb_raise(symbol_not_found,
             "Could not load symbol `%s' from library `%s'.\nReason: %s",
             buf, path_cstr, err ? err : "symbol not found");
  }

  const TSLanguage *lang = make_ts_language();
  if (lang == NULL) {
    dlclose(lib);
    VALUE language_load_error = rb_const_get(mTreeSitter, rb_intern("LanguageLoadError"));
    rb_raise(language_load_error,
             "TSLanguage = NULL for language `%s' in library `%s'.\nCall your "
             "local TSLanguage supplier.",
             StringValueCStr(name), path_cstr);
  }

  // tree-sitter 0.26+ renamed ts_language_version to ts_language_abi_version
  uint32_t version = ts_language_abi_version(lang);
  if (version < TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION) {
    VALUE version_error = rb_const_get(mTreeSitter, rb_intern("ParserVersionError"));
    rb_raise(version_error,
             "Language %s (v%d) from `%s' is old.\nMinimum supported ABI: "
             "v%d.\nCurrent ABI: v%d.",
             StringValueCStr(name), version, path_cstr,
             TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION,
             TREE_SITTER_LANGUAGE_VERSION);
  }

  return new_language(lang);
}

static VALUE language_equal(VALUE self, VALUE other) {
  TSLanguage *this = SELF;
  TSLanguage *that = unwrap(other)->data;
  return this == that ? Qtrue : Qfalse;
}

/**
 * Get the number of distinct field names in the language.
 *
 * @return [Integer]
 */
static VALUE language_field_count(VALUE self) {
  return UINT2NUM(ts_language_field_count(SELF));
}

/**
 * Get the numerical id for the given field name string.
 *
 * @param name [String]
 *
 * @return [Integer]
 */
static VALUE language_field_id_for_name(VALUE self, VALUE name) {
  TSLanguage *language = SELF;
  const char *str = StringValuePtr(name);
  uint32_t length = (uint32_t)RSTRING_LEN(name);
  return UINT2NUM(ts_language_field_id_for_name(language, str, length));
}

/**
 * Get the field name string for the given numerical id.
 *
 * @param field_id [Integer]
 *
 * @return [String]
 */
static VALUE language_field_name_for_id(VALUE self, VALUE field_id) {
  return safe_str(ts_language_field_name_for_id(SELF, NUM2UINT(field_id)));
}

/**
 * Get the next parse state. Combine this with lookahead iterators to generate
 * completion suggestions or valid symbols in error nodes. Use
 * {Node#grammar_symbol} for valid symbols.
 */
static VALUE language_next_state(VALUE self, VALUE state, VALUE symbol) {
  uint16_t sta = (uint16_t)NUM2UINT(state);
  uint16_t sym = (uint16_t)NUM2UINT(symbol);
  return UINT2NUM(ts_language_next_state(SELF, sta, sym));
}

/**
 * Get the number of distinct node types in the language.
 *
 * @return [Integer]
 */
static VALUE language_symbol_count(VALUE self) {
  return UINT2NUM(ts_language_symbol_count(SELF));
}

/**
 * Get a node type string for the given numerical id.
 *
 * @param symbol [Integer]
 *
 * @return [String]
 */
static VALUE language_symbol_name(VALUE self, VALUE symbol) {
  return safe_str(ts_language_symbol_name(SELF, NUM2UINT(symbol)));
}

/**
 * Get the numerical id for the given node type string.
 *
 * @param string   [Symbol]
 * @param is_named [Boolean]
 *
 * @return [Integer]
 */
static VALUE language_symbol_for_name(VALUE self, VALUE string,
                                      VALUE is_named) {
  const char *str = rb_id2name(SYM2ID(string));
  uint32_t length = (uint32_t)strlen(str);
  bool named = RTEST(is_named);
  return UINT2NUM(ts_language_symbol_for_name(SELF, str, length, named));
}

/**
 * Check whether the given node type id belongs to named nodes, anonymous nodes,
 * or a hidden nodes.
 *
 * Hidden nodes are never returned from the API.
 *
 * @see Node#named?
 *
 * @param symbol [Integer]
 *
 * @return [SymbolType]
 */
static VALUE language_symbol_type(VALUE self, VALUE symbol) {
  return new_symbol_type(ts_language_symbol_type(SELF, NUM2UINT(symbol)));
}

/**
 * Get the ABI version number for this language. This version number is used
 * to ensure that languages were generated by a compatible version of
 * Tree-sitter.
 *
 * @see Parser#language=
 */
static VALUE language_version(VALUE self) {
  // tree-sitter 0.26+ renamed ts_language_version to ts_language_abi_version
  return UINT2NUM(ts_language_abi_version(SELF));
}

void init_language(void) {
  cLanguage = rb_define_class_under(mTreeSitter, "Language", rb_cObject);

  rb_define_alloc_func(cLanguage, language_allocate);

  /* Module methods */
  rb_define_module_function(cLanguage, "load", language_load, 2);

  /* Operators */
  rb_define_method(cLanguage, "==", language_equal, 1);

  /* Class methods */
  rb_define_method(cLanguage, "field_count", language_field_count, 0);
  rb_define_method(cLanguage, "field_id_for_name", language_field_id_for_name,
                   1);
  rb_define_method(cLanguage, "field_name_for_id", language_field_name_for_id,
                   1);
  rb_define_method(cLanguage, "next_state", language_next_state, 2);
  rb_define_method(cLanguage, "symbol_count", language_symbol_count, 0);
  rb_define_method(cLanguage, "symbol_for_name", language_symbol_for_name, 2);
  rb_define_method(cLanguage, "symbol_name", language_symbol_name, 1);
  rb_define_method(cLanguage, "symbol_type", language_symbol_type, 1);
  rb_define_method(cLanguage, "version", language_version, 0);
  rb_define_method(cLanguage, "abi_version", language_version, 0);
}
