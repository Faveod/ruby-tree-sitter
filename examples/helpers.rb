require 'fileutils'
require 'tree_sitter'
require 'pathname'

module TreeSitter
  def assert_eq(a, b)
    puts "#{a} #{a == b ? '==' : '!='} #{b}"
  end

  def section
    puts '-' * 79
  end
end
