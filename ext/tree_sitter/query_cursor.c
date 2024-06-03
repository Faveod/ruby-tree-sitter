#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cQueryCursor;

DATA_TYPE(TSQueryCursor *, query_cursor)
DATA_FREE_PTR(query_cursor)
DATA_MEMSIZE(query_cursor)
DATA_DECLARE_DATA_TYPE(query_cursor)
static VALUE query_cursor_allocate(VALUE klass) {
  query_cursor_t *query_cursor;
  VALUE res = TypedData_Make_Struct(klass, query_cursor_t,
                                    &query_cursor_data_type, query_cursor);
  query_cursor->data = ts_query_cursor_new();
  return res;
}
DATA_UNWRAP(query_cursor)
/**
 * Create a new cursor for executing a given query.
 *
 * The cursor stores the state that is needed to iteratively search
 * for matches. To use the query cursor, first call {QueryCursor#exec}
 * to start running a given query on a given syntax node. Then, there are
 * two options for consuming the results of the query:
 * 1. Repeatedly call {QueryCursor#next_match} to iterate over all of the
 *    *matches* in the order that they were found. Each match contains the
 *    index of the pattern that matched, and an array of captures. Because
 *    multiple patterns can match the same set of nodes, one match may contain
 *    captures that appear *before* some of the captures from a previous match.
 * 2. Repeatedly call {QueryCursor#next_capture} to iterate over all of the
 *    individual *captures* in the order that they appear. This is useful if
 *    don't care about which pattern matched, and just want a single ordered
 *    sequence of captures.
 *
 * If you don't care about consuming all of the results, you can stop calling
 * {QueryCursor#next_match} or {QueryCursor#next_capture} at any point.
 * You can then start executing another query on another node by calling
 * {QueryCursor#exec} again.
 */
DATA_PTR_NEW(cQueryCursor, TSQueryCursor, query_cursor)
DATA_FROM_VALUE(TSQueryCursor *, query_cursor)

/**
 * Start running a given query on a given node.
 *
 * @param query [Query]
 * @param node  [Node]
 *
 * @return [QueryCursor]
 */
static VALUE query_cursor_exec_static(VALUE self, VALUE query, VALUE node) {
  VALUE res = query_cursor_allocate(cQueryCursor);
  query_cursor_t *query_cursor = unwrap(res);
  ts_query_cursor_exec(query_cursor->data, value_to_query(query),
                       value_to_node(node));
  return res;
}

/**
 * Start running a given query on a given node.
 *
 * @param query [Query]
 * @param node  [Node]
 *
 * @return [QueryCursor]
 */
static VALUE query_cursor_exec(VALUE self, VALUE query, VALUE node) {
  query_cursor_t *query_cursor = unwrap(self);
  ts_query_cursor_exec(query_cursor->data, value_to_query(query),
                       value_to_node(node));
  return self;
}

/**
 * Manage the maximum number of in-progress matches allowed by this query
 * cursor.
 *
 * Query cursors have an optional maximum capacity for storing lists of
 * in-progress captures. If this capacity is exceeded, then the
 * earliest-starting match will silently be dropped to make room for further
 * matches. This maximum capacity is optional — by default, query cursors allow
 * any number of pending matches, dynamically allocating new space for them as
 * needed as the query is executed.
 */
static VALUE query_cursor_did_exceed_match_limit(VALUE self) {
  return ts_query_cursor_did_exceed_match_limit(SELF) ? Qtrue : Qfalse;
}

/**
 * @param limit [Integer]
 *
 * @return [nil]
 */
static VALUE query_cursor_set_match_limit(VALUE self, VALUE limit) {
  ts_query_cursor_set_match_limit(SELF, NUM2UINT(limit));
  return Qnil;
}

/**
 * @return [Integer]
 */
static VALUE query_cursor_get_match_limit(VALUE self) {
  return UINT2NUM(ts_query_cursor_match_limit(SELF));
}

/**
 * Set the maximum start depth for a query cursor.
 *
 * This prevents cursors from exploring children nodes at a certain depth.
 * Note if a pattern includes many children, then they will still be checked.
 *
 * The zero max start depth value can be used as a special behavior and
 * it helps to destructure a subtree by staying on a node and using captures
 * for interested parts. Note that the zero max start depth only limit a search
 * depth for a pattern's root node but other nodes that are parts of the pattern
 * may be searched at any depth what defined by the pattern structure.
 *
 * @param max_start_depth [Integer|nil] set to nil to remove the maximum start
 * depth.
 *
 * @return [nil]
 */
static VALUE query_cursor_set_max_start_depth(VALUE self,
                                              VALUE max_start_depth) {
  uint32_t max = UINT32_MAX;
  if (!NIL_P(max_start_depth)) {
    max = NUM2UINT(max_start_depth);
  }
  ts_query_cursor_set_max_start_depth(SELF, max);
  return Qnil;
}

// FIXME: maybe this is the limit of how "transparent" the bindings need to be.
// Pending benchmarks, this can be very inefficient because obviously
// ts_query_cursor_next_capture is intended to be used in a loop.  Creating an
// array of two values and returning them, intuitively speaking, seem very
// inefficient.
// FIXME: maybe this needs to return an empty array to make for a nicer ruby
// API?
/**
 * Advance to the next capture of the currently running query.
 *
 * @return [Array<Integer|Boolean>|nil] If there is a capture, return a tuple
 * [Integer, Boolean], otherwise return +nil+.
 */
static VALUE query_cursor_next_capture(VALUE self) {
  TSQueryMatch match;
  uint32_t index;
  if (ts_query_cursor_next_capture(SELF, &match, &index)) {
    VALUE res = rb_ary_new_capa(2);
    rb_ary_push(res, UINT2NUM(index));
    rb_ary_push(res, new_query_match(&match));
    return res;
  } else {
    return Qnil;
  }
}

/**
 * Advance to the next match of the currently running query.
 *
 * @return [Boolean] Whether there's a match.
 */
static VALUE query_cursor_next_match(VALUE self) {
  TSQueryMatch match;
  if (ts_query_cursor_next_match(SELF, &match)) {
    return new_query_match(&match);
  } else {
    return Qnil;
  }
}

static VALUE query_cursor_remove_match(VALUE self, VALUE id) {
  ts_query_cursor_remove_match(SELF, NUM2UINT(id));
  return Qnil;
}

/**
 * @param from [Integer]
 * @param to   [Integer]
 *
 * @return [nil]
 */
static VALUE query_cursor_set_byte_range(VALUE self, VALUE from, VALUE to) {
  ts_query_cursor_set_byte_range(SELF, NUM2UINT(from), NUM2UINT(to));
  return Qnil;
}

/**
 * @param from [Point]
 * @param to   [Point]
 *
 * @return [nil]
 */
static VALUE query_cursor_set_point_range(VALUE self, VALUE from, VALUE to) {
  ts_query_cursor_set_point_range(SELF, value_to_point(from),
                                  value_to_point(to));
  return Qnil;
}

void init_query_cursor(void) {
  cQueryCursor = rb_define_class_under(mTreeSitter, "QueryCursor", rb_cObject);

  rb_define_alloc_func(cQueryCursor, query_cursor_allocate);

  /* Module methods */
  rb_define_module_function(cQueryCursor, "exec", query_cursor_exec_static, 2);

  /* Class methods */
  // Accessors
  DECLARE_ACCESSOR(cQueryCursor, query_cursor, match_limit)

  // Other
  rb_define_method(cQueryCursor, "exec", query_cursor_exec, 2);
  rb_define_method(cQueryCursor, "exceed_match_limit?",
                   query_cursor_did_exceed_match_limit, 0);
  rb_define_method(cQueryCursor, "match_limit", query_cursor_get_match_limit,
                   0);
  rb_define_method(cQueryCursor, "match_limit=", query_cursor_set_match_limit,
                   1);
  rb_define_method(cQueryCursor,
                   "max_start_depth=", query_cursor_set_max_start_depth, 1);
  rb_define_method(cQueryCursor, "next_capture", query_cursor_next_capture, 0);
  rb_define_method(cQueryCursor, "next_match", query_cursor_next_match, 0);
  rb_define_method(cQueryCursor, "remove_match", query_cursor_remove_match, 1);
  rb_define_method(cQueryCursor, "set_byte_range", query_cursor_set_byte_range,
                   2);
  rb_define_method(cQueryCursor, "set_point_range",
                   query_cursor_set_point_range, 2);
}
