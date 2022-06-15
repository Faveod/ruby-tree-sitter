require 'fileutils'
require 'tree_sitter'

def ext
  case Gem::Platform.local.os
  in /darwin/ then 'dylib'
  else             'so'
  end
end

def lang name, dir = nil
  symbol = name.gsub(/-/, '_')
  lib = if dir then dir
        else
          parsers = "tree-sitter-parsers/#{name}"
          system("bin/get #{name}") unless File.exist?(parsers)
          File.expand_path("#{parsers}/libtree-sitter-#{name}.#{ext}", FileUtils.getwd)
        end
  TreeSitter::Language.load(symbol, lib)
end

def assert_eq(a, b)
  puts "#{a} #{a == b ? '==' : '!='} #{b}"
end

def section
    puts '-' * 79
end
