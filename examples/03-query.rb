require 'tree_sitter'

ruby = TreeSitter::Language.load('ruby', '/Users/firas/projects/github/tree-sitter-ruby/libtree-sitter-ruby.dylib')

parser = TreeSitter::Parser.new
parser.language = ruby

program = <<~RUBY
def mul a, b
    return a * b
end

puts mul(1, 2)
puts 1 * 2

RUBY

patterns = [
  '(binary (integer) (integer))',
  '(binary (integer) @left (integer) @right)',
]

puts "Parsing Ruby program:\n\n#{program}\n\n"
tree = parser.parse_string(nil, program)
root = tree.root_node
puts "#{root}\n\n"

patterns.each do |p|
  puts "Searching for pattern: #{p}\n"
  query = TreeSitter::Query.new(ruby, p)
  puts "pattern count: #{query.pattern_count}"
  puts "capture count: #{query.pattern_count}"
  cursor = TreeSitter::QueryCursor.exec(query, root)
  match = cursor.next_match
  puts "match: #{match}"
end
