GEM_NAME := 'tree_sitter'
LIB := 'lib'
LIB_FILE := LIB / GEM_NAME + '.rb'
VERSION_FILE := LIB / GEM_NAME / 'version.rb'
VERSION := shell("ruby -r ./" + VERSION_FILE  + " -e 'puts TreeSitter::VERSION'")

EXEC := 'bundle exec'
RAKE := EXEC + ' rake'
IRB := EXEC + ' irb'
RUBY := EXEC + ' ruby'

default: test

check:
  bundle exec rake test
  bundle exec rubocop --config .rubocop.yml
  bundle exec yard

[group('compile')]
clean:
  bundle exec rake clean

[group('compile')]
compile:
  bundle exec rake clean compile

[group('doc')]
doc:
  {{EXEC}} yard

[group('doc')]
doc-stats:
  {{EXEC}} yard stats --list-undoc

[group('lint')]
lint:
  {{EXEC}} rubocop --config .rubocop.yml

[group('lint')]
lint-fix:
  {{EXEC}} rubocop --config .rubocop.yml -A

setup:
  bin/setup javascript json ruby

test *args:
  {{RAKE}} test {{ if args == '' { '' } else { '-- ' + args } }}


