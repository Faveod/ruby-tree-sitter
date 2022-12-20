# frozen_string_literal: true

require 'rake/testtask'

begin
  require 'rake/extensiontask'
rescue LoadError
  abort <<-ERROR
  rake-compiler is missing; TreeSitter depends on rake-compiler to build the C wrapping code.
  Install it by running `gem i rake-compiler`
  ERROR
end

require "ruby_memcheck"

gemspec = Gem::Specification.load('tree_sitter.gemspec')

cross_rubies = [
  '3.1.0',
  '3.0.0',
  '2.7.0',
].freeze

cross_platforms = [
  'x64-mingw32',
  'x64-mingw-ucrt',
  'x86-linux',
  'x86_64-linux',
  'aarch64-linux',
  #
  # FIXME: ld: unknown -soname
  # that's a bug in tree-sitter's makefile: it only checks for OS type and
  # not compiler type, so when we're cross-building it blows in out face
  #
  'x86_64-darwin',
  'arm64-darwin',
].freeze

ENV['RUBY_CC_VERSION'] = cross_rubies.join(':') if !ENV['RUBY_CC_VERSION']
Rake::ExtensionTask.new('tree_sitter', gemspec) do |r|
  r.lib_dir = 'lib/tree_sitter'
    require "rake_compiler_dock"
    r.cross_compile = true
    r.cross_platform = cross_platforms
    r.cross_compiling do |spec|
      spec.files.reject! { |file| /(\.gz)$|(\.zip)$|(\.tar)$/ =~ File.basename(file) }
    end

    r.config_options << "--disable-sys-libs" if ENV["DISABLE_SYS_LIBS"]
end

Gem::PackageTask.new(gemspec) do |pkg|
end

desc 'Build native gems'
task 'gem:native' do
  cross_platforms.each do |plat|
    RakeCompilerDock.sh "gem update --system --no-document && bundle && bundle exec rake clean && bundle exec rake native:#{plat} gem", platform: plat
  end
end

cross_platforms.each do |plat|
  task "gem:#{plat}" do
    RakeCompilerDock.sh "gem update --system --no-document && bundle && bundle exec rake clean && bundle exec rake native:#{plat} gem", platform: plat
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
    files = $LOADED_FEATURES.select { |feat| feat =~ %r{/tree_sitter/} }
    files.each { |file| load file }
  end

  ARGV.clear
  Pry.start
end

test_config = lambda do |t|
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
