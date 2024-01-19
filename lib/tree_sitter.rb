# frozen_string_literal: true

# TreeSitter is a Ruby interface to the tree-sitter parsing library.
module TreeSitter
end

require 'set'

require 'tree_sitter/version'

require 'tree_sitter/tree_sitter'
require 'tree_sitter/node'

ObjectSpace.define_finalizer(TreeSitter::Tree.class, proc { TreeSitter::Tree.finalizer })
