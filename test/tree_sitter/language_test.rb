# frozen_string_literal: true

require_relative '../test_helper.rb'

ruby = lang('ruby')
parser = TreeSitter::Parser.new
parser.language = ruby

describe 'language' do
  it 'must return symbol count' do
    assert ruby.symbol_count.positive?
  end
end
