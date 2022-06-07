# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'grenadier/version'

Gem::Specification.new do |spec|
  spec.name          = 'grenadier'
  spec.version       = Grenadier::VERSION
  spec.authors       = ['Firas al-Khalil']
  spec.email         = ['firasalkhalil@gmail.com']

  spec.summary       = 'Ruby bindings for Tree-Sitter'
  spec.homepage      = 'https://www.github.com/stackmystack/grenadier'

  spec.files         = %w(LICENSE README.md grenadier.gemspec)
  spec.files        += Dir.glob('lib/**/*.rb')
  spec.files        += Dir.glob('ext/**/*.[ch]')
  spec.test_files    = Dir.glob('test/**/*')
  spec.extensions    = %(ext/grenadier/extconf.rb)

  spec.required_ruby_version = '>= 3.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake-compiler'
end
