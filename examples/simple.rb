require 'tree_sitter'

out = 'graph.gv'

puts("loading language")
language = TreeSitter::Language.load('ruby', '/Users/firas/projects/github/tree-sitter-ruby/libtree-sitter-ruby.dylib')

puts("creating parser")
parser = TreeSitter::Parser.new

puts("setting language")
parser.language = language

puts("parsing string")
tree = parser.parse_string(nil, '1 + 2 * 3')

puts("generating graph")
tree.print_dot_graph(out)

system("open #{out}")
