# frozen_string_literal: true

require_relative '../test_helper'
require 'stringio'

ruby = TreeSitter.lang('ruby')
parser = TreeSitter::Parser.new
parser.language = ruby

program = <<~RUBY
  def mul(a, b)
    res = a * b
    puts res.inspect
    return res
  end
RUBY

# Use with fork.
#
# Minitest on ruby 2.7 was failing sometimes for no particular reason,
# complaining about some random number not having a `write` method.
#
# My assumption is that the global var $stderr is not playing nice when
# we try to replace it and other minitest stuff are going alongside.
#
# If this theory holds, then forking should solve any race conditions that
# minitest could introduce. Let's wait and see.
def capture_stderr
  # The output stream must be an IO-like object. In this case we capture it in
  # an in-memory IO object so we can return the string value. You can assign any
  # IO object here.
  previous_stderr = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  # Restore the previous value of stderr (typically equal to STDERR).
  $stderr = previous_stderr
end

describe 'logging' do
  it 'should log to stderr by default' do
    fork do
      captured_output = capture_stderr do
        # Does not output anything directly.
        parser.logger = TreeSitter::Logger.new
        parser.parse_string(nil, program)
      end
      refute_equal 0, captured_output.length
    end
  end

  it 'should log to IO objects' do
    backend = StringIO.new
    parser.logger = TreeSitter::Logger.new(backend)
    parser.parse_string(nil, program)
    refute_equal 0, backend.length
  end

  it 'should format output when a format string is passed' do
    delim = '~~~~~'
    backend = StringIO.new
    parser.logger = TreeSitter::Logger.new(backend, "%s#{delim}%s")
    parser.parse_string(nil, program)
    backend.each_line do |l|
      assert (/#{delim}/ =~ l), 'delimiter must be in every single line'
    end
  end
end
