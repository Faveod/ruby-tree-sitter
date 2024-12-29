# frozen_string_literal: true
# typed: true

module TreeStand
  module Cli
    # @!visibility private
    class Options
      attr_accessor :source_file, :query_file, :parser_file, :watch

      attr_reader :logger, :progname

      def initialize(progname = File.basename($PROGRAM_NAME))
        @logger = Logger.new($stderr, level: T.unsafe(ENV.fetch('LOG_LEVEL', Logger::INFO)), progname: progname)
        @progname = progname
      end

      # @!visibility private
      def define_options(parser)
        parser.banner = "usage: exe/#{progname} [options]"
        parser.on('-v', '--verbose', 'Enable verbose logging') { logger.level -= 1 }

        parser.on('-s', '--source SOURCE', 'The filepath to the source code to be parsed') do |filepath|
          self.source_file = error_no_file(File.expand_path(filepath), "Source file not found: #{filepath}", 1)
        end
        parser.on('-q', '--query QUERY', 'The filepath to the query to be run against the source code') do |filepath|
          self.query_file = error_no_file(File.expand_path(filepath), "Query file not found: #{filepath}", 2)
        end
        parser.on('-p', '--parser PARSER', 'The parser to use to parse the source code') do |filepath|
          self.parser_file = error_no_file(File.expand_path(filepath), "Parser file not found: #{filepath}", 3)
        end
      end

      # @!visibility private
      def check!
        error!('No source file provided, specify with --source', 4) unless source_file
        error!('No query file provided, specify with --query', 5) unless query_file
        error!('No parser file provided, specify with --parser', 6) unless parser_file

        parser_path = File.dirname(parser_file)

        TreeStand.configure do
          config.parser_path = parser_path
        end
      end

      # @!visibility private
      def source = @source ||= File.read(source_file)
      # @!visibility private
      def query = @query ||= File.read(query_file)
      # @!visibility private
      def parser = @parser ||= TreeStand::Parser.new(File.extname(source_file).delete_prefix('.'))
      # @!visibility private
      def tree = @tree ||= parser.parse_string(source)

      private

      def error_no_file(filepath, message, code)
        return filepath if File.exist?(filepath)

        error!(message, code)
      end

      def error!(message, code = 1)
        logger.error(message)
        exit(code)
      end
    end
  end
end
