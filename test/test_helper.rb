# frozen_string_literal: true

at_exit { GC.start }

require 'bundler/setup'
require 'tree_sitter'
require 'tree_stand'
# require 'debug'
require 'minitest/autorun'
require 'minitest/focus'
require 'minitest/reporters'

require_relative '../examples/helpers'

Minitest::Reporters.use!

PARSERS_INSTALL_PATH = (Pathname('vendor') / 'parsers').freeze

TreeStand.configure do
  config.parser_path = PARSERS_INSTALL_PATH.expand_path
end
