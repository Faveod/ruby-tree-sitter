# frozen_string_literal: true

require 'rake/extensiontask'
require 'rake/testtask'
require 'ruby_memcheck'

# NOTE: tree-sitter does not support:
#     x64-mingw-ucrt
#     x64-mingw32
#     x86-mingw32
#
# NOTE: bundler is segfaulting on:
#     x86-linux-gnu
PLATFORMS = %w[
  aarch64-linux-gnu
  aarch64-linux-musl
  arm-linux-gnu
  arm-linux-musl
  arm64-darwin
  x86-linux-musl
  x86_64-darwin
  x86_64-linux-gnu
  x86_64-linux-musl
].freeze

# The only exception in the version scheme is ruby 3.3.5 because of an issue
# with ruby cross compilation.
#
# See https://github.com/rake-compiler/rake-compiler-dock/blob/3811c31917a9dcb9cb139c0841f420c82663ae89/History.md?plain=1#L35C117-L35C156
CROSS_RUBIES = %w[3.4.0 3.3.5 3.2.0 3.1.0 3.0.0].freeze

ENV['RUBY_CC_VERSION'] = CROSS_RUBIES.join(':') if !ENV['RUBY_CC_VERSION']

gemspec = Gem::Specification.load('tree_sitter.gemspec')

Gem::PackageTask.new(gemspec) do |task|
end

Rake::ExtensionTask.new('tree_sitter', gemspec) do |task|
  task.lib_dir = 'lib/tree_sitter'
  task.cross_compile = true
  task.cross_platform = PLATFORMS
  task.cross_config_options << '--enable-cross-build'
end

task 'gem:cross' do
  require 'rake_compiler_dock'
  PLATFORMS.each do |plat|
    RakeCompilerDock.sh <<~CMD, platform: plat
      bundle config set --local cache_all true \\
      && bundle package --all-platforms \\
      && RUBY_CC_VERSION='#{ENV.fetch('RUBY_CC_VERSION', nil)}' \\
          bundle exec rake native:#{plat} gem
    CMD
  end
end

task :clean do
  require 'fileutils'
  bundle = File.join(__dir__, *%w[lib tree_sitter tree_sitter.bundle tree_sitter.so tree_sitter.dylib])
  tmp = File.join(__dir__, 'tmp')
  [bundle, tmp].each do |f|
    if File.exist?(f)
      puts "rm #{f}"
      File.directory?(f) ? FileUtils.rm_rf(f) : FileUtils.rm(f)
    else
      puts "skipping #{f}"
    end
  end
end

task :console do
  require 'pry'
  require 'tree_sitter'
  require_relative 'examples/helpers'

  def reload!
    files = $LOADED_FEATURES.grep(%r{/tree_sitter/})
    files.each { |file| load file }
  end

  ARGV.clear
  Pry.start
end

test_config = ->(t) do
  t.libs << 'lib' << 'test'
  t.libs << 'minitest/autorun' << 'minitest/color'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
  t.warning = true
end

Rake::TestTask.new(test: :compile, &test_config)

RubyMemcheck.config(binary_name: 'tree_sitter')
namespace :test do
  RubyMemcheck::TestTask.new(valgrind: :compile, &test_config)
end

begin
  require 'rdoc/task'
  Rake::RDocTask.new('doc') do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.rdoc_files.include('ext/**/*.c')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError
  puts 'Could not load rdoc/task'
end

task default: %i[clean compile test]
