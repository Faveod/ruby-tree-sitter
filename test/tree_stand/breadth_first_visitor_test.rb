# frozen_string_literal: true

require 'test_helper'

# Most of the visitor tests generate a tree from the the expression `1 * x + 3`.
# The S-expression below serves as visual documentation for the generated tree.
#
# (expression
#   (sum
#     (product
#       (number)
#       ("*")
#       (variable))
#     ("+")
#     (number)))
class BreadthFirstVisitorTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new('math')
  end

  def test_default_on_hook
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:on) { |node| acc << node.type }
    visitor.visit

    assert_equal(
      %i[expression sum product + number number * variable],
      acc,
    )
  end

  def test_custom_visitor_hooks
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    method = ->(node) { acc << node.type }
    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:on_sum, method)
    visitor.define_singleton_method(:on_number, method)
    visitor.define_singleton_method(:on_expression, method)
    visitor.visit

    assert_equal(
      %i[expression sum number number],
      acc,
    )
  end

  def test_default_on_hook_doesnt_run_when_a_custom_hook_is_defined
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:on) { |node| acc << node.type }
    visitor.define_singleton_method(:on_sum) { |_node| acc << :custom_sum }
    visitor.visit

    assert_equal(
      %i[expression custom_sum product + number number * variable],
      acc,
    )
  end

  def test_default_around_hook
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    method = ->(node, &block) do
      acc << "before:#{node.type}"
      block.call
      acc << "after:#{node.type}"
    end
    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:around, method)
    visitor.visit

    assert_equal(
      %w[
        before:expression
        after:expression
        before:sum
        after:sum
        before:product
        after:product
        before:+
        after:+
        before:number
        after:number
        before:number
        after:number
        before:*
        after:*
        before:variable
        after:variable
      ],
      acc,
    )
  end

  def test_custom_around_hooks
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    method = ->(node, &block) do
      acc << "before:#{node.type}"
      block.call
      acc << "after:#{node.type}"
    end
    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:around_sum, method)
    visitor.define_singleton_method(:around_number, method)
    visitor.define_singleton_method(:around_expression, method)
    visitor.visit

    assert_equal(
      %w[
        before:expression
        after:expression
        before:sum
        after:sum
        before:number
        after:number
        before:number
        after:number
      ],
      acc,
    )
  end

  def test_around_hooks_traverse_children_only_when_yielding
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:on) { |node| acc << node.type }
    visitor.define_singleton_method(:around_product) { |node, &block| }
    visitor.visit

    assert_equal(
      %i[expression sum product + number],
      acc,
    )
  end

  def test_default_around_hook_doesnt_run_when_a_custom_hook_is_defined
    tree = @parser.parse_string(<<~MATH)
      1 * x + 3
    MATH

    acc = []

    method = ->(node, &block) do
      acc << "before:#{node.type}"
      block.call
      acc << "after:#{node.type}"
    end
    visitor = TreeStand::BreadthFirstVisitor.new(tree.root_node)
    visitor.define_singleton_method(:around, method)
    visitor.define_singleton_method(:around_sum) { |_node| acc << 'around:sum' }
    visitor.visit

    assert_equal(
      %w[
        before:expression
        after:expression
        around:sum
      ],
      acc,
    )
  end
end
