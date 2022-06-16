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

# NOTE: I was trying to parse invalid programs and see what happens.
#
# What happens = undefined behavior with the ruby parsers.
#
# Sometimes it would parse normally and return an instance of Tree, and
# sometimes it would return nil.  That goes for both `parse_string` and
# `parse_string_encoded`.
#
# I suspect the same thing would happen with `parse`

# margorp = <<~YBUR
#   fibfast n = fib' 0 1 n
#     where fib' a b n | n <= 1 = b
#                      | otherwise = fib' b (a+b) (n-1)
# YBUR

program_16 = program.encode('utf-16')
# margorp_16 = margorp.encode('utf-16')

describe 'loading a language' do
  before do
    parser.reset
  end

  it 'must set/get the same language' do
    parser.language = ruby
    assert_equal ruby, parser.language
  end
end

describe 'parse_string' do
  before do
    parser.reset
  end

  it 'must parse nil' do
    res = parser.parse_string(nil, nil)
    assert_nil res
  end

  [
    ['empty', '', 0],
    ['valid', program, 1],
    # ['invalid', margorp, 3]
  ].each do |q, p, c|
    it "must parse #{q} programs" do
      res = parser.parse_string(nil, p)
      assert_instance_of TreeSitter::Tree, res

      root = res.root_node
      assert_instance_of TreeSitter::Node, root
      assert_equal c, root.child_count
    end
  end
end

describe 'parse_string_encoding' do
  before do
    parser.reset
  end

  it 'must parse nil' do
    res = parser.parse_string_encoding(nil, nil, :utf8)
    assert_nil res
    res = parser.parse_string_encoding(nil, nil, :utf16)
    assert_nil res
  end

  [
    ['empty', '', 0, :utf8],
    ['valid', program, 1, :utf8],
    # ['invalid', margorp, 3, :utf8],
    ['empty', ''.encode('utf-16'), 0, :utf16],
    ['valid', program_16, 1, :utf16],
    # ['invalid', margorp_16, 1, :utf16]
  ].each do |q, p, c, e|
    it "must parse #{q} programs in #{e}" do
      res = parser.parse_string_encoding(nil, p, e)
      assert_instance_of TreeSitter::Tree, res

      root = res.root_node
      assert_instance_of TreeSitter::Node, root
      assert_equal c, root.child_count
    end
  end
end

describe 'print_dot_graphs' do
  before do
    parser.reset
  end

  it 'must save its debug info to a file' do
    dot = File.expand_path('tmp/debug-dot.gv', FileUtils.getwd)
    parser.print_dot_graphs(dot)
    parser.parse_string(nil, program)

    assert File.exist?(dot), 'dot file must be exist'
    assert File.file?(dot), 'dot file must be a file'
    refute_equal 0, File.size(dot)
  end
end

describe 'canecalation_flags' do
  it 'must get/set cancellation_flah' do
    parser.cancellation_flag = 1
    assert_equal 1, parser.cancellation_flag
  end
end

describe 'timeout_micros' do
  it 'must get/set timeout_micros' do
    parser.timeout_micros = 1
    assert_equal 1, parser.timeout_micros
  end
end

# TODO: included_ranges for parsing partial documents.

# TODO: parsing with non-nil tree.

# TODO: parsing Input streams.  We're currently just hading the callback from
#       C-space to Ruby-space At some point we might need to implement a
#       buffered input reader and we should test it here.
