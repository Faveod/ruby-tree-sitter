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

describe 'type' do
  it 'must be a string' do
    assert_instance_of String, root.type
  end

  it 'must be "program" on root' do
    assert_equal 'program', root.type
  end
end

describe 'symbol' do
  it 'must be an Integer' do
    assert_instance_of Integer, root.symbol
  end
end

describe 'start_byte' do
  it 'must be an Integer' do
    assert_instance_of Integer, root.start_byte
  end

  it 'must be an 0' do
    assert_equal 0, root.start_byte
  end
end

describe 'end_byte' do
  it 'must be an Integer' do
    assert_instance_of Integer, root.end_byte
  end

  it 'must not be 0' do
    refute_equal 0, root.end_byte
  end
end

describe 'start_point' do
  it 'must be an instance of point' do
    assert_instance_of TreeSitter::Point, root.start_point
  end

  it 'must be at row 0' do
    assert_equal 0, root.start_point.row
  end

  it 'must be at column 0' do
    assert_equal 0, root.start_point.row
  end
end

describe 'end_point' do
  it 'must be an instance of point' do
    assert_instance_of TreeSitter::Point, root.end_point
  end

  it 'must not be at row 0' do
    refute_equal 0, root.end_point.row
  end

  it 'must not be at column 0' do
    refute_equal 0, root.end_point.row
  end
end

describe 'string' do
  it 'must be an instance of string' do
    assert_instance_of String, root.to_s
  end

  it 'must be non-empty' do
    refute root.to_s.empty?
  end
end

describe 'predicates' do
  it 'must not be null' do
    refute_nil root.null?
  end

  it 'must be named' do
    assert root.named?
  end

  it 'must not be missing' do
    refute root.missing?
  end

  it 'must not be extra' do
    refute root.extra?
  end

  it 'must not have any changes' do
    refute root.changes?
  end

  it 'must not have no errors' do
    refute root.error?
  end
end

describe 'parent' do
  # NOTE: never call parent on root. It will segfault.
  #
  # tree-sitter does not provide a way to check if a node has a parent.

  it 'must never be nil' do
    refute_nil root.child(0).parent
  end

  it 'must be root for its children' do
    assert_equal root, root.child(0).parent
  end
end
