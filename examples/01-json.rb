require_relative 'helpers'

parser = TreeSitter::Parser.new
language = lang('json')

src = "[1, null]"

parser.language = language

tree = parser.parse_string(nil, src).copy
root = tree.root_node
array = root.named_child(0)
number = array.named_child(0)

assert_eq(root.type, 'document')
assert_eq(array.type, 'array')
assert_eq(number.type, 'number')

puts "Syntax tree: #{root.to_s}"
