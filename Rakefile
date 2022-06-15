# frozen_string_literal: true

require 'rake/testtask'

begin
  require 'rake/extensiontask'
rescue LoadError
  abort <<-error
  rake-compiler is missing; TreeSitter depends on rake-compiler to build the C wrapping code.
  Install it by running `gem i rake-compiler`
error
end

gemspec = Gem::Specification::load(File.expand_path('../tree_sitter.gemspec', __FILE__))

Gem::PackageTask.new(gemspec) do |pkg|
end

Rake::ExtensionTask.new('tree_sitter', gemspec) do |r|
  r.lib_dir = 'lib/tree_sitter'
end

task :clean do
  require 'fileutils'
  bundle = File.join(__dir__, *%w[lib tree_sitter tree_sitter.bundle])
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
  require_relative 'examples/helpers.rb'

  def reload!
    files = $LOADED_FEATURES.select { |feat| feat =~ /\/tree_sitter\// }
    files.each { |file| load file }
  end

  ARGV.clear
  Pry.start
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.libs << 'minitest/autorun' << 'minitest/color'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
  t.warning = true
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

task :default => %i[clean compile test]
