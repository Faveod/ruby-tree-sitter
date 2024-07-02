# frozen_string_literal: true

require 'set'

require 'tree_sitter/tree_sitter'
require 'tree_sitter/version'

require 'tree_sitter/mixins/language'

require 'tree_sitter/node'
require 'tree_sitter/query'
require 'tree_sitter/query_captures'
require 'tree_sitter/query_cursor'
require 'tree_sitter/query_match'
require 'tree_sitter/query_matches'
require 'tree_sitter/query_predicate'
require 'tree_sitter/text_predicate_capture'

# TreeSitter is a Ruby interface to the tree-sitter parsing library.
module TreeSitter
  extend Mixins::Language

  class << self
    alias_method :lang, :language
  end
end

ObjectSpace.define_finalizer(TreeSitter::Tree.class, proc { TreeSitter::Tree.finalizer })
