require 'fileutils'
require 'tree_sitter'
require 'pathname'

module TreeSitter
  def self.ext
    case Gem::Platform.local.os
        in /darwin/ then 'dylib'
    else             'so'
    end
  end
  LIBDIRS = [
    ENV['TREE_SITTER_PARSERS'] ? Pathname(ENV['TREE_SITTER_PARSERS']) : nil,
    Pathname('lib'),
    Pathname('app/lib'),
    Pathname('tree-sitter-parsers'),
    Pathname('/usr/lib'),
    Pathname('/usr/local/lib'),
    Pathname('/opt/lib'),
    Pathname('/opt/local/lib'),
  ].compact.freeze

  def self.lang name, lib = nil
    symbol = name.gsub(/-/, '_')
    so     = "libtree-sitter-#{name}.#{ext}"

    # Look for an existing lib installation.
    lib ||= LIBDIRS.find { |dir|
      dylib = dir / so
      dylib = dir / name / so if !dylib.exist?
      break dylib.expand_path if dylib.exist?
    }

    # Download if we still didn't find.
    # NOTE: we only allow .so download to tree-sitter-parsers locally.
    if lib.nil?
      raise "could not load/download #{name} from #{dylib}" if system("bin/get #{name}").nil?

      lib = Pathname.new("tree-sitter-parsers/#{name}/#{so}").expand_path
    end

    raise "could not find a library with the symbol #{name}" if lib.nil?

    TreeSitter::Language.load(symbol, lib)
  end

  def assert_eq(a, b)
    puts "#{a} #{a == b ? '==' : '!='} #{b}"
  end

  def section
    puts '-' * 79
  end
end
