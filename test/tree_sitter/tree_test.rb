# frozen_string_literal: true

require_relative '../test_helper'

ruby = TreeSitter.lang('ruby')
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

describe 'print_dot_graph' do
  it 'must save to disk' do
    dot = File.expand_path('/tmp/tree-dot.gv', FileUtils.getwd)
    tree.print_dot_graph(dot)

    assert File.exist?(dot), 'dot file must be exist'
    assert File.file?(dot), 'dot file must be a file'
    refute_equal 0, File.size(dot)
  end
end

# TODO: edit
# TODO: changed_ranges
