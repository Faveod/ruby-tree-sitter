# frozen_string_literal: true

require 'rake/extensiontask'
require 'rake/testtask'
require 'ruby_memcheck'

# FIXME: ld: unknown -soname
# that's a bug in tree-sitter's makefile: it only checks for OS type and
# not compiler type, so when we're cross-building it blows in our face
#     x86_64-darwin
#     arm64-darwin
# However, these don't work at all with tree-sitter:
#     x64-mingw-ucrt
#     x64-mingw32
#     x86-mingw32
# And here, bundler is segfaulting
#     x86-linux-gnu
#     x86-linux-musl
#
PLATFORMS = %w[
  aarch64-linux-gnu
  aarch64-linux-musl
  arm-linux-gnu
  arm-linux-musl
  x86_64-linux-gnu
  x86_64-linux-musl
].freeze

CROSS_RUBIES = %w[3.3.0 3.2.0 3.1.0 3.0.0].freeze

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

task 'gem:native' do
  require 'rake_compiler_dock'
  sh 'bundle package --all' # Avoid repeated downloads of gems by using gem files from the host.
  PLATFORMS.each do |plat|
    RakeCompilerDock.sh <<~CMD, platform: plat
      bundle --local && \\
        RUBY_CC_VERSION='#{ENV.fetch('RUBY_CC_VERSION', nil)}' \\
          bundle exec rake native:#{plat} gem -- --disable-sys-libs
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
