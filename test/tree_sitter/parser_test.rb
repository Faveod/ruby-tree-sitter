# frozen_string_literal: true

require_relative '../test_helper.rb'

ruby = lang('ruby')
parser = TreeSitter::Parser.new

describe 'loading a language' do
  it 'must set/get the same language' do
    parser.language = ruby
    assert_equal ruby, parser.language
  end
end
