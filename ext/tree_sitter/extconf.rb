require 'mkmf'
require 'pathname'

# ################################## #
#             Some helpers           #
# ################################## #

def system_tree_sitter?
  enable_config('sys-libs', true)
end

def sh cmd
  if !system(cmd)
    abort "Aborting.\nFailed to run:\n    #{cmd}\n"
  end
end

# ################################## #
#    System lib + dynamic linking    #
#                                    #
#                OR                  #
#                                    #
#  Downloaded libs + static linking  #
# ################################## #

dir_include, dir_lib, static =
  if system_tree_sitter?
    [['/opt/include', '/opt/local/include', '/usr/include', '/usr/local/include'],
     ['/opt/lib', '/opt/local/lib', '/usr/lib', '/usr/local/lib'],
     false]
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

    # We need to clean because the same folder is used over and over
    # by rake-compiler-dock
    sh "cd #{src} && make clean && make"

    # This is necessary to link statically against tree-sitter.
    # The docs don't mention anything about static-linking, so here we are.
    if !File.exists?(Pathname.pwd / 'libtree-sitter.a')
      sh "ln -s #{src / 'libtree-sitter.a'} #{Pathname.pwd / 'libtree-sitter.a'}"
    end

    if !File.exists?(Pathname.pwd / 'include')
      sh "ln -s #{src / 'lib' / 'include'} #{Pathname.pwd / 'include'}"
    end

    [[Pathname.pwd / 'include'], [Pathname.pwd.to_s], true]
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
    * Static linking         : #{static}

    Try to install tree-sitter from source, or through your package manager,
    or even try one of the following options to extconf.rb/rake compile:

      --with-tree-sitter-dir=/path/to/tree-sitter
      --with-tree-sitter-lib=/path/to/tree-sitter/lib
      --with-tree-sitter-include=/path/to/tree-sitter/include

  EOL
end

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

$CFLAGS << ' -O3'
$CFLAGS << ' -g'
$CFLAGS << ' -std=c99'
$CFLAGS << ' -fPIC'
$CFLAGS << ' -Wall'

if ENV['SANITIZE']
  $CFLAGS  << ' -fsanitize=address -fno-omit-frame-pointer'
  $LDFLAGS << ' -fsanitize=address -dynamic-libasan'
end

dir_config('tree-sitter')
create_header()
create_makefile('tree_sitter/tree_sitter')
