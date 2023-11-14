# frozen_string_literal: true

require 'mkmf'
require 'pathname'

require_relative 'repo'

# ################################## #
#             Some helpers           #
# ################################## #

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

cflags = []
ldflags = []

def system_tree_sitter?
  enable_config('sys-libs', true)
end

def env_var_on?(var)
  %w[1 on true t yes y].include?(ENV.fetch(var, '').downcase)
end

# ################################## #
#    System lib vs Downloaded lib    #
# ################################## #

dir_include, dir_lib =
  if system_tree_sitter?
    [
      %w[/opt/include /opt/local/include /usr/include /usr/local/include],
      %w[/opt/lib /opt/local/lib /usr/lib /usr/local/lib]
    ]
  else
    repo = TreeSitter::Repo.new
    if !repo.download
      msg = <<~MSG

        Could not fetch tree-sitter sources:

        #{repo.exe.map { |k, v| "#{k}: #{v}" }.join("\n")}

      MSG
      abort(msg)
    end

    # We need to make sure we're selecting the proper toolchain.
    # Especially needed for corss-compilation.
    ENV.store('CC', RbConfig::CONFIG['CC'])
    repo.compile
    repo.keep_static_lib
    repo.include_and_lib_dirs
  end

# TREESITTER_SPEC = Bundler.load_gemspec('../../../../tree_sitter.gemspec')

# # def version = TREESITTER_SPEC.version.gsub(/\A(\d+\.\d+\.\d+)(\.\d+)?\z/, '\1')

# def version = '0.20.8'

# LINUX_PLATFORM_REGEX = /linux/
# DARWIN_PLATFORM_REGEX = /darwin/

# def platform = RUBY_PLATFORM

# def darwin?
#   !!(platform =~ DARWIN_PLATFORM_REGEX)
# end

# def dll_ext
#   darwin? ? 'dylib' : 'so'
# end

# def staging_path
#   '../../stage/lib/tree_sitter'
# end

# def downloaded_dll_path
#   "tree-sitter-#{version}"
# end

# def add_tree_sitter_dll_to_gem
#   puts ">>>>>>>>>>>>> #{`pwd`}"
#   path = "#{downloaded_dll_path}/libtree-sitter*.#{dll_ext}"
#   files =
#     Dir.glob(path)
#        .map { |f| Pathname(f) }
#        .filter { |f| !f.symlink? && f.file? }
#   dll = files.first
#   dst = Pathname(staging_path) / "libtree-sitter.#{dll_ext}"
#   FileUtils.cp(dll, dst)
#   TREESITTER_SPEC.files << dst
# end

# add_tree_sitter_dll_to_gem

# ################################## #
#          Generate Makefile         #
# ################################## #

header = find_header('tree_sitter/api.h', *dir_include)
library = find_library('tree-sitter',   # libtree-sitter
                       'ts_parser_new', # a symbol
                       *dir_lib)

if !header || !library
  abort <<~MSG

    * Missing header         : #{header ? 'no' : 'yes'}
    * Missing lib            : #{library ? 'no' : 'yes'}
    * Use system tree-sitter : #{system_tree_sitter?}

    Try to install tree-sitter from source, or through your package manager,
    or even try one of the following options to extconf.rb/rake compile:

      --with-tree-sitter-dir=/path/to/tree-sitter
      --with-tree-sitter-lib=/path/to/tree-sitter/lib
      --with-tree-sitter-include=/path/to/tree-sitter/include

  MSG
end

cflags << '-Werror' if env_var_on?('TREE_SITTER_PEDANTIC')

if env_var_on?('DEBUG')
  cflags << '-fbounds-check'
  CONFIG['optflags'].gsub!(/-O\d/, '-O0')
else
  cflags << '-DNDEBUG'
  CONFIG['optflags'].gsub!(/-O\d/, '-O3')
end

sanitizers = ENV.fetch('SANITIZE', nil)

if sanitizers =~ /memory/
  puts <<~MSG

    We do not support memory sanitizers as of yet.
    It requires building ruby with the same sanitizer, and maybe its dependencies.

    exiting…

  MSG
  exit 1
end

if sanitizers
  # NOTE: when sanitizing, the default generated warning flags emit a lot of …
  # warnings.
  #
  # I couldn't make mkmf understand it's running with clang and not gcc, so
  # I'm omitting the warning generating warnings.
  #
  # It should be harmless, since sanitization is meant for CI and dev builds.
  %w[
    -Wduplicated-cond
    -Wimplicit-fallthrough=\d+
    -Wno-cast-function-type
    -Wno-packed-bitfield-compat
    -Wsuggest-attribute=\w+
  ].each do |r|
    $warnflags.gsub!(/#{r}/, '')
  end

  cflags.concat %W[
    -fms-extensions
    -fdeclspec
    -fsanitize=#{sanitizers}
    -fsanitize-blacklist=../../../../.asanignore
    -fsanitize-recover=#{sanitizers}
    -fno-sanitize-recover=all
    -fno-sanitize=null
    -fno-sanitize=alignment
    -fno-omit-frame-pointer
  ]

  ldflags.concat %W[
    -fsanitize=#{sanitizers}
    -dynamic-libasan
  ]
end

cflags.concat %w[-std=c99 -fPIC -Wall]

append_cflags(cflags)
append_ldflags(ldflags)

dir_config('tree-sitter')
create_header
create_makefile('tree_sitter/tree_sitter')
