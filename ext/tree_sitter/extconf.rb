require 'mkmf'
require 'pathname'

# ################################## #
#             Some helpers           #
# ################################## #

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

cflags = []
ldflags = []

def system_tree_sitter?
  enable_config('sys-libs', true)
end

def sh cmd
  if !system(cmd)
    abort <<~MSG

      Failed to run: #{cmd}

      exiting…

    MSG
  end
end

def env_var_on?(var)
  %w[1 on true t yes y].include?(ENV.fetch(var, '').downcase)
end

# ################################## #
#            System lib              #
#                                    #
#                OR                  #
#                                    #
#          Downloaded libs           #
# ################################## #

# This library's version is not really in semver.
#
# We append a version next to the tree-sitter's, so when fetching from sources
# we need to strip off the addition.
version = TreeSitter::VERSION.gsub(/\A(\d+\.\d+\.\d+)(\.\d+)?\z/, '\1')

dir_include, dir_lib =
  if system_tree_sitter?
    [
      %w[/opt/include /opt/local/include /usr/include /usr/local/include],
      %w[/opt/lib /opt/local/lib /usr/lib /usr/local/lib]
    ]
  else
    src = Pathname.pwd / "tree-sitter-#{version}"
    if !Dir.exist? src
      if find_executable('git')
        sh "git clone https://github.com/tree-sitter/tree-sitter #{src}"
        sh "cd #{src} && git checkout tags/v#{version}"
      elsif find_executable('curl')
        if find_executable('tar')
          sh "curl -L https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v#{version}.tar.gz -o tree-sitter-v#{version}.tar.gz"
          sh "tar -xf tree-sitter-v#{version}.tar.gz"
        elsif find_executable('zip')
          sh "curl -L https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v#{version}.zip -o tree-sitter-v#{version}.zip"
          sh "unzip -q tree-sitter-v#{version}.zip"
        else
          abort('Could not find `tar` or `zip` (and `git` was not found!)')
        end
      else
        abort('Could not find `git` or `curl` to download tree-sitter and build from sources.')
      end
    end

    # We need to make sure we're selecting the proper toolchain.
    # Especially needed for corss-compilation.
    ENV.store('CC', RbConfig::CONFIG['CC'])
    # We need to clean because the same folder is used over and over
    # by rake-compiler-dock
    sh "cd #{src} && make clean && make"

    [[src / 'lib' / 'include'], [src.to_s]]
  end

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

if env_var_on?('TREE_SITTER_PEDANTIC')
  cflags << '-Werror'
end

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
