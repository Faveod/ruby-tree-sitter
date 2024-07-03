GEM_NAME := 'tree_sitter'
LIB := 'lib'
LIB_FILE := LIB / GEM_NAME + '.rb'
VERSION_FILE := LIB / GEM_NAME / 'version.rb'
VERSION := shell("ruby -r ./" + VERSION_FILE  + " -e 'puts TreeSitter::VERSION'")

default: check

[group('test')]
check: test lint doc-stats tc

[group('compile')]
clean:
  bundle exec rake clean

[group('compile')]
compile:
  bundle exec rake clean compile

[group('compile')]
compile-no-sys:
  bundle exec rake clean compile -- --disable-sys-libs

[group('tree-sitter')]
dl-parsers platform:
  curl -o tree-sitter-parsers.zip -L https://github.com/Faveod/tree-sitter-parsers/releases/download/v3.4/tree-sitter-parsers-3.3-{{platform}}.zip
  unzip tree-sitter-parsers.zip

[group('doc')]
doc:
  bundle exec yard

[group('doc')]
doc-stats:
  bundle exec yard stats --list-undoc

[group('gem')]
gem:
  bundle exec rake gem

[group('gem')]
gem-native:
  bundle exec rake native gem

[group('lint')]
lint:
  bundle exec rubocop --config .rubocop.yml

[group('lint')]
lint-fix:
  bundle exec rubocop --config .rubocop.yml -A

[group('setup')]
setup:
  @just setup-bundler
  @just setup-parsers javascript json ruby

[group('setup')]
setup-bundler:
  bundle config set --local path vendor
  bundle install

[group('setup')]
setup-parsers *parsers:
  bin/setup {{parsers}}

[group('lint')]
tc:
  bundle exec srb tc

[group('test')]
test *args:
  bundle exec rake test {{ if args == '' { '' } else { '-- ' + args } }}

[group('tree-sitter')]
setup-ts:
  #!/usr/bin/env bash
  set -euxo pipefail
  if [ -d tree-sitter ]; then
    cd tree-sitter
    git reset --hard HEAD
  else
    mkdir -p tree-sitter
    cd tree-sitter
    git init
    git remote add origin https://github.com/tree-sitter/tree-sitter
  fi
  git fetch origin --depth 1 v0.22.6
  git reset --hard FETCH_HEAD
  make
  sudo make install
  sudo rm /usr/local/lib/libtree-sitter.a

