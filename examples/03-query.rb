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
  '(method name: (identifier) @name) @definition.function'
]

puts "Parsing Ruby program:\n\n#{program}\n\n"
tree = parser.parse_string(nil, program)
root = tree.root_node
puts "#{root}\n\n"

patterns.each do |p|
  puts "Searching for pattern: #{p}\n"
  query = TreeSitter::Query.new(ruby, p)
  puts "query: pattern count: #{query.pattern_count}"

  # Iterate over all the matches in the order they were found
  cursor = TreeSitter::QueryCursor.exec(query, root)
  puts '  matches:'
  while match = cursor.next_match
    puts "    #{match.capture_count} matched"
    puts '    ['
    puts match.captures.map { |c| "      #{c}" }.join("\n")
    puts '    ]'
  end

  # # Iterate over all the captures
  cursor = TreeSitter::QueryCursor.exec(query, root)
  puts '  captures:'
  while cap = cursor.next_capture
    idx, match = cap
    puts "    #{match.capture_count} captured @#{idx}"
    puts '    ['
    puts match.captures.map { |c| "      #{c}" }.join("\n")
    puts '    ]'
  end
  puts ''
end
