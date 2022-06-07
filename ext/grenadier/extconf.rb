require 'mkmf'

ROOT                    = File.expand_path(__dir__)
TREE_SITTER_DIR         = File.join(ROOT, '..', '..', 'vendor', 'tree-sitter')
TREE_SITTER_OUT_DIR     = TREE_SITTER_DIR
TREE_SITTER_INCLUDE_DIR = File.join(TREE_SITTER_DIR, 'lib', 'include')
# TREE_SITTER_SRC_DIR     = File.join(TREE_SITTER_DIR, 'lib', 'src')

HEADER_DIRS = [TREE_SITTER_INCLUDE_DIR]
LIB_DIRS    = [TREE_SITTER_OUT_DIR]


Dir.chdir(TREE_SITTER_DIR) do
  puts `make`
end

dir_config('grenadier', HEADER_DIRS, LIB_DIRS)
create_makefile('grenadier/grenadier')
