# frozen_string_literal: true

require 'test_helper'

class NodeTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new('math')
    @tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH
  end

  def test_accessors
    assert_instance_of(TreeSitter::Node, @tree.root_node.ts_node)
    assert_equal(@tree, @tree.root_node.tree)
  end

  def test_children
    assert_equal(1, @tree.root_node.children.size)
    assert_equal(1, @tree.root_node.to_a.size)
  end

  def test_can_enumerate_children
    expression = @tree.root_node
    assert_equal(:expression, expression.type)

    sum = expression.first
    assert_equal(:sum, sum.type)
    assert_equal(3, sum.count)

    number1, operator, product = sum.to_a
    assert_equal(:number, number1.type)
    assert_equal('1', number1.text)

    assert_equal('+', operator.text)

    assert_equal(:product, product.type)
  end

  def test_can_delegate_named_fields
    sum = @tree.root_node.first

    assert_equal(:number, sum.left.type)
    assert_equal('1', sum.left.text)
  end

  def test_can_navigate_to_the_parent_nodes
    node = @tree.root_node.first.first

    assert_equal(:expression, node.parent.parent.type)
    assert_equal(@tree.root_node, node.parent.parent)
  end

  def test_can_enumrate_named_children
    root = @tree.root_node
    node = root.children.first

    assert_equal([], root.each_field.to_a)
    assert_equal([[:left, node.left], [:right, node.right]], node.each_field.to_a)
  end

  def test_can_enumrate_fields
    root = @tree.root_node
    node = root.children.first

    assert_equal([root.named_child(0)], root.each_named.to_a)
    assert_equal([node.left, node.right], node.each_named.to_a)
  end

  def test_nodes_wrap_the_document_so_they_can_reference_text
    assert_equal(<<~MATH, @tree.root_node.text)
      1 + x * 3
    MATH

    number, _, product = @tree.root_node.first.to_a
    assert_equal('1', number.text)
    assert_equal('x * 3', product.text)
  end

  def test_nodes_wrap_range_in_a_comparable_struct
    assert_instance_of(TreeStand::Range, @tree.root_node.range)
  end

  def test_query_for_root_node_returns_the_same_as_query_for_tree
    tree = @parser.parse_string(<<~MATH)
      (1 + x) * (2 + 3)
    MATH

    # Tree#query
    matches = tree.query(<<~QUERY)
      (sum) @sum
    QUERY

    assert_equal(2, matches.size)
    assert_equal(['1 + x', '2 + 3'], matches.map { |m| m['sum'].text })

    # Node#query
    matches = tree.root_node.query(<<~QUERY)
      (sum) @sum
    QUERY

    assert_equal(2, matches.size)
    assert_equal(['1 + x', '2 + 3'], matches.map { |m| m['sum'].text })
  end

  def test_query_for_node_returns_only_matches_within_that_node
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3 + 2
    MATH

    match = tree.query(<<~QUERY).first
      (sum) @sum
    QUERY

    node = match['sum']
    assert_equal('1 + x * 3 + 2', node.text)
    assert_equal(<<~MATH.chomp, node.left.text)
      1 + x * 3
    MATH

    # Query the parent node
    matches = node.left.query(<<~QUERY)
      (sum) @sum
    QUERY

    assert_equal(1, matches.size)
    assert_equal('1 + x * 3', matches.dig(0, 'sum').text)
  end

  def test_error_nodes
    tree = @parser.parse_string(<<~MATH)
      1 ++ x
    MATH

    refute_predicate(tree.root_node, :error?)
    assert_predicate(tree.root_node.first.children[2], :error?)
  end

  def test_find_node_returns_the_first_node_that_matches_the_query
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3 + 2 * 4
    MATH

    product_node = tree.root_node.find_node!(<<~QUERY)
      (product) @product
    QUERY

    assert_equal('x * 3', product_node.text)
  end

  def test_find_node
    [
      '(product) @product',
      '(sum) @subtraction',
      '(sum left: (number) @number)',
      '(product left: (variable)) @sum',
    ].each do |query|
      refute_nil(@tree.root_node.find_node!(query))
    end
  end

  def test_find_node_with_no_matches
    [
      '(product)',
      '(subtraction) @subtraction',
      '(sum left: (number) right: (number)) @sum',
      '(product right: (variable)) @sum',
    ].each do |query|
      node = @tree.root_node.find_node(query)
      assert_nil(node, "Expected to find no node for query: #{query}")

      assert_raises(TreeStand::NodeNotFound) do
        @tree.root_node.find_node!(query)
      end
    end
  end

  def test_respond_to_missing
    assert_respond_to(@tree.root_node.first, :left)
  end
end
