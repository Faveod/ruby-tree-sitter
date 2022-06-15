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

margorp = <<~YBUR
  fibfast n = fib' 0 1 n
    where fib' a b n | n <= 1 = b
                     | otherwise = fib' b (a+b) (n-1)
YBUR

describe 'loading a language' do
  it 'must set/get the same language' do
    parser.language = ruby
    assert_equal ruby, parser.language
  end
end

describe 'parse_string' do
  it 'must parse nil' do
    res = parser.parse_string(nil, nil)
    assert_nil res
  end

  [
    ['empty', '', 0],
    ['valid', program, 1],
    ['invalid', margorp, 3]
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

# TODO: parsing with non-nil tree.

# TODO: parsing Input streams.  We're currently just hading the callback from
#       C-space to Ruby-space At some point we might need to implement a
#       buffered input reader and we should test it here.
