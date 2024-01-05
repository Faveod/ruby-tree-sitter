# frozen_string_literal: true

require 'test_helper'

class AstModifierTest < Minitest::Test
  def setup
    @parser = TreeStand::Parser.new('math')
  end

  def test_can_work_with_multiple_edits
    tree = @parser.parse_string(<<~MATH)
      1 + x * 3 - x - 2 * 4 + 5
    MATH

    TreeStand::AstModifier.new(tree).on_match(<<~QUERY) do |_ast, match|
      (product) @product
    QUERY
      node = match['product']
      parent = node.parent

      if parent.left == node
        tree.edit!(parent.range, parent.right.text)
      else
        tree.edit!(parent.range, parent.left.text)
      end
    end

    assert_equal(<<~MATH, tree.document)
      1 - x + 5
    MATH
  end
end
