# frozen_string_literal: true
# typed: true

module TreeStand
  # Breadth-first traversal through the tree, calling hooks at each stop.
  class BreadthFirstVisitor
    extend T::Sig

    sig { params(node: TreeStand::Node).void }
    def initialize(node)
      @node = node
    end

    # Run the visitor on the document and return self. Allows chaining create and visit.
    # @example
    #   visitor = CountingVisitor.new(node, :predicate).visit
    sig { returns(T.self_type) }
    def visit
      queue = [@node]
      visit_node(queue) while queue.any?
      self
    end

    # @abstract The default implementation does nothing.
    sig { overridable.params(node: TreeStand::Node).void }
    def on(node) = nil

    # @abstract The default implementation yields to visit all children.
    sig { overridable.params(node: TreeStand::Node, block: T.proc.void).void }
    def around(node, &block) = yield

    private

    def visit_node(queue)
      node = queue.shift

      if respond_to?("on_#{node.type}")
        public_send("on_#{node.type}", node)
      else
        on(node)
      end

      if respond_to?("around_#{node.type}")
        public_send("around_#{node.type}", node) do
          node.each { |child| queue << child }
        end
      else
        around(node) do
          node.each { |child| queue << child }
        end
      end
    end
  end
end
