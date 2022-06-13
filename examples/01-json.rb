require 'tree_sitter'

def assert_eq(a, b)
  puts "#{a} #{a == b ? '==' : '!='} #{b}"
end

parser = TreeSitter::Parser.new
language = TreeSitter::Language.load('json', '/Users/firas/projects/github/tree-sitter-json/libtree-sitter-json.dylib')

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

tree.delete # we have to do this because it's a quirky one
            # parser on the other hand gets freed automatically
