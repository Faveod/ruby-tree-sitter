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

describe 'type' do
  it 'must be a Symbol' do
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

describe 'named_child' do
  before do
    @child = root.child(0)
  end

  it 'must return proper node' do
    assert_equal @child.named_child(0), @child.child_by_field_name('name')
    assert_equal @child.named_child(0), @child.child_by_field_name(:name)
    assert_equal @child.named_child(1), @child.child_by_field_name('parameters')
    assert_equal @child.named_child(1), @child.child_by_field_name(:parameters)
  end

  it 'must raise IndexError when out of range' do
    assert_raises(IndexError) { @child.named_child(13) }
    assert_raises(IndexError) { @child.named_child(-13) }
  end
end

describe 'child' do
  before do
    @child = root.child(0)
  end

  it 'must know whether a field exists' do
    assert_equal true, @child.field?('name')
    assert_equal true, @child.field?(:name)
    assert_equal false, @child.field?('something')
    assert_equal false, @child.field?(:something)
  end

  it 'must return proper children count' do
    assert_equal 1, root.child_count
  end

  it 'must return proper name child count' do
    assert_equal 3, @child.named_child_count
  end

  it 'must return proper name child' do
    assert_equal @child.child(1), @child.named_child(0)
  end

  it 'must return proper child by field name' do
    assert_equal @child.child(1), @child.child_by_field_name('name')
    assert_equal @child.child(1), @child.child_by_field_name(:name)
    assert_nil @child.child_by_field_name('something')
    assert_nil @child.child_by_field_name(:something)
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
    assert_raises(IndexError) { root.child(13).parent }
    assert_raises(IndexError) { root.child(-13).parent }
    assert_raises(IndexError) { @child.descendant_for_byte_range(child.end_byte, child.start_byte) }
    assert_raises(IndexError) { @child.named_descendant_for_byte_range(child.end_byte, child.start_byte) }
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

  it 'must raise an exception for a wrong index' do
    assert_raises(IndexError) { @child.field_name_for_child(13) }
    assert_raises(IndexError) { @child.field_name_for_child(-13) }
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

  it 'must raise an exception when index is does not exist' do
    assert_raises(IndexError) { @child[13] }
    assert_raises(IndexError) { @child['something'] }
    assert_raises(IndexError) { @child[:something] }
    assert_raises(ArgumentError) { @child[1.0] }
    assert_raises(ArgumentError) { @child[[:name]] }
    assert_raises(ArgumentError) { @child[[:something]] }
    assert_raises(ArgumentError) { @child[{ name: :something }] }
  end

  it 'must return an array of nodes when index is an Array' do
    arr = [@child.named_child(0)] * 3
    assert_equal arr, @child[0, :name, 'name']
  end

  it 'must throw an exception when out of index' do
    assert_raises { @child[255] }
  end

  it 'must throw an exception when field is not found (NO SIGSEGV ANYMORE!)' do
    assert_raises { @child[:randomzes] }
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

describe 'Enumerable' do
  it 'should be' do
    _(root.class.ancestors).must_be :include?, Enumerable
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

describe 'to_a' do
  before do
    @child = root.child(0)
  end

  it 'should return the list from each' do
    ll = @child.to_a

    refute ll.empty?

    @child.each.with_index do |c, i|
      assert_equal @child.child(i), c
    end
  end
end

describe 'fetch' do
  before do
    @child = root.child(0)
  end

  it 'should retrun an array of the same size of requested keys' do
    assert_equal [], @child.fetch
    assert_equal [nil], @child.fetch(:fake)
    assert_equal [@child.name, @child.name], @child.fetch(:name, :name)
    assert_equal [@child.name, nil], @child.fetch(:name, :fake)
    assert_equal [nil, @child.name], @child.fetch(:fake, :name)
    assert_equal [@child.name, nil, @child.name], @child.fetch(:name, :fake, :name)
    assert_equal [@child.name, @child.name, nil], @child.fetch(:name, :name, :fake)
    assert_equal [nil, nil, @child.name], @child.fetch(:fake, :whatever, :name)
    assert_equal [nil, nil, @child.name], @child.fetch(:fake, :fake, :name)
    assert_equal [nil, @child.name, nil], @child.fetch(:fake, :name, :fake)
    assert_equal [nil, @child.name, nil], @child.fetch(:whatever, :name, :fake)
    assert_equal [@child.name, nil, nil], @child.fetch(:name, :fake, :fake)
    assert_equal [@child.name, nil, nil], @child.fetch(:name, :whatever, :fake)
    assert_equal [@child.name, @child.parameters, nil], @child.fetch(:name, :parameters, :fake)
    assert_equal [@child.parameters, @child.name, nil], @child.fetch(:parameters, :name, :fake)
    assert_equal [@child.parameters, nil, @child.name], @child.fetch(:parameters, :fake, :name)
    assert_equal [@child.parameters, nil, @child.name, nil], @child.fetch(:parameters, :fake, :name, :fake)
    assert_equal [@child.parameters, nil, @child.name, nil], @child.fetch(:parameters, :fake, :name, :whatever)
  end

  describe 'sexpr' do
    it 'should print a proper sexpr' do
      assert_equal root.sexpr, <<~SEXPR.chomp
        (program
          (method
            (def)
            name: (identifier)
            parameters: (method_parameters (() (identifier) (,) (identifier) ()))
            body:
              (body_statement
                (assignment left: (identifier) (=) right: (binary left: (identifier) operator: (*) right: (identifier)))
                (call
                  method: (identifier)
                  arguments: (argument_list (call receiver: (identifier) operator: (.) method: (identifier))))
                (return (return) (argument_list (identifier))))
            (end)))
      SEXPR
    end

    it 'should print a sexpr with sources on the margins' do
      assert_equal root.sexpr(source: program), <<~SEXPR.chomp
        (program                          |
          (method                         |
            (def)                         |
            name:                         |
              (identifier)                |mul
            parameters:                   |
              (method_parameters          |
                (()                       |
                (identifier)              |a
                (,)                       |
                (identifier)              |b
                ()))                      |
            body:                         |
              (body_statement             |
                (assignment               |
                  left:                   |
                    (identifier)          |res
                  (=)                     |
                  right:                  |
                    (binary               |
                      left:               |
                        (identifier)      |a
                      operator:           |
                        (*)               |
                      right:              |
                        (identifier)))    |b
                (call                     |
                  method:                 |
                    (identifier)          |puts
                  arguments:              |
                    (argument_list        |
                      (call               |
                        receiver:         |
                          (identifier)    |res
                        operator:         |
                          (.)             |
                        method:           |
                          (identifier)))) |inspect
                (return                   |
                  (return)                |
                  (argument_list          |
                    (identifier))))       |res
            (end)))                       |
      SEXPR
    end

    it 'should print a vertical sexpr without sources' do
      assert_equal root.sexpr(vertical: true), <<~SEXPR.chomp
        (program
          (method
            (def)
            name:
              (identifier)
            parameters:
              (method_parameters
                (()
                (identifier)
                (,)
                (identifier)
                ()))
            body:
              (body_statement
                (assignment
                  left:
                    (identifier)
                  (=)
                  right:
                    (binary
                      left:
                        (identifier)
                      operator:
                        (*)
                      right:
                        (identifier)))
                (call
                  method:
                    (identifier)
                  arguments:
                    (argument_list
                      (call
                        receiver:
                          (identifier)
                        operator:
                          (.)
                        method:
                          (identifier))))
                (return
                  (return)
                  (argument_list
                    (identifier))))
            (end)))
      SEXPR
    end
  end
end
