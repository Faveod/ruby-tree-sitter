require 'tree_sitter'

javascript = TreeSitter::Language.load('javascript', '/Users/firas/projects/github/tree-sitter-javascript/libtree-sitter-javascript.dylib')

parser = TreeSitter::Parser.new
parser.language = javascript

program = <<~JAVASCRIPT
console.log(`Hello ${1 + 2 * 3}`)
JAVASCRIPT

puts "Parsing JS program:\n\n#{program}\n\n"
tree = parser.parse_string(nil, program)
root = tree.root_node
puts "#{root}\n\n"
puts "Working with TreeCursor\n\n"
cursor = TreeSitter::TreeCursor.new(root)

pcurs = -> {
  puts ''
  puts "Current Node      : #{cursor.current_node}"
  puts "Current Field Name: #{cursor.current_field_name}"
  puts "Current Field ID  : #{cursor.current_field_id}"
  puts ''
}

pcurs[]
puts 'Move to first child.'
cursor.goto_first_child
pcurs[]

puts 'Then first child -> first child.'
cursor.goto_first_child
cursor.goto_first_child
pcurs[]

puts 'Then next sibling.'
cursor.goto_next_sibling
pcurs[]

puts 'Ok, now we reset to root node.'
cursor.reset(root)
pcurs[]
