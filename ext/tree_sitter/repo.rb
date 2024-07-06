# frozen_string_literal: true

require_relative '../../lib/tree_sitter/version'

module TreeSitter
  # Fetches tree-sitter sources.
  class Repo
    attr_reader :exe, :src, :url, :version

    def initialize
      @version = TREESITTER_VERSION

      # `tree-sitter-@version` is the name produced by tagged releases of sources
      # by git, so we use it everywhere, including when cloning from git.
      @src = Pathname.pwd / "tree-sitter-#{@version}"

      @url = {
        git: 'https://github.com/tree-sitter/tree-sitter',
        tar: "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v#{@version}.tar.gz",
        zip: "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v#{@version}.zip",
      }

      @exe = {}
      %i[curl git tar wget zip].each do |cmd|
        @exe[cmd] = find_executable(cmd.to_s)
      end
    end

    def compile
      # We need to clean because the same folder is used over and over
      # by rake-compiler-dock
      sh "cd #{src} && make clean && make"
    end

    def exe?(name)
      @exe[name]
    end

    def extract?
      !exe.filter { |k, v| %i[tar zip].include?(k) && v }.empty?
    end

    def download
      # TODO: should we force re-download? Maybe with a flag?
      return true if Dir.exist? src

      res = false
      %w[git curl wget].each do |cmd|
        res =
          if find_executable(cmd)
            send("sources_from_#{cmd}")
          else
            false
          end
        break if res
      end

      res
    end

    def include_and_lib_dirs
      [[(src / 'lib' / 'include').to_s], [src.to_s]]
    end

    def keep_static_lib
      src
        .children
        .filter { |f| /\.(dylib|so)/ =~ f.basename.to_s }
        .each(&:unlink)
    end

    def sh(cmd)
      return if system(cmd)

      abort <<~MSG

        Failed to run: #{cmd}

        exiting …

      MSG
    end

    def sources_from_curl
      return false if !exe?(:curl) || !extract?

      if exe?(:tar)
        sh "curl -L #{url[:tar]} -o tree-sitter-v#{version}.tar.gz"
        sh "tar -xf tree-sitter-v#{version}.tar.gz"
      elsif exe?(:zip)
        sh "curl -L #{url[:zip]} -o tree-sitter-v#{version}.zip"
        sh "unzip -q tree-sitter-v#{version}.zip"
      end

      true
    end

    def sources_from_git
      return false if !exe?(:git)

      sh "git clone #{url[:git]} #{src}"
      sh "cd #{src} && git checkout tags/v#{version}"

      true
    end

    def sources_from_wget
      return false if !exe?(:wget) || !extract?

      if exe?(:tar)
        sh "wget #{url[:tar]} -O tree-sitter-v#{version}.tar.gz"
        sh "tar -xf tree-sitter-v#{version}.tar.gz"
      elsif exe?(:zip)
        sh "wget #{url[:zip]} -O tree-sitter-v#{version}.zip"
        sh "unzip -q tree-sitter-v#{version}.zip"
      end

      true
    end
  end
end
