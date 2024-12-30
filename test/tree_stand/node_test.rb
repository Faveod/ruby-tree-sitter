# frozen_string_literal: true

require 'test_helper'

class NodeTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new('math')
    @tree = @parser.parse_string(<<~MATH)
      1 + x * 3
    MATH
  end

  def test_node_text
    parser = TreeStand::Parser.new('javascript')
    tree = parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    number, _, product = tree.root_node.first.first.to_a
    assert_equal('1', number.text)
    assert_equal('x * 3', product.text)

    tree = parser.parse_string(<<~MATH)
      1 + â * 3
    MATH

    number, _, product = tree.root_node.first.first.to_a
    assert_equal('1', number.text)
    assert_equal('â * 3', product.text)
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

  def test_can_enumerate_named_children
    root = @tree.root_node
    node = root.children.first

    assert_equal([], root.each_field.to_a)
    assert_equal([[:left, node.left], [:right, node.right]], node.each_field.to_a)
  end

  def test_can_enumerate_fields
    root = @tree.root_node
    node = root.children.first

    assert_equal([root.named_child(0)], root.each_named.to_a)
    assert_equal([node.left, node.right], node.each_named.to_a)
  end

  def test_can_call_thinly_wrapped_and_mapped
    node = @tree.root_node.children.first
    assert_equal(node.left, node.field(:left))
    assert_equal(node.left, node.field('left'))
  end

  def test_children_access_by_index # rubocop:disable Metrics/AbcSize
    sum = @tree.root_node.first

    assert_raises(ArgumentError) { sum[] }
    assert_raises(ArgumentError) { sum[1.0] }
    assert_raises(ArgumentError) { sum[[]] }
    assert_raises(ArgumentError) { sum[[1]] }
    assert_raises(ArgumentError) { sum[{ keys: [1] }] }
    assert_raises(ArgumentError) { sum[1.0] }

    assert_equal(sum.left, sum[:left])
    assert_equal([sum.left, sum.right], sum[:left, :right])
    assert_equal([sum.left, sum.right, sum.right, sum.left], sum[:left, :right, :right, :left])
    assert_equal(sum.left, sum[0])
    assert_equal([sum.left, sum.right], sum[0, 1])
    assert_equal([sum.left, sum.right, sum.right, sum.left], sum[0, 1, 1, 0])

    assert_raises(IndexError) { sum[:whatever] }
    assert_raises(IndexError) { sum[:left, :whatever] }
    assert_raises(IndexError) { sum[:whatever, :left] }
    assert_raises(IndexError) { sum[-1] }
    assert_raises(IndexError) { sum[0, -1] }
    assert_raises(IndexError) { sum[-1, 0] }
    assert_raises(IndexError) { sum[13] }
    assert_raises(IndexError) { sum[0, 13] }
    assert_raises(IndexError) { sum[13, 0] }
  end

  def test_children_access_by_fetch # rubocop:disable Metrics/AbcSize
    sum = @tree.root_node.first

    assert_equal([nil], sum.fetch(-1))
    assert_equal([nil], sum.fetch(12))
    assert_equal([nil], sum.fetch(0))
    assert_equal([nil, nil], sum.fetch(0, 1))
    assert_equal([nil, nil], sum.fetch(0, -1))
    assert_equal([nil, nil], sum.fetch(-1, 0))
    assert_equal([nil, nil], sum.fetch(-1, 0))
    assert_equal([nil, nil, nil], sum.fetch(0, -1, 1))
    assert_equal([nil, nil, nil], sum.fetch(0, 1, -1))
    assert_equal([nil, nil, nil, nil], sum.fetch(-1, 0, 1, -1))

    assert_equal([], sum.fetch)
    assert_equal([nil], sum.fetch(:whatever))
    assert_equal([nil, sum.right], sum.fetch(:whatever, :right))
    assert_equal([nil, sum.left, sum.right], sum.fetch(:whatever, :left, :right))
    assert_equal([nil, sum.right, sum.left], sum.fetch(:whatever, :right, :left))
    assert_equal([nil, sum.left, nil, sum.left], sum.fetch(:whatever, :left, :and, :left))
    assert_equal([nil, sum.left, nil, sum.left, sum.right], sum.fetch(:whatever, :left, :and, :left, :right))
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

    assert_equal(2, matches.size)
    assert_equal('1 + x * 3 + 2', matches.dig(0, 'sum').text)
    assert_equal('1 + x * 3', matches.dig(1, 'sum').text)
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

  def test_def_delegators
    assert_equal(:expression, @tree.root_node.type)
  end

  def test_respond_to_missing
    assert_respond_to(@tree.root_node.first, :left)
  end

  def test_sexpr
    assert_equal <<~SEXPR.chomp, @tree.root_node.sexpr(width: 10)
      (expression
        (sum
          left:
            (number)
          (+)
          right:
            (product
              left:
                (variable)
              (*)
              right:
                (number))))
    SEXPR
  end

  def test_pp
    output = StringIO.new
    PP.pp(@tree.root_node, output)
    assert_equal <<~SEXPR, output.string
      (expression           |
        (sum                |
          left:             |
            (number)        |1
          (+)               |
          right:            |
            (product        |
              left:         |
                (variable)  |x
              (*)           |
              right:        |
                (number)))) |3
    SEXPR
  end
end
