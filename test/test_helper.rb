# frozen_string_literal: true

at_exit { GC.start }

require 'bundler/setup'
require 'tree_sitter'
require 'tree_stand'
require 'debug'
require 'minitest/autorun'
require 'minitest/focus'
require 'minitest/reporters'

require_relative '../examples/helpers'

Minitest::Reporters.use!

TreeStand.configure do
  config.parser_path = File.expand_path(
    File.join(__dir__, '..', 'tree-sitter-parsers'),
  )
end
