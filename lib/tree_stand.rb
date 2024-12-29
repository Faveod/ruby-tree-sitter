# frozen_string_literal: true
# typed: true

require 'forwardable'
require 'sorbet-runtime'
require 'stringio'
require 'tree_sitter'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/tree_sitter")
loader.ignore("#{__dir__}/tree_sitter.rb")
loader.ignore("#{__dir__}/tree_stand/cli")
loader.ignore("#{__dir__}/tree_stand/cli.rb")
loader.setup

# TreeStand is a high-level Ruby wrapper for {https://tree-sitter.github.io/tree-sitter tree-sitter} bindings. It makes
# it easier to configure the parsers, and work with the underlying syntax tree.
module TreeStand
  # Common Ancestor for all TreeStand errors.
  class Error < StandardError; end
  # Raised when the parsed document contains errors.
  class InvalidDocument < Error; end
  # Raised when performing a search on a tree where a return value is expected,
  # but no match is found.
  class NodeNotFound < Error; end

  class << self
    extend T::Sig

    # Easy configuration of the gem.
    #
    # @example
    #   TreeStand.configure do
    #     config.parser_path = "path/to/parser/folder/"
    #   end
    #
    #   sql_parser = TreeStand::Parser.new("sql")
    #   ruby_parser = TreeStand::Parser.new("ruby")
    sig { params(block: T.proc.void).void }
    def configure(&block)
      instance_eval(&block)
    end

    sig { returns(TreeStand::Config) }
    def config
      @config ||= Config.new
    end
  end
end
