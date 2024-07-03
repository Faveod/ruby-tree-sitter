# frozen_string_literal: true

module TreeSitter
  # A colon-separated list of paths pointing to directories that can contain parsers.
  # Order matters.
  # Takes precedence over default lookup paths.
  ENV_PARSERS =
    ENV['TREE_SITTER_PARSERS']
      &.split(':')
      &.map { |v| Pathname(v) }
      .freeze

  # The default paths we use to lookup parsers.
  # Order matters.
  LIBDIRS = [
    '.vendor/parsers',
    '.vendor/tree-sitter-parsers',
    'vendor/parsers',
    'vendor/tree-sitter-parsers',
    'parsers',
    'tree-sitter-parsers',
    '/opt/local/lib',
    '/opt/lib',
    '/usr/local/lib',
    '/usr/lib',
  ].map { |p| Pathname(p) }.freeze

  # Mixins.
  module Mixins
    # Language Mixin.
    module Language
      # Load a language from configuration or default lookup paths.
      #
      # @example Load java from default paths
      #    # This will look for:
      #    #
      #    #   .vendor/tree-sitter-parsers/(java/)?(libtree-sitter-)?java.{ext}
      #    #   .vendor/parsers/(java/)?(libtree-sitter-)?java.{ext}
      #    #   vendor/tree-sitter-parsers/(java/)?(libtree-sitter-)?java.{ext}
      #    #   vendor/parsers/(java/)?(libtree-sitter-)?java.{ext}
      #    #   parsers/(java/)?(libtree-sitter-)?java.{ext}
      #    #   tree-sitter-parsers/(java/)?(libtree-sitter-)?java.{ext}
      #    #   /opt/local/lib/(java/)?(libtree-sitter-)?java.{ext}
      #    #   /opt/lib/(java/)?(libtree-sitter-)?java.{ext}
      #    #   /usr/local/lib/(java/)?(libtree-sitter-)?java.{ext}
      #    #   /usr/lib/(java/)?(libtree-sitter-)?java.{ext}
      #    #
      #    java = TreeSitter.language('java')
      #
      # @example (TreeStand) Load java from a configured path
      #    # This will look for:
      #    #
      #    #   /my/path/(java/)?(libtree-sitter-)?java.{ext}
      #    #
      #    TreeStand.config.parser_path = '/my/path'
      #    java = TreeStand::Parser.language('java')
      #
      # @example (TreeStand) Load java from environment variables
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
      #
      # @return [TreeSitter:language] a language object to use in your parsers.
      #
      # @raise [RuntimeError] if the parser was not found.
      #
      # @see search_for_lib
      def language(name)
        lib = search_for_lib(name)

        if lib.nil?
          raise <<~MSG.chomp
            Failed to load a parser for #{name}.

            #{search_lib_message}
          MSG
        end

        # We know that the bindings will accept `lib`, but I don't know how to tell sorbet
        # the types in ext/tree_sitter where `load` is defined.
        TreeSitter::Language.load(name.tr('-', '_'), lib)
      end

      # The platform-specific extension of the parser.
      # @return [String] `dylib` or `so` for mac or linux.
      def ext
        case Gem::Platform.local.os
        in   /darwin/ then 'dylib'
        else               'so'
        end
      end

      private

      # The library directories we need to look into.
      #
      # @return [Array<Pathname>] the list of candidate places to use when searching for parsers.
      #
      # @see ENV_PARSERS
      # @see LIBDIRS
      def lib_dirs = [*TreeSitter::ENV_PARSERS, *TreeSitter::LIBDIRS]

      # Lookup a parser by name.
      #
      # Precedence:
      # 1. `Env['TREE_SITTER_PARSERS]`.
      # 2. {TreeStand::Config#parser_path} if using {TreeStand}.
      # 3. {LIBDIRS}.
      #
      # If a {TreeStand::Config#parser_path} is `nil`, {LIBDIRS} is used.
      # If a {TreeStand::Config#parser_path} is a {::Pathname}, {LIBDIRS} is ignored.
      def search_for_lib(name)
        files = [
          name,
          "tree-sitter-#{name}",
          "libtree-sitter-#{name}",
        ].map { |v| "#{v}.#{ext}" }

        lib_dirs
          .product(files)
          .find do |dir, so|
            path = dir / so
            path = dir / name / so if !path.exist?
            break path.expand_path if path.exist?
          end
      end

      # Generates a string message on where parser lookup happens.
      #
      # @return [String] A pretty message.
      def search_lib_message
        indent = 2
        pretty = ->(arr) {
          if arr
            arr
              .compact
              .map { |v| "#{' ' * indent}#{v.expand_path}" }
              .join("\n")
          end
        }
        <<~MSG.chomp
          From ENV['TREE_SITTER_PARSERS']:
          #{pretty.call(ENV_PARSERS)}

          From Defaults:
          #{pretty.call(lib_dirs)}
        MSG
      end
    end
  end
end
