# frozen_string_literal: true

require 'pathname'
require 'tree_sitter'

def darwin?
  !!(`uname -s`.strip =~ /darwin/i)
end

def ext
  darwin? ? 'dylib' : 'so'
end

parser = TreeSitter::Parser.new
language = TreeSitter::Language.load(
  'ruby',
  Pathname(ENV['TREE_SITTER_PARSERS']) / "libtree-sitter-ruby.#{ext}"
)
parser.language = language
src = "puts 'x = 42'"
tree = parser.parse_string(nil, src)

puts tree.root_node
