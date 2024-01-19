# frozen_string_literal: true

require 'test_helper'

class ParserSetupTest < Minitest::Test
  def test_can_parse_a_document
    parser = TreeSitter::Parser.new.tap do |p|
      p.language = TreeSitter::Language.load('math', 'tree-sitter-parsers/math.so')
    end

    tree = parser.parse_string(nil, <<~MATH)
      1 + x * 3
    MATH

    query = TreeSitter::Query.new(parser.language, <<~QUERY)
      (expression
        (sum
          left: (number)
          right: (product
            left: (variable)
            right: (number))))
    QUERY
    cursor = TreeSitter::QueryCursor.exec(query, tree.root_node)

    refute_nil(cursor.next_match)
  end

  def test_can_parse_a_document_with_tree_stand_api
    parser = TreeStand::Parser.new('math')
    tree = parser.parse_string(<<~MATH)
      1 + x * 3
    MATH

    matches = tree.query(<<~QUERY)
      (expression
        (sum
          left: (number)
          right: (product
            left: (variable)
            right: (number))))
    QUERY

    assert_equal(1, matches.size)
  end

  def test_parse_document_with_errors
    parser = TreeStand::Parser.new('math')
    document = <<~MATH
      1 + x * 3 // 3
    MATH

    tree = parser.parse_string(document)
    assert(tree.any?(&:error?))

    assert_raises(TreeStand::InvalidDocument) do
      parser.parse_string!(document)
    end
  end
end
