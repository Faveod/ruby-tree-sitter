# frozen_string_literal: true

require 'test_helper'

module Utils
  class PrinterTest < Minitest::Test
    def setup
      @printer = TreeStand::Utils::Printer.new(ralign: 30)
      @parser = TreeStand::Parser.new('math')
    end

    def test_can_print_a_node
      tree = @parser.parse_string(<<~MATH)
        1 + x * 3
      MATH

      assert_equal(<<~SEXPR, @printer.print(tree.root_node).string)
        (expression
         (sum
          left: (number)              | 1
          ("+")                       | +
          right: (product
           left: (variable)           | x
           ("*")                      | *
           right: (number))))         | 3
      SEXPR
    end

    def test_printer_accepts_a_string
      tree = @parser.parse_string(<<~MATH)
        1 + x
      MATH

      assert_equal(<<~SEXPR, @printer.print(tree.root_node, io: +''))
        (expression
         (sum
          left: (number)              | 1
          ("+")                       | +
          right: (variable)))         | x
      SEXPR
    end

    def test_pretty_printing_nodes
      tree = @parser.parse_string(<<~MATH)
        1 + x * 3 + 2 / 4 ** 8 - 9 * (10 - 11.1)
      MATH

      assert_equal(<<~SEXPR, @printer.print(tree.root_node).string)
        (expression
         (subtraction
          left: (sum
           left: (sum
            left: (number)            | 1
            ("+")                     | +
            right: (product
             left: (variable)         | x
             ("*")                    | *
             right: (number)))        | 3
           ("+")                      | +
           right: (division
            left: (number)            | 2
            ("/")                     | /
            right: (exponent
             base: (number)           | 4
             ("**")                   | **
             exponent: (number))))    | 8
          ("-")                       | -
          right: (product
           left: (number)             | 9
           ("*")                      | *
           right: ("(")               | (
           (subtraction
            left: (number)            | 10
            ("-")                     | -
            right: (number))          | 11.1
           (")"))))                   | )
      SEXPR
    end
  end
end
