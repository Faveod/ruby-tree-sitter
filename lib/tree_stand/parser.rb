# frozen_string_literal: true
# typed: true

require 'pathname'

module TreeStand
  # Wrapper around the TreeSitter parser. It looks up the parser by filename in
  # the configured parsers directory.
  # @example
  #   TreeStand.configure do
  #     config.parser_path = "path/to/parser/folder/"
  #   end
  #
  #   # Looks for a parser in `path/to/parser/folder/sql.{so,dylib}`
  #   sql_parser = TreeStand::Parser.new("sql")
  #
  #   # Looks for a parser in `path/to/parser/folder/ruby.{so,dylib}`
  #   ruby_parser = TreeStand::Parser.new("ruby")
  #
  # If no {TreeStand::Config#parser_path} is setup, {TreeStand} will lookup in a
  # set of default paths.  You can always override any configuration by passing
  # the environment variable `TREE_SITTER_PARSERS` (colon-separated).
  #
  # @see language
  # @see search_for_lib
  # @see LIBDIRS
  class Parser
    extend T::Sig
    extend TreeSitter::Mixins::Language

    sig { returns(TreeSitter::Language) }
    attr_reader :ts_language

    sig { returns(TreeSitter::Parser) }
    attr_reader :ts_parser

    # @param language [String]
    sig { params(language: String).void }
    def initialize(language)
      @ts_language = Parser.language(language)
      @ts_parser = TreeSitter::Parser.new.tap do |parser|
        parser.language = @ts_language
      end
    end

    # Parse the provided document with the TreeSitter parser.
    # @param tree [TreeStand::Tree, nil] providing the old tree will allow the
    #   parser to take advantage of incremental parsing and improve performance
    #   by re-useing nodes from the old tree.
    sig { params(document: String, tree: T.nilable(TreeStand::Tree)).returns(TreeStand::Tree) }
    def parse_string(document, tree: nil)
      # @todo There's a bug with passing a non-nil tree
      ts_tree = @ts_parser.parse_string(nil, document)
      TreeStand::Tree.new(self, ts_tree, document)
    end

    # (see #parse_string)
    # @note Like {#parse_string}, except that if the tree contains any parse
    #   errors, raises an {TreeStand::InvalidDocument} error.
    #
    # @see #parse_string
    # @raise [TreeStand::InvalidDocument]
    sig { params(document: String, tree: T.nilable(TreeStand::Tree)).returns(TreeStand::Tree) }
    def parse_string!(document, tree: nil)
      tree = parse_string(document, tree: tree)
      return tree unless tree.any?(&:error?)

      raise(InvalidDocument, <<~ERROR)
        Encountered errors in the document. Check the tree for more details.
          #{tree}
      ERROR
    end
  end
end
