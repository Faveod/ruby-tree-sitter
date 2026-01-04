GEM_NAME := 'tree_sitter'
LIB := 'lib'
LIB_FILE := LIB / GEM_NAME + '.rb'
VERSION_FILE := LIB / GEM_NAME / 'version.rb'
VERSION := shell("ruby -r ./" + VERSION_FILE  + " -e 'puts TreeSitter::VERSION'")
TS_PARSER_VERSION := '4.8'

default: check

[group('test')]
check: compile test lint doc-stats tc

[group('compile')]
clean:
  bundle exec rake clean
  rm -rf lib/tree_sitter/tree_sitter.{bundle,so}

[group('compile')]
compile *args:
  @just clean
  bundle exec rake compile {{ if args == '' { '' } else { '-- ' + args } }}

[group('tree-sitter')]
dl-parsers platform:
  curl -o tree-sitter-parsers.zip -L https://github.com/Faveod/tree-sitter-parsers/releases/download/v{{TS_PARSER_VERSION}}/tree-sitter-parsers-{{TS_PARSER_VERSION}}-{{platform}}.zip
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

[group('gem')]
gem-cross:
  rm -rf Gemfile.lock
  bundle exec rake gem:cross

[group('gem')]
[group('test')]
gem-cross-test:
  bin/ci-push-gems && bin/ci-test-project

[group('lint')]
lint:
  bundle exec rubocop --config .rubocop.yml

[group('lint')]
lint-fix:
  bundle exec rubocop --config .rubocop.yml -A

[group('develop')]
[group('test')]
nm:
  #!/usr/bin/env bash
  ruby_version=$(ruby -e 'print RUBY_VERSION')
  extension='so'
  if [[ "$(uname)" == 'Darwin' ]]; then
      extension='bundle'
  fi
  find ./tmp \
    -type f \
    -path "*/${ruby_version}/*" \
    -name "tree_sitter.${extension}" \
    -exec nm -gu {} \; \

[group('publish')]
publish:
  bin/publish

[group('setup')]
setup:
  @just setup-bundler
  @just setup-parsers

[group('setup')]
setup-bundler:
  bundle config set --local cache_all true
  bundle config set --local path vendor
  bundle install

[group('setup')]
[group('tree-sitter')]
setup-ts:
  #!/usr/bin/env bash
  set -euo pipefail
  version=$(sed -nE 's/^tree-sitter-version[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' parsers.toml)
  if [ -d tree-sitter ]; then
    cd tree-sitter
    git reset --hard HEAD
  else
    mkdir -p tree-sitter
    cd tree-sitter
    git init
    git remote add origin https://github.com/tree-sitter/tree-sitter
  fi
  git fetch origin --depth 1 "v${version}"
  git reset --hard FETCH_HEAD
  make
  echo "now you can:"
  echo "  $ cd tree-sitter && make install"

[group('setup')]
setup-parsers:
  bin/setup

[group('lint')]
tc:
  bundle exec srb tc

[group('test')]
test *args:
  bundle exec rake test {{ if args == '' { '' } else { '-- ' + args } }}
