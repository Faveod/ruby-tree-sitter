# frozen_string_literal: true

require 'test_helper'

module Visitors
  class TreeWalkerTest < Minitest::Test
    def setup
      @parser = TreeStand::Parser.new('math')
      @tree = @parser.parse_string(<<~MATH)
        1 + x * 3
      MATH
    end

    def test_walk_whole_tree
      node_types = []
      TreeStand::Visitors::TreeWalker.new(@tree.root_node) do |node|
        node_types << node.type
      end.visit

      assert_equal(
        %i[expression sum number + product variable * number],
        node_types,
      )
    end

    def test_walk_the_tree_depth_first
      tree = @parser.parse_string(<<~MATH)
        1 + x * 3 + 2
      MATH

      node_types = []
      tree.each do |node|
        node_types << node.type
      end

      assert_equal(
        #             double sum nodes show the tree is walked depth-first.
        #             v
        %i[expression sum sum number + product variable * number + number],
        node_types,
      )
    end

    def test_tree_api_walks_the_whole_tree
      node_types = []
      @tree.each do |node|
        node_types << node.type
      end

      assert_equal(
        %i[expression sum number + product variable * number],
        node_types,
      )

      assert(@tree.any? { |node| node.type == :number })
    end

    def test_tree_walk_api_walks_the_whole_tree
      node_types = []
      @tree.walk do |node|
        node_types << node.type
      end

      assert_equal(
        %i[expression sum number + product variable * number],
        node_types,
      )

      assert(@tree.any? { |node| node.type == :number })
    end

    def test_node_api_walks_the_whole_tree
      node_types = []
      @tree.root_node.walk do |node|
        node_types << node.type
      end

      assert_equal(
        %i[expression sum number + product variable * number],
        node_types,
      )

      assert(@tree.root_node.walk.any? { |node| node.type == :number })
    end
  end
end
