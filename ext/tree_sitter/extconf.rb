require 'mkmf'
require 'pathname'

# ################################## #
#             Some helpers           #
# ################################## #

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

def system_tree_sitter?
  enable_config('sys-libs', true)
end

def sh cmd
  if !system(cmd)
    abort "Aborting.\nFailed to run:\n    #{cmd}\n"
  end
end

# ################################## #
#            System lib              #
#                                    #
#                OR                  #
#                                    #
#          Downloaded libs           #
# ################################## #

dir_include, dir_lib =
  if system_tree_sitter?
    [['/opt/include', '/opt/local/include', '/usr/include', '/usr/local/include'],
     ['/opt/lib', '/opt/local/lib', '/usr/lib', '/usr/local/lib']]
  else
    src = Pathname.pwd / "tree-sitter-#{TreeSitter::VERSION}"
    if !Dir.exists? src
      if find_executable('git')
        sh "git clone https://github.com/tree-sitter/tree-sitter #{src}"
        sh "cd #{src} && git checkout tags/v#{TreeSitter::VERSION}"
      elsif find_executable('curl')
        if find_executable('tar')
          sh "curl -L https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v#{TreeSitter::VERSION}.tar.gz -o tree-sitter-v#{TreeSitter::VERSION}.tar.gz"
          sh "tar -xf tree-sitter-v#{TreeSitter::VERSION}.tar.gz"
        elsif find_executable('zip')
          sh "curl -L https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v#{TreeSitter::VERSION}.zip -o tree-sitter-v#{TreeSitter::VERSION}.zip"
          sh "unzip -q tree-sitter-v#{TreeSitter::VERSION}.zip"
        else
          abort('Could not find `tar` or `zip` (and `git` was not found!)')
        end
      else
        abort('Could not find `git` or `curl` to download tree-sitter and build from sources.')
      end
    end

    # We need to make sure we're selecting the proper toolchain.
    # Especially needed for corss-compilation.
    ENV['CC'] = RbConfig::CONFIG["CC"]
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
  abort <<~EOL

    * Missing header         : #{header ? 'no' : 'yes'}
    * Missing lib            : #{library ? 'no' : 'yes'}
    * Use system tree-sitter : #{system_tree_sitter?}

    Try to install tree-sitter from source, or through your package manager,
    or even try one of the following options to extconf.rb/rake compile:

      --with-tree-sitter-dir=/path/to/tree-sitter
      --with-tree-sitter-lib=/path/to/tree-sitter/lib
      --with-tree-sitter-include=/path/to/tree-sitter/include

  EOL
end

$CFLAGS << ' -O3'
$CFLAGS << ' -std=c99'
$CFLAGS << ' -fPIC'

sanitizers = ENV['SANITIZE'] if ENV['SANITIZE']

if sanitizers =~ /memory/
  puts ''
  puts ''
  puts "We don't support memory sanitizers as of yet."
  puts 'It requires building ruby with the same sanitizer, and maybe its dependencies.'
  puts ''
  puts 'exiting…'
  puts ''
  puts ''
  exit 1
end

if sanitizers
  # NOTE: when sanitizing, the default generated warning flags emit a lot of …
  # warnings.
  #
  # I couldn't make mkmf understand it's running with clang and not gcc, so
  # I'm omitting those flags.
  #
  # It should be harmless, since sanitization is meant for CI and dev builds.
  $warnflags = ''

  $CFLAGS  << ' -fdeclspec'
  $CFLAGS  << " -fsanitize=#{sanitizers}"
  $CFLAGS  << ' -fsanitize-blacklist=../../../../.asanignore'
  $CFLAGS  << " -fsanitize-recover=#{sanitizers}"

  $CFLAGS  << ' -fno-sanitize-recover=all -fno-sanitize=null -fno-sanitize=alignment'
  $CFLAGS  << ' -fno-omit-frame-pointer'

  $LDFLAGS << " -fsanitize=#{sanitizers} -dynamic-libasan"
end

dir_config('tree-sitter')
create_header
create_makefile('tree_sitter/tree_sitter')
