require_relative 'helpers'

template = lang('embedded-template')
html = lang('html')
ruby = lang('ruby')

program = <<~ERB
<ul>
  <% people.each do |person| %>
    <li><%= person.name %></li>
  <% end %>
</ul>
ERB

puts "Parsing:\n\n#{program}\n"

parser = TreeSitter::Parser.new

puts 'First we parse ERB'
parser.language = template
tree_erb = parser.parse_string(nil, program)
root_erb = tree_erb.root_node

puts "\n#{root_erb}\n"

# In the ERB syntax tree, find the ranges of the `content` nodes,
# which represent the underlying HTML, and the `code` nodes, which
# represent the interpolated Ruby.

puts "\nExtracting HTML/Ruby ranges ..."

ranges_html = []
ranges_ruby = []

(0...root_erb.child_count).each do |i|
  node = root_erb.child(i)
  range = TreeSitter::Range.new
  range.start_point = node.start_point
  range.end_point = node.end_point
  range.start_byte = node.start_byte
  range.end_byte = node.end_byte
  if node.type == 'content'
    ranges_html << range
  else
    ranges_ruby << range
  end
end

puts "HTML:\n#{ranges_html}\nRuby:\n#{ranges_ruby}\n\n"

puts "Parsing HTML ..."
parser.language = html
parser.included_ranges = ranges_html
tree_html = parser.parse_string(nil, program)
root_html = tree_html.root_node

puts "\n\n#{root_html}\n\n"

puts "Parsing Ruby ..."
parser.language = ruby
parser.included_ranges = ranges_ruby
tree_ruby = parser.parse_string(nil, program)
root_ruby = tree_ruby.root_node

puts "\n\n#{root_ruby}\n\n"
