# frozen_string_literal: true

require_relative 'helpers'

class Test
  def run
    parser = TreeSitter::Parser.new
    language = TreeSitter.lang('javascript')

    src = "console.log('hello, world!');"

    parser.language = language

    tree = parser.parse_string(nil, src)
    root = tree.root_node
    [root].type
  end
end

class Minitest
  attr_accessor :result

  def run
    read, write = IO.pipe

    pid = Process.fork do
      data = 'intialized'
      begin
        read.close
        data = Test.new.run
      rescue StandardError => e
        data = e
      ensure
        GC.start(full_mark: true, immediate_sweep: true)
        write.write(Marshal.dump(data))
      end
    end

    write.close
    res = read.read
    Process.wait(pid)
    @result = Marshal.load(res)
  end
end

t = Minitest.new
t.run

puts t.result
