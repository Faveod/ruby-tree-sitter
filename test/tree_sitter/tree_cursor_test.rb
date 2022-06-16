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

describe 'TreeCursor should work properly' do
  before do
    @cursor = TreeSitter::TreeCursor.new(root)
  end
  
  it 'must return root node when created' do
    assert_equal root, @cursor.current_node
  end

  it 'must return root node when reset after creation' do
    @cursor.reset(root)
    assert_equal root, @cursor.current_node
  end

  it 'must reset to an arbitrary node' do
    @cursor.reset(root.child(0).child(0))
    assert_equal root.child(0).child(0), @cursor.current_node
  end

  it 'must move on the tree properly' do
    @cursor.goto_first_child
    assert_equal root.child(0), @cursor.current_node

    @cursor.goto_first_child
    @cursor.goto_next_sibling
    assert_equal root.child(0).child(0).next_sibling, @cursor.current_node

    @cursor.goto_parent
    assert_equal root.child(0), @cursor.current_node

    @cursor.reset(root)
    assert_equal root, @cursor.current_node
  end
end
