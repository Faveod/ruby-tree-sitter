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

describe 'copy' do
  it 'must make a new copy' do
    copy = tree.copy
    refute_equal tree, copy
  end
end

describe 'root_node' do
  it 'must be of type TreeSitter::Node' do
    root = tree.root_node
    assert_instance_of TreeSitter::Node, root
  end
end

describe 'language' do
  it 'must be identical to parser language' do
    assert_equal parser.language, tree.language
  end
end
