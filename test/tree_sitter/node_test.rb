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
    assert_instance_of Symbol, root.type
  end

  it 'must be "program" on root' do
    assert_equal :program, root.type
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
    # TODO: needs a more elaborate test to check for true changes?
    refute root.changed?
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

describe 'child' do
  before do
    @child = root.child(0)
  end

  it 'must return proper children count' do
    assert_equal 1, root.child_count
  end

  it 'must return proper name child count' do
    assert_equal 5, @child.named_child_count
  end

  it 'must return proper name child' do
    assert_equal @child.child(1), @child.named_child(0)
  end

  it 'must return proper child by field name' do
    assert_equal @child.child(1), @child.child_by_field_name('name')
  end

  it 'must return proper child by field id' do
    assert_equal @child.child(1), @child.child_by_field_id(ruby.field_id_for_name('name'))
  end

  it 'must return proper child for byte' do
    child = @child.child(0)
    assert_equal child, @child.first_child_for_byte(child.start_byte)
  end

  it 'must return proper named child for byte' do
    child = @child.child(1)
    assert_equal child, @child.first_named_child_for_byte(child.start_byte)
  end

  it 'must return proper descendant for byte range' do
    child = @child.child(1)
    assert_equal child, @child.descendant_for_byte_range(child.start_byte, child.end_byte)
  end

  it 'must return proper descendant for point range' do
    child = @child.child(1)
    assert_equal child, @child.descendant_for_point_range(child.start_point, child.end_point)
  end

  it 'must return proper named descendant for byte range' do
    child = @child.child(1)
    assert_equal child, @child.named_descendant_for_byte_range(child.start_byte, child.end_byte)
  end

  it 'must return proper named descendant for point range' do
    child = @child.child(1)
    assert_equal child, @child.named_descendant_for_point_range(child.start_point, child.end_point)
  end

  it 'must raise an exception for wrong ranges' do
    child = @child.child(0)
    assert_raises IndexError do
      @child.descendant_for_byte_range(child.end_byte, child.start_byte)
    end
    assert_raises IndexError do
      @child.named_descendant_for_byte_range(child.end_byte, child.start_byte)
    end
    assert_raises IndexError do
      p1 = TreeSitter::Point.new
      p1.row = @child.end_point.row
      p1.column = @child.end_point.column + 1
      @child.named_descendant_for_point_range(@child.start_point, p1)
    end
    assert_raises IndexError do
      p1 = TreeSitter::Point.new
      p1.row = @child.end_point.row
      p1.column = @child.end_point.column + 1
      @child.named_descendant_for_point_range(@child.start_point, p1)
    end
  end
end

describe 'field_name' do
  before do
    @child = root.child(0)
  end

  it 'must return proper field name' do
    assert_equal 'name', @child.field_name_for_child(1)
  end
end

describe 'siblings' do
  before do
    @child = root.child(0).child(0)
  end

  it 'must return proper next/previous siblings' do
    assert_equal @child, @child.next_sibling.prev_sibling
  end

  it 'must return proper next/previous named siblings' do
    assert_equal @child.parent.child(1), @child.next_named_sibling
  end
end

# TODO: edit

# Tese are High-Level Ruby APIs that we designed.
# They rely on the bindings.

describe '[]' do
  before do
    @child = root.child(0)
  end

  it 'must return a named child by index when index is an Integer' do
    assert_equal @child.named_child(0), @child[0]
  end

  it 'must return a child by field name when index is a (String | Symbol)' do
    assert_equal @child.named_child(0), @child[:name]
    assert_equal @child.named_child(0), @child['name']
  end
end

describe 'each' do
  before do
    @child = root.child(0)
  end

  it 'must iterate over all children' do
    i = 0
    @child.each do |_|
      i += 1
    end
    assert @child.child_count, i
  end

  it 'must iterate ove named children attached to fields only' do
    @child.each_field do |f, c|
      refute f.nil?
      refute f.empty?
      assert_equal @child[f], c
    end
  end

  it 'must iterate over named children when `each_named_child`' do
    i = 0
    @child.each_named do |c|
      assert c.named?
      i += 1
    end
    assert @child.named_child_count, i
  end
end

describe 'method_missing' do
  before do
    @child = root.child(0)
  end

  it 'should act like the [] method when we pass (String | Symbol)' do
    assert_equal @child[:name], @child.name
  end
end
