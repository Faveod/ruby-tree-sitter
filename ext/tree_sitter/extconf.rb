require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

$CFLAGS << " -O0"
$CFLAGS << " -std=c99"
$CFLAGS << " -fPIC"
$CFLAGS << " -Wall"

if ENV['SANITIZE']
  $CFLAGS = ' -fsanitize=address -fno-omit-frame-pointer'
  $LDFLAGS << ' -fsanitize=address -dynamic-libasan'
end

header = find_header('tree_sitter/api.h',
                     # Usual paths
                     '/opt/include',
                     '/opt/local/include',
                     '/usr/include',
                     '/usr/local/include')

library = find_library('tree-sitter',   # libtree-sitter
                       'ts_parser_new', # a symbol
                       # Usual paths
                       '/opt/lib',
                       '/opt/local/lib',
                       '/usr/lib',
                       '/usr/local/lib')

if !header || !library
  crash(<<~EOL)
    Missing header: #{header ? 'no' : 'yes'}, library: #{library ? 'no' : 'yes'}.
    Install the library or try one of the following options to extconf.rb:

      --with-tree-sitter-dir=/path/to/tree-sitter
      --with-tree-sitter-lib=/path/to/tree-sitter/lib
      --with-tree-sitter-include=/path/to/tree-sitter/include
  EOL
end

dir_config('tree-sitter')
create_header()
create_makefile('tree_sitter/tree_sitter')
