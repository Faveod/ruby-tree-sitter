# frozen_string_literal: true
# typed: true

module TreeStand
  # A collection of useful visitors for traversing trees.
  module Visitors
    # Walks the tree depth-first and yields each node to the provided block.
    #
    # @example Create a list of all the nodes in the tree.
    #   list = []
    #   TreeStand::Visitors::TreeWalker.new(root) do |node|
    #     list << node
    #   end.visit
    #
    # @see TreeStand::Node#walk
    # @see TreeStand::Tree#walk
    class TreeWalker < Visitor
      extend T::Sig

      # @param block [Proc] A block that will be called for
      #   each node in the tree.
      sig do
        params(
          node: TreeStand::Node,
          block: T.proc.params(node: TreeStand::Node).void,
        ).void
      end
      def initialize(node, &block)
        super(node)
        @block = block
      end

      sig { override.params(node: TreeStand::Node).void }
      def on(node) = @block.call(node)
    end
  end
end
