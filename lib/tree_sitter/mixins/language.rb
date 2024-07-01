# frozen_string_literal: true

module TreeSitter
  # Mixins.
  module Mixins
    # Language Mixin.
    module Language
      # A colon-seprated list of paths pointing to directories that can contain parsers.
      # Order matters.
      # Takes precedence over default lookup paths.
      ENV_PARSERS =
        ENV['TREE_SITTER_PARSERS']
          &.split(':')
          &.map { |v| Pathname(v) }
          .freeze

      # The default paths we use to lookup parsers when no specific
      # {TreeStand::Config#parser_path} is `nil`.
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
      def lib_dirs
        [
          *ENV_PARSERS,
          *(TreeStand.config.parser_path ? [TreeStand.config.parser_path] : LIBDIRS),
        ].compact
      end

      # The platform-specific extension of the parser.
      # @return [String] `dylib` or `so` for mac or linux.
      def ext
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
      def search_for_lib(name)
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
      def language(name)
        lib = search_for_lib(name)

        if lib.nil?
          raise <<~MSG
            Failed to load a parser for #{name}.

            #{search_lib_message}
          MSG
        end

        # We know that the bindings will accept `lib`, but I don't know how to tell sorbet
        # the types in ext/tree_sitter where `load` is defined.
        TreeSitter::Language.load(name.tr('-', '_'), T.unsafe(lib))
      end
    end
  end
end
