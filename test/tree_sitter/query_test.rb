# frozen_string_literal: true

require_relative '../test_helper'

ruby = TreeSitter.lang('ruby')
parser = TreeSitter::Parser.new
parser.language = ruby

program = <<~RUBY
  def mul(a, b)
    res = a * b
    puts res.inspect
    return res
  end
RUBY

tree = parser.parse_string(nil, program)
root = tree.root_node

pattern = '(method_parameters)'
capture = '(method_parameters (_)+ @args)'
predicate = '(method_parameters (_)+ @args (#match? @args "\w"))'
combined = "#{pattern} #{capture}"
# string = '(method_parameters (_)+ @args)'

# NOTE: It' still unclear to me what a captured string is.

describe 'pattern/capture/string' do
  it 'must return an Integer for pattern count' do
    query = TreeSitter::Query.new(ruby, pattern)
    assert_equal 1, query.pattern_count
    assert_equal 0, query.capture_count
    assert_equal 0, query.string_count
  end

  it 'must return an Integer for pattern count' do
    query = TreeSitter::Query.new(ruby, capture)
    assert_equal 1, query.pattern_count
    assert_equal 1, query.capture_count
    assert_equal 0, query.string_count
  end

  it 'must return an Integer for combined patterns' do
    query = TreeSitter::Query.new(ruby, combined)
    assert_equal 2, query.pattern_count
    assert_equal 1, query.capture_count
    assert_equal 0, query.string_count
  end

  it 'must return an Integer for pattern start byte' do
    query = TreeSitter::Query.new(ruby, combined)
    assert_equal 0, query.start_byte_for_pattern(0)
    assert_equal pattern.bytesize + 1, query.start_byte_for_pattern(1)
  end

  it 'must return an array of predicates for a pattern' do
    query = TreeSitter::Query.new(ruby, combined)

    preds0 = query.predicates_for_pattern(0)
    assert_instance_of Array, preds0
    assert_equal 0, preds0.size

    preds1 = query.predicates_for_pattern(1)
    assert_instance_of Array, preds1
    assert_equal 0, preds1.size

    query = TreeSitter::Query.new(ruby, predicate)
    preds2 = query.predicates_for_pattern(0)
    assert_instance_of Array, preds2
    assert_equal 4, preds2.size
  end

  it 'must return string names, quanitfier, and string value for capture id' do
    query = TreeSitter::Query.new(ruby, predicate)
    query.predicates_for_pattern(0).each do |step|
      next if step.type != TreeSitter::QueryPredicateStep::CAPTURE

      assert_equal 'args', query.capture_name_for_id(step.value_id)
      assert_equal TreeSitter::Quantifier::ONE_OR_MORE, query.capture_quantifier_for_id(0, step.value_id)
      assert_equal 'match?', query.string_value_for_id(step.value_id)
    end
  end

  it 'must disable captures but keep it in count' do
    query = TreeSitter::Query.new(ruby, capture)
    query.disable_capture('@args')
    assert_equal 1, query.capture_count
  end

  it 'must disable captures but keep it in count' do
    query = TreeSitter::Query.new(ruby, capture)
    query.disable_pattern(0)
    assert_equal 1, query.pattern_count
  end
  # TODO: pattern guaranteed at step
end

describe 'query_cursor' do
  before do
    @query = TreeSitter::Query.new(ruby, capture)
    @cursor = TreeSitter::QueryCursor.exec(@query, root)
  end

  it 'must work with limits' do
    @cursor.match_limit = 1
    assert_equal 1, @cursor.match_limit
    refute @cursor.exceed_match_limit?
    refute_nil @cursor.next_capture
    assert @cursor.exceed_match_limit?
  end

  it 'must work with byte range' do
    child = root.child(0).child(0)
    @cursor.set_byte_range(child.start_byte, child.end_byte)
    assert_nil @cursor.next_capture
  end

  it 'must work with point range' do
    child = root.child(0).child(0)
    @cursor.set_point_range(child.start_point, child.end_point)
    assert_nil @cursor.next_capture
  end

  it 'must work with next/remove' do
    assert_equal 0, @cursor.next_match.id
    @cursor.remove_match(1)
    assert_nil @cursor.next_match
  end
end

describe 'querying anonymous nodes' do
  it 'must match & capture the correct nodes' do
    binary = '(binary left: (identifier) operator: "*" right: (identifier)) @binary'
    prog = <<~RUBY
      c + d
      a * b
      e / f
    RUBY
    prog_tree = parser.parse_string(nil, prog)
    prog_root = prog_tree.root_node
    query = TreeSitter::Query.new(ruby, binary)
    cursor = TreeSitter::QueryCursor.exec(query, prog_root)

    while match = cursor.next_match
      refute_nil(match)
      assert_equal(1, match.captures.size)

      node = match.captures.first.node
      assert_equal 'a * b', prog[node.start_byte...node.end_byte]
    end
    assert_nil(match)
  end
end

describe 'query predicates' do
  it 'should handle string equality and regex matching' do
    src = <<~MATH
      1 + x * 3
    MATH
    math = TreeSitter.lang('math')
    parser = TreeSitter::Parser.new
    parser.language = math
    tree = parser.parse_string(nil, src)
    [
      { matches: 1, captures: 0, query: '(product)' },
      { matches: 0, captures: 0, query: '(subtraction) @subtraction' },

      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#eq? @l "1"))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#eq? @l "1 "))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#eq? @l "\\\d"))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#eq? @l "\\\d\\\s"))' },

      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#not-eq? @l "1 "))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#not-eq? @l "1"))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#not-eq? @l "\\\d"))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#not-eq? @l "\\\d\\\s\\\s"))' },

      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#match? @l "\\\d\\\s"))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#match? @l "\\\d\\\s+"))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#match? @l "\\\d\\\s*"))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#match? @l "\\\d\\\s?"))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#match? @l "\\\d\\\s\\\s"))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#match? @l "1"))' },
      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#match? @l "1 "))' },

      { matches: 0, captures: 0, query: '((sum left: (number) @l right: (_) @r) (#not-match? @l "1"))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#not-match? @l "1 "))' },
      { matches: 1, captures: 2, query: '((sum left: (number) @l right: (_) @r) (#not-match? @l "x+"))' },
    ].each do |t|
      q = TreeSitter::Query.new(math, t[:query])
      c = TreeSitter::QueryCursor.new
      assert_equal(
        t[:matches],
        c.matches(q, tree.root_node, src).each.to_a.length,
        "bad  matches for query #{t[:query]}",
      )
      assert_equal(
        t[:captures],
        c.captures(q, tree.root_node, src).each.to_a.length,
        "bad  captures for query #{t[:query]}",
      )
    end
  end

  it 'should handle `any-` predicates without quantification' do
    src = <<~MATH
      1 + x * 3 * 4 * 5
    MATH
    math = TreeSitter.lang('math')
    parser = TreeSitter::Parser.new
    parser.language = math
    tree = parser.parse_string(nil, src)
    [
      { matches: 1, captures: 1, query: '((product) @p (#eq? @p "x * 3"))' },
      { matches: 3, captures: 3, query: '((product) @p (#any-eq? @p "x * 3"))' },
      { matches: 3, captures: 3, query: '((product) @p (#any-not-eq? @p "x * 3"))' },
      { matches: 3, captures: 3, query: '((product) @p (#any-match? @p "aaaa"))' },
      { matches: 3, captures: 3, query: '((product) @p (#any-not-match? @p "aaaa"))' },
      { matches: 3, captures: 3, query: '((product) @p (#any-of? @p "aaaa" "xxxx"))' },
      { matches: 2, captures: 2, query: '((product) @p (#any-of? @p "x * 3" "xxxx"))' },
      { matches: 2, captures: 2, query: '((product) @p (#not-any-of? @p "x * 3" "xxxx"))' },
      { matches: 3, captures: 3, query: '((product) @p (#not-any-of? @p "aaaa" "xxxx"))' },
    ].each do |t|
      q = TreeSitter::Query.new(math, t[:query])
      c = TreeSitter::QueryCursor.new
      assert_equal(
        t[:matches],
        c.matches(q, tree.root_node, src).each.to_a.length,
        "bad matches for query #{t[:query]}",
      )
      assert_equal(
        t[:captures],
        c.captures(q, tree.root_node, src).each.to_a.length,
        "bad captures for query #{t[:query]}",
      )
    end
  end

  it 'should handle `any-` predicates with quantification I' do
    src = <<~MATH
      1 + x * 3 * 4 * 5
    MATH
    math = TreeSitter.lang('math')
    parser = TreeSitter::Parser.new
    parser.language = math
    tree = parser.parse_string(nil, src)
    [
      { matches: 3, captures: 3, query: '((product)+ @p (#any-eq? @p "x * 3"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-eq? @p "x * 3"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-eq? @p "x * 3"))' },

      { matches: 3, captures: 3, query: '((product)+ @p (#any-match? @p "^x$"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-match? @p "^x$"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-match? @p "^x$"))' },

      { matches: 3, captures: 3, query: '((product)+ @p (#any-not-eq? @p "x * 3"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-not-eq? @p "x * 3"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-not-eq? @p "x * 3"))' },

      { matches: 3, captures: 3, query: '((product)+ @p (#any-not-match? @p "\\\d?"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-not-match? @p "\\\d?"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-not-match? @p "\\\d?"))' },

      { matches: 2, captures: 2, query: '((product)+ @p (#any-of? @p "x * 3" "xxxx"))' },
      { matches: 3, captures: 3, query: '((product)+ @p (#any-of? @p "aaaa" "xxxx"))' },
      { matches: 16, captures: 2, query: '((product)? @p (#any-of? @p "x * 3" "xxxx"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-of? @p "aaaa" "xxxx"))' },
      { matches: 16, captures: 2, query: '((product)* @p (#any-of? @p "x * 3" "xxxx"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-of? @p "aaaa" "xxxx"))' },

      { matches: 3, captures: 3, query: '((product)+ @p (#any-not-of? @p "x * 3" "xxxx"))' },
      { matches: 3, captures: 3, query: '((product)+ @p (#any-not-of? @p "aaaa" "xxxx"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-not-of? @p "x * 3" "xxxx"))' },
      { matches: 17, captures: 3, query: '((product)? @p (#any-not-of? @p "aaaa" "xxxx"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-not-of? @p "x * 3" "xxxx"))' },
      { matches: 17, captures: 3, query: '((product)* @p (#any-not-of? @p "aaaa" "xxxx"))' },
    ].each do |t|
      q = TreeSitter::Query.new(math, t[:query])
      c = TreeSitter::QueryCursor.new
      assert_equal(
        t[:matches],
        c.matches(q, tree.root_node, src).each.to_a.length,
        "bad matches for query #{t[:query]}",
      )
      assert_equal(
        t[:captures],
        c.captures(q, tree.root_node, src).each.to_a.length,
        "bad captures for query #{t[:query]}",
      )
    end
  end

  it 'should handle `any-` predicates with quantification II' do
    src = <<~RUBY
      [1,1,1,1,1,1]
    RUBY
    math = TreeSitter.lang('ruby')
    parser = TreeSitter::Parser.new
    parser.language = math
    tree = parser.parse_string(nil, src)
    [
      { matches: 6, captures: 6, query: '((integer)+ @int (#any-eq? @int "1"))' },
      { matches: 21, captures: 6, query: '((integer)? @int (#any-eq? @int "1"))' },
      { matches: 21, captures: 6, query: '((integer)* @int (#any-eq? @int "1"))' },

      { matches: 6, captures: 6, query: '((integer)+ @int (#any-match? @int "xxxx"))' },
      { matches: 21, captures: 6, query: '((integer)? @int (#any-match? @int "xxxx"))' },
      { matches: 21, captures: 6, query: '((integer)* @int (#any-match? @int "xxxx"))' },

      { matches: 6, captures: 6, query: '((integer)+ @int (#any-not-eq? @int "1"))' },
      { matches: 21, captures: 6, query: '((integer)? @int (#any-not-eq? @int "1"))' },
      { matches: 21, captures: 6, query: '((integer)* @int (#any-not-eq? @int "1"))' },

      { matches: 6, captures: 6, query: '((integer)+ @int (#any-not-match? @int "\\\d"))' },
      { matches: 21, captures: 6, query: '((integer)? @int (#any-not-match? @int "\\\d"))' },
      { matches: 21, captures: 6, query: '((integer)* @int (#any-not-match? @int "\\\d"))' },
    ].each do |t|
      q = TreeSitter::Query.new(math, t[:query])
      c = TreeSitter::QueryCursor.new
      assert_equal(
        t[:matches],
        c.matches(q, tree.root_node, src).each.to_a.length,
        "bad matches for query #{t[:query]}",
      )
      assert_equal(
        t[:captures],
        c.captures(q, tree.root_node, src).each.to_a.length,
        "bad captures for query #{t[:query]}",
      )
    end
  end
end
