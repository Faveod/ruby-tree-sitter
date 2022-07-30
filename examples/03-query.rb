require_relative 'helpers'

ruby = TreeSitter.lang('ruby')

parser = TreeSitter::Parser.new
parser.language = ruby

program = <<~RUBY
  def mul a, b
      return a * b
  end

  puts mul(1, 2)
  puts 1 * 2

  never_gonna = [1, 2]
  give_you_up = [3, 4]

  let_you_down = never_gonna + give_you_up

RUBY

patterns = [
  # '(binary (_) @left (_) @right)',
  # '(binary (_) (_))',
  # '(binary (integer) @left (integer) @right)',
  '(method name: (identifier) @name) @definition.function'
]

puts "Parsing Ruby program:\n\n#{program}\n\n"
tree = parser.parse_string(nil, program)
root = tree.root_node
puts "#{root}\n\n"
section

patterns.each do |p|
  puts "Searching for pattern: #{p}\n"
  query = TreeSitter::Query.new(ruby, p)
  puts "query: pattern count: #{query.pattern_count}"

  # Iterate over all the matches in the order they were found
  cursor = TreeSitter::QueryCursor.exec(query, root)
  puts '  matches:'
  while match = cursor.next_match
    puts "    #{match.capture_count} captured"
    puts '    ['
    puts match.captures.map { |c| "      #{c}" }.join("\n")
    puts '    ]'
  end

  # # Iterate over all the captures
  cursor = TreeSitter::QueryCursor.exec(query, root)
  puts '  captures:'
  while cap = cursor.next_capture
    idx, match = cap
    quantifier = TreeSitter.quantifier_name(query.capture_quantifier_for_id(0, idx))
    puts "    @#{idx} -> #{quantifier} -> #{query.capture_name_for_id(idx)}"
  end
  puts ''
  puts section
end
