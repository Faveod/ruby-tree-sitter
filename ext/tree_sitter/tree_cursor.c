#include "tree_sitter.h"

extern VALUE mTreeSitter;

VALUE cTreeCursor;

DATA_TYPE(TSTreeCursor, tree_cursor)
static void tree_cursor_free(void *ptr) {
  tree_cursor_t *type = (tree_cursor_t *)ptr;
  ts_tree_cursor_delete(&type->data);
  xfree(ptr);
}
DATA_MEMSIZE(tree_cursor)
DATA_DECLARE_DATA_TYPE(tree_cursor)
DATA_ALLOCATE(tree_cursor)
DATA_UNWRAP(tree_cursor)
DATA_NEW(cTreeCursor, TSTreeCursor, tree_cursor)
DATA_FROM_VALUE(TSTreeCursor, tree_cursor)

/**
 * Safely copy a tree cursor.
 *
 * @return [TreeCursor]
 */
static VALUE tree_cursor_copy(VALUE self) {
  VALUE res = tree_cursor_allocate(cTreeCursor);
  tree_cursor_t *ptr = unwrap(res);
  ptr->data = ts_tree_cursor_copy(&SELF);
  return res;
}

/**
 * Get the depth of the cursor's current node relative to the original
 * node that the cursor was constructed with.
 *
 * @return [Integer]
 */
static VALUE tree_cursor_current_depth(VALUE self) {
  return UINT2NUM(ts_tree_cursor_current_depth(&SELF));
}

/**
 * Get the index of the cursor's current node out of all of the
 * descendants of the original node that the cursor was constructed with.
 *
 * @return [Integer]
 */
static VALUE tree_cursor_current_descendant_index(VALUE self) {
  return UINT2NUM(ts_tree_cursor_current_descendant_index(&SELF));
}

/**
 * Get the field id of the tree cursor's current node.
 *
 * This returns zero if the current node doesn't have a field.
 *
 * @see Node#child_by_field_id
 * @see Node#field_id_for_name
 *
 * @return [Integer]
 */
static VALUE tree_cursor_current_field_id(VALUE self) {
  return UINT2NUM(ts_tree_cursor_current_field_id(&SELF));
}

/**
 * Get the field name of the tree cursor's current node.
 *
 * This returns +nil+ if the current node doesn't have a field.
 *
 * @see Node#child_by_field_name
 *
 * @return [String]
 */
static VALUE tree_cursor_current_field_name(VALUE self) {
  return safe_str(ts_tree_cursor_current_field_name(&SELF));
}

/**
 * Get the tree cursor's current node.
 *
 * @return [Node]
 */
static VALUE tree_cursor_current_node(VALUE self) {
  TSNode node = ts_tree_cursor_current_node(&SELF);
  return new_node(&node);
}

/**
 * Move the cursor to the node that is the nth descendant of
 * the original node that the cursor was constructed with, where
 * zero represents the original node itself.
 *
 * @return [nil]
 */
static VALUE tree_cursor_goto_descendant(VALUE self, VALUE descendant_idx) {
  uint32_t idx = NUM2UINT(descendant_idx);
  ts_tree_cursor_goto_descendant(&SELF, idx);
  return Qnil;
}

/**
 * Move the cursor to the first child of its current node.
 *
 * This returns +true+ if the cursor successfully moved, and returns +false+
 * if there were no children.
 *
 * @return [Boolean]
 */
static VALUE tree_cursor_goto_first_child(VALUE self) {
  return ts_tree_cursor_goto_first_child(&SELF) ? Qtrue : Qfalse;
}

/**
 * Move the cursor to the first child of its current node that extends beyond
 * the given byte offset.
 *
 * This returns the index of the child node if one was found, and returns -1
 * if no such child was found.
 *
 * @return [Integer]
 */
static VALUE tree_cursor_goto_first_child_for_byte(VALUE self, VALUE byte) {
  return LL2NUM(
      ts_tree_cursor_goto_first_child_for_byte(&SELF, NUM2UINT(byte)));
}

/**
 * Move the cursor to the first child of its current node that extends beyond
 * the given or point.
 *
 * This returns the index of the child node if one was found, and returns -1
 * if no such child was found.
 *
 * @return [Integer]
 */
static VALUE tree_cursor_goto_first_child_for_point(VALUE self, VALUE point) {
  return LL2NUM(
      ts_tree_cursor_goto_first_child_for_point(&SELF, value_to_point(point)));
}

/**
 * Move the cursor to the last child of its current node.
 *
 * This returns +true+ if the cursor successfully moved, and returns +false+ if
 * there were no children.
 *
 * Note that this function may be slower than {#goto_first_child}
 * because it needs to iterate through all the children to compute the child's
 * position.
 */
static VALUE tree_cursor_goto_last_child(VALUE self) {
  return ts_tree_cursor_goto_last_child(&SELF) ? Qtrue : Qfalse;
}

/**
 * Move the cursor to the next sibling of its current node.
 *
 * This returns +true+ if the cursor successfully moved, and returns +false+
 * if there was no next sibling node.
 *
 * @return Boolean
 */
static VALUE tree_cursor_goto_next_sibling(VALUE self) {
  return ts_tree_cursor_goto_next_sibling(&SELF) ? Qtrue : Qfalse;
}

/**
 * Move the cursor to the parent of its current node.
 *
 * This returns +true+ if the cursor successfully moved, and returns +false+
 * if there was no parent node (the cursor was already on the root node).
 *
 * @return [Boolean]
 */
static VALUE tree_cursor_goto_parent(VALUE self) {
  return ts_tree_cursor_goto_parent(&SELF) ? Qtrue : Qfalse;
}

/**
 * Move the cursor to the previous sibling of its current node.
 *
 * This returns +true+ if the cursor successfully moved, and returns +false+ if
 * there was no previous sibling node.
 *
 * Note, that this function may be slower than
 * {#goto_next_sibling} due to how node positions are stored. In
 * the worst case, this will need to iterate through all the children upto the
 * previous sibling node to recalculate its position.
 *
 * @return [Boolean]
 */
static VALUE tree_cursor_goto_previous_sibling(VALUE self) {
  return ts_tree_cursor_goto_previous_sibling(&SELF) ? Qtrue : Qfalse;
}

/**
 * Create a new tree cursor starting from the given node.
 *
 * A tree cursor allows you to walk a syntax tree more efficiently than is
 * possible using the {Node} functions. It is a mutable object that is always
 * on a certain syntax node, and can be moved imperatively to different nodes.
 *
 * @return [TreeCursor]
 */
static VALUE tree_cursor_initialize(VALUE self, VALUE node) {
  TSNode n = value_to_node(node);
  tree_cursor_t *ptr = unwrap(self);
  ptr->data = ts_tree_cursor_new(n);
  return self;
}

/**
 * Re-initialize a tree cursor to start at a different node.
 *
 * @return [nil]
 */
static VALUE tree_cursor_reset(VALUE self, VALUE node) {
  ts_tree_cursor_reset(&SELF, value_to_node(node));
  return Qnil;
}

/**
 * Re-initialize a tree cursor to the same position as another cursor.
 *
 * Unlike {#reset}, this will not lose parent information and allows reusing
 * already created cursors.
 *
 * @return [nil]
 */
VALUE tree_cursor_reset_to(VALUE self, VALUE src) {
  ts_tree_cursor_reset_to(&SELF, &unwrap(src)->data);
  return Qnil;
}

void init_tree_cursor(void) {
  cTreeCursor = rb_define_class_under(mTreeSitter, "TreeCursor", rb_cObject);

  rb_define_alloc_func(cTreeCursor, tree_cursor_allocate);

  /* Class methods */
  rb_define_method(cTreeCursor, "copy", tree_cursor_copy, 0);
  rb_define_method(cTreeCursor, "current_depth", tree_cursor_current_depth, 0);
  rb_define_method(cTreeCursor, "current_descendant_index",
                   tree_cursor_current_descendant_index, 0);
  rb_define_method(cTreeCursor, "current_field_id",
                   tree_cursor_current_field_id, 0);
  rb_define_method(cTreeCursor, "current_field_name",
                   tree_cursor_current_field_name, 0);
  rb_define_method(cTreeCursor, "current_node", tree_cursor_current_node, 0);
  rb_define_method(cTreeCursor, "goto_descendant", tree_cursor_goto_descendant,
                   1);
  rb_define_method(cTreeCursor, "goto_first_child",
                   tree_cursor_goto_first_child, 0);
  rb_define_method(cTreeCursor, "goto_first_child_for_byte",
                   tree_cursor_goto_first_child_for_byte, 1);
  rb_define_method(cTreeCursor, "goto_first_child_for_point",
                   tree_cursor_goto_first_child_for_point, 1);
  rb_define_method(cTreeCursor, "goto_last_child", tree_cursor_goto_last_child,
                   0);
  rb_define_method(cTreeCursor, "goto_next_sibling",
                   tree_cursor_goto_next_sibling, 0);
  rb_define_method(cTreeCursor, "goto_parent", tree_cursor_goto_parent, 0);
  rb_define_method(cTreeCursor, "goto_previous_sibling",
                   tree_cursor_goto_previous_sibling, 0);
  rb_define_method(cTreeCursor, "initialize", tree_cursor_initialize, 1);
  rb_define_method(cTreeCursor, "reset", tree_cursor_reset, 1);
  rb_define_method(cTreeCursor, "reset_to", tree_cursor_reset_to, 1);
}
