# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) if !$LOAD_PATH.include?(lib)

require 'tree_sitter/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.authors       = ['Firas al-Khalil', 'Derek Stride']
  spec.email         = ['firasalkhalil@gmail.com', 'derek@stride.host']
  spec.homepage      = 'https://www.github.com/Faveod/ruby-tree-sitter'
  spec.license       = 'MIT'
  spec.name          = 'ruby_tree_sitter'
  spec.summary       = 'Ruby bindings for Tree-Sitter'
  spec.version       = TreeSitter::VERSION

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => spec.homepage,
    'documentation_uri' => 'https://faveod.github.io/ruby-tree-sitter/',
  }

  spec.extensions    = %(ext/tree_sitter/extconf.rb)
  spec.files         = %w[LICENSE README.md tree_sitter.gemspec]
  spec.files        += Dir.glob('ext/**/*.{c,h,rb}')
  spec.files        += Dir.glob('lib/**/*.rb')
  spec.require_paths = ['lib']

  spec.add_dependency 'sorbet-runtime'
  spec.add_dependency 'zeitwerk'
end
