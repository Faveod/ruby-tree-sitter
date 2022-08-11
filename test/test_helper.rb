# frozen_string_literal: true

at_exit { GC.start }

require 'minitest/autorun'
require 'minitest/color'
require 'tree_sitter'

require_relative '../examples/helpers'
