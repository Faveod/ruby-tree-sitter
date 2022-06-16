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
