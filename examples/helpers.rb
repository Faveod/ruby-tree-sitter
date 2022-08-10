require 'fileutils'
require 'tree_sitter'

def ext
  case Gem::Platform.local.os
  in /darwin/ then 'dylib'
  else             'so'
  end
end

def self.lang name, lib = nil
  symbol = name.gsub(/-/, '_')
  if lib.nil?
    if root = ENV.fetch('TREE_SITTER_PARSERS', nil)
      dylib = Pathname(root) / "libtree-sitter-#{name}.#{ext}"
    else
      dylib = Pathname('tree-sitter-parsers') / name / "libtree-sitter-#{name}.#{ext}"
      if !dylib.exist? && system("bin/get #{name}").nil?
        raise "could not load #{name} from #{dylib}"
      end
    end
    lib = dylib.expand_path
  end

  TreeSitter::Language.load(symbol, lib)
end

def assert_eq(a, b)
  puts "#{a} #{a == b ? '==' : '!='} #{b}"
end

def section
  puts '-' * 79
end
