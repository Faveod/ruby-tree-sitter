# frozen_string_literal: true

require_relative '../test_helper.rb'

ruby = lang('ruby')
parser = TreeSitter::Parser.new
parser.language = ruby

program = <<~RUBY
  def mul(a, b)
    res = a* b
    puts res.inspect
    return res
  end
RUBY

tree = parser.parse_string(nil, program)
root = tree.root_node

puts root

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

    preds_0 = query.predicates_for_pattern(0)
    assert_instance_of Array, preds_0
    assert_equal 0, preds_0.size

    preds_1 = query.predicates_for_pattern(1)
    assert_instance_of Array, preds_1
    assert_equal 0, preds_1.size

    query = TreeSitter::Query.new(ruby, predicate)
    preds_2 = query.predicates_for_pattern(0)
    assert_instance_of Array, preds_2
    assert_equal 4, preds_2.size
  end

  it 'must return string names, quanitfier, and string value for capture id' do
    query = TreeSitter::Query.new(ruby, predicate)
    query.predicates_for_pattern(0).each do |step|
      if TreeSitter::QueryPredicateStep::CAPTURE == step.type
        assert_equal 'args', query.capture_name_for_id(step.value_id)
        assert_equal TreeSitter::Quantifier::ONE_OR_MORE, query.capture_quantifier_for_id(0, step.value_id)
        assert_equal 'match?', query.string_value_for_id(step.value_id)
      end
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
  #TODO: pattern guaranteed at step
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
end
