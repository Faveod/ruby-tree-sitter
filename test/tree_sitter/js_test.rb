# frozen_string_literal: true

require_relative '../test_helper'

js = TreeSitter.lang('javascript')
parser = TreeSitter::Parser.new
parser.language = js

program = <<~JS
  let a = 42;
JS

describe 'loading a language' do
  before do
    parser.reset
  end

  it 'must set/get the same language' do
    parser.language = js
    assert_equal js, parser.language
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
