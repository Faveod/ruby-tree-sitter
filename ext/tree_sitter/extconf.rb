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
  enable_config('sys-libs', false)
end

def env_var_on?(var)
  %w[1 on true t yes y].include?(ENV.fetch(var, '').downcase)
end

# ################################## #
#    System lib vs Downloaded lib    #
# ################################## #

repo = TreeSitter::Repo.new

dir_include, dir_lib =
  if system_tree_sitter?
    [
      %w[/opt/include /opt/local/include /usr/include /usr/local/include],
      %w[/opt/lib /opt/local/lib /usr/lib /usr/local/lib],
    ]
  else
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
    repo.include_and_lib_dirs
  end

dir_config('tree-sitter', dir_include&.first, dir_lib&.first)

# ################################## #
#          Generate Makefile         #
# ################################## #

header = find_header('tree_sitter/api.h')
library = find_library('tree-sitter', 'ts_parser_new')

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

  cflags.push(*
    %W[
      -fms-extensions
      -fdeclspec
      -fsanitize=#{sanitizers}
      -fsanitize-blacklist=../../../../.asanignore
      -fsanitize-recover=#{sanitizers}
      -fno-sanitize-recover=all
      -fno-sanitize=null
      -fno-sanitize=alignment
      -fno-omit-frame-pointer
    ])

  ldflags.push(*
    %W[
      -fsanitize=#{sanitizers}
      -dynamic-libasan
    ])
end

cflags.push(*%w[-std=c99 -fPIC -Wall])

append_cflags(cflags)
append_ldflags(ldflags)

create_header
create_makefile('tree_sitter/tree_sitter')
