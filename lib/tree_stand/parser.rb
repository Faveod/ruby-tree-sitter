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

    sig { returns(TreeSitter::Language) }
    attr_reader :ts_language

    sig { returns(TreeSitter::Parser) }
    attr_reader :ts_parser

    # A colon-seprated list of paths pointing to directories that can contain parsers.
    # Order matters.
    # Takes precedence over default lookup paths.
    ENV_PARSERS =
      ENV['TREE_SITTER_PARSERS']
        &.split(':')
        &.map { |v| Pathname(v) }
        .freeze

    # The default paths we use to lookup parsers when no specific
    # {TreeStand::Config#parser_path} is {nil}.
    # Order matters.
    LIBDIRS = [
      'tree-sitter-parsers',
      '/opt/local/lib',
      '/opt/lib',
      '/usr/local/lib',
      '/usr/lib',
    ].map { |p| Pathname(p) }.freeze

    # The library directories we need to look into.
    #
    # @return [Array<Pathname>] the list of candidate places to use when searching for parsers.
    #
    # @see ENV_PARSERS
    # @see LIBDIRS
    sig { returns(T::Array[Pathname]) }
    def self.lib_dirs = [
      *ENV_PARSERS,
      *(TreeStand.config.parser_path ? [TreeStand.config.parser_path] : LIBDIRS),
    ].compact

    # The platform-specific extension of the parser.
    # @return [String] `dylib` or `so` for mac or linux.
    sig { returns(String) }
    def self.ext
      case Gem::Platform.local.os
      in   /darwin/ then 'dylib'
      else               'so'
      end
    end

    # Lookup a parser by name.
    #
    # Precedence:
    # 1. `Env['TREE_SITTER_PARSERS]`
    # 2. {TreeStand::Config#parser_path}
    # 3. {LIBDIRS}
    #
    # If a {TreeStand::Config#parser_path} is `nil`, {LIBDIRS} is used.
    # If a {TreeStand::Config#parser_path} is a {::Pathname}, {LIBDIRS} is ignored.
    sig { params(name: String).returns(T.nilable(Pathname)) }
    def self.search_for_lib(name)
      files = [
        name,
        "tree-sitter-#{name}",
        "libtree-sitter-#{name}",
      ].map { |v| "#{v}.#{ext}" }

      res = lib_dirs
        .product(files)
        .find do |dir, so|
          path = dir / so
          path = dir / name / so if !path.exist?
          break path.expand_path if path.exist?
        end
      res.is_a?(Array) ? nil : res
    end

    # Generates a string message on where parser lookup happens.
    #
    # @return [String] A pretty message.
    sig { returns(String) }
    def self.search_lib_message
      indent = 2
      pretty = ->(arr) {
        if arr
          arr
            .compact
            .map { |v| "#{' ' * indent}#{v.expand_path}" }
            .join("\n")
        end
      }
      <<~MSG
        From ENV['TREE_SITTER_PARSERS']:
        #{pretty.call(ENV_PARSERS)}

        From TreeStand.config.parser_path:
        #{pretty.call([TreeStand.config.parser_path])}

        From Defaults:
        #{pretty.call(LIBDIRS)}
      MSG
    end

    # Load a language from configuration or default lookup paths.
    #
    # @example Load java from default paths
    #    # This will look for:
    #    #
    #    #   tree-sitter-parsers/(java/)?(libtree-sitter-)?java.{ext}
    #    #   /opt/local/lib/(java/)?(libtree-sitter-)?java.{ext}
    #    #   /opt/lib/(java/)?(libtree-sitter-)?java.{ext}
    #    #   /usr/local/lib/(java/)?(libtree-sitter-)?java.{ext}
    #    #   /usr/lib/(java/)?(libtree-sitter-)?java.{ext}
    #    #
    #    java = TreeStand::Parser.language('java')
    #
    # @example Load java from a configured path
    #    # This will look for:
    #    #
    #    #   /my/path/(java/)?(libtree-sitter-)?java.{ext}
    #    #
    #    TreeStand.config.parser_path = '/my/path'
    #    java = TreeStand::Parser.language('java')
    #
    # @example Load java from environment variables
    #    # This will look for:
    #    #
    #    #   /my/forced/env/path/(java/)?(libtree-sitter-)?java.{ext}
    #    #   /my/path/(java/)?(libtree-sitter-)?java.{ext}
    #    #
    #    # … and the same works for the default paths if `TreeStand.config.parser_path`
    #    # was `nil`
    #    ENV['TREE_SITTER_PARSERS'] = '/my/forced/env/path'
    #    TreeStand.config.parser_path = '/my/path'
    #    java = TreeStand::Parser.language('java')
    #
    # @param name [String] the name of the parser.
    #   This name is used to load the symbol from the compiled parser, replacing `-` with `_`.
    # @return [TreeSitter:language] a language object to use in your parsers.
    # @raise [RuntimeError] if the parser was not found.
    # @see search_for_lib
    sig { params(name: String).returns(TreeSitter::Language) }
    def self.language(name)
      lib = search_for_lib(name)

      if lib.nil?
        raise <<~MSG
          Failed to load a parser for #{name}.

          #{search_lib_message}
        MSG
      end

      # We know that the bindings will accept `lib`, but I don't know how to tell sorbet
      # the types in ext/tree_sitter where `load` is defined.
      TreeSitter::Language.load(name.gsub(/-/, '_'), T.unsafe(lib))
    end

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
