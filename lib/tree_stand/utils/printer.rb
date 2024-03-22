# frozen_string_literal: true
# typed: true

module TreeStand
  # A collection of useful methods for working with syntax trees.
  module Utils
    # Used to {TreeStand::Node#pretty_print pretty-print} the node.
    #
    # @example
    #   pp node
    #   # (expression
    #   #  (sum
    #   #   left: (number)              | 1
    #   #   ("+")                       | +
    #   #   right: (variable)))         | x
    class Printer
      extend T::Sig

      # @param ralign the right alignment for the text column.
      sig { params(ralign: Integer).void }
      def initialize(ralign:)
        @ralign = ralign
      end

      # (see TreeStand::Utils::Printer)
      sig { params(node: TreeStand::Node, io: T.any(IO, StringIO, String)).returns(T.any(IO, StringIO, String)) }
      def print(node, io: StringIO.new)
        lines = pretty_output_lines(node)

        lines.each do |line|
          if line.text.empty?
            io << line.sexpr << "\n"
            next
          end

          io << "#{line.sexpr}#{' ' * [(@ralign - line.sexpr.size), 0].max}| #{line.text}\n"
        end

        io
      end

      private

      Line = Struct.new(:sexpr, :text)
      private_constant :Line

      def pretty_output_lines(node, prefix: '', depth: 0)
        indent = ' ' * depth
        ts_node = node.ts_node
        if indent.size + prefix.size + ts_node.to_s.size < @ralign || ts_node.child_count.zero?
          return [Line.new("#{indent}#{prefix}#{ts_node}", node.text)]
        end

        lines = T.let([Line.new("#{indent}#{prefix}(#{ts_node.type}", '')], T::Array[Line])

        node.each.with_index do |child, index|
          lines += if field_name = ts_node.field_name_for_child(index)
            pretty_output_lines(
              child,
              prefix: "#{field_name}: ",
              depth: depth + 1,
            )
          else
            pretty_output_lines(child, depth: depth + 1)
          end
        end

        T.must(lines.last).sexpr << ')'
        lines
      end
    end
  end
end
