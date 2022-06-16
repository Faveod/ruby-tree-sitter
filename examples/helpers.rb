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
          dylib = "#{parsers}/libtree-sitter-#{name}.#{ext}"
          if !File.exist?(dylib)
            if system("bin/get #{name}").nil?
              raise "could not load #{name} from #{dylib}"
            end
          end
          File.expand_path(dylib, FileUtils.getwd)
        end
  TreeSitter::Language.load(symbol, lib)
end

def assert_eq(a, b)
  puts "#{a} #{a == b ? '==' : '!='} #{b}"
end

def section
    puts '-' * 79
end
