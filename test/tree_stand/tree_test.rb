# frozen_string_literal: true

require 'test_helper'

class TreeTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new('math')
  end

  def test_text
    document = '1 + x * 3 + 2'
    tree = @parser.parse_string(document)
    assert_equal(document, tree.document)
  end

  def test_can_replace_text
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3 + 2
    MATH

    match = tree.query(<<~QUERY).first
      (product) @product
    QUERY

    node = match['product']
    parent = node.parent

    tree.edit!(parent.range, parent.left.text)

    assert_equal(<<~MATH, tree.document)
      1 + 2
    MATH
  end

  def test_can_delete_a_node
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3 + 2
    MATH

    match = tree.query(<<~QUERY).first
      (product) @product
    QUERY

    node = match['product']

    tree.delete!(node.range)

    assert_equal(<<~MATH, tree.document)
      1 +  + 2
    MATH
  end

  def test_can_handle_invalid_edits
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3 + 2
    MATH

    match = tree.query(<<~QUERY).first
      (product) @product
    QUERY

    node = match['product']

    tree.edit!(node.range, 'y **')

    assert_equal(<<~MATH, tree.document)
      1 + y ** + 2
    MATH
  end
end
