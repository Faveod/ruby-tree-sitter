# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/color'
require 'tree_sitter'

require_relative '../examples/helpers'

at_exit { GC.start }
