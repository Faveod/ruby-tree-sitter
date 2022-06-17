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
    dylib = Pathname('tree-sitter-parsers') / name / "libtree-sitter-#{name}.#{ext}"
    if !dylib.exist? && system("bin/get #{name}").nil?
      raise "could not load #{name} from #{dylib}"
    end

    lib = File.expand_path(dylib, FileUtils.getwd)
  end
  TreeSitter::Language.load(symbol, lib)
end

def assert_eq(a, b)
  puts "#{a} #{a == b ? '==' : '!='} #{b}"
end

def section
  puts '-' * 79
end
