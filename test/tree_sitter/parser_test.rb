# frozen_string_literal: true

require_relative '../test_helper.rb'

ruby = lang('ruby')
parser = TreeSitter::Parser.new

program = <<~RUBY
def mul(a, b)
  res = a* b
  puts res.inspect
  return res
end
RUBY

describe 'loading a language' do
  it 'must set/get the same language' do
    parser.language = ruby
    assert_equal ruby, parser.language
  end
end
