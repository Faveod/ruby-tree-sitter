# frozen_string_literal: true

require 'rake/testtask'

begin
  require 'rake/extensiontask'
rescue LoadError
  abort <<-error
  rake-compiler is missing; Grenadier depends on rake-compiler to build the C wrapping code.
  Install it by running `gem i rake-compiler`
error
end

gemspec = Gem::Specification::load(File.expand_path('../grenadier.gemspec', __FILE__))

Gem::PackageTask.new(gemspec) do |pkg|
end

Rake::ExtensionTask.new('grenadier', gemspec) do |r|
  r.lib_dir = 'lib/grenadier'
end

desc "checkout treesitter source"
task :checkout do
  if !ENV['CI_BUILD']
    sh "git submodule update --init"
  end
end
# Rake::Task[:compile].prerequisites.insert(0, :checkout)

namespace :clean do
  task :treesitter do
    puts `make clean`
  end
end
Rake::Task[:clean].prerequisites << "clean:treesitter"

task :console do
  require 'pry'
  require 'grenadier'

  def reload!
    files = $LOADED_FEATURES.select { |feat| feat =~ /\/grenadier\// }
    files.each { |file| load file }
  end

  ARGV.clear
  Pry.start
end

task :default => [:compile, :test]
