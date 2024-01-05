# frozen_string_literal: true
# typed: true

module TreeStand
  # Depth-first traversal through the tree, calling hooks at each stop.
  #
  # Hooks are language dependent and are defined by creating methods on the
  # visitor with the form `on_*` or `around_*`, where `*` is {Node#type}.
  #
  # - Hooks prefixed with `on_*` are called *before* visiting a node.
  # - Hooks prefixed with `around_*` must `yield` to continue visiting child
  #   nodes.
  #
  # You can also define default hooks by implementing an {on} or {around}
  # method to call when visiting each node.
  #
  # @example Create a visitor counting certain nodes
  #   class CountingVisitor < TreeStand::Visitor
  #     attr_reader :count
  #
  #     def initialize(root, type:)
  #       super(root)
  #       @type = type
  #       @count = 0
  #     end
  #
  #     def on_predicate(node)
  #       # if this node matches our search, increment the counter
  #       @count += 1 if node.type == @type
  #     end
  #   end
  #
  #   # Initialize a visitor
  #   visitor = CountingVisitor.new(document, :predicate).visit
  #   # Check the result
  #   visitor.count
  #   # => 3
  #
  # @example A visitor using around hooks to contruct a tree
  #   class TreeBuilder < TreeStand::Visitor
  #     TreeNode = Struct.new(:name, :children)
  #
  #     attr_reader :stack
  #
  #     def initialize(root)
  #       super(root)
  #       @stack = []
  #     end
  #
  #     def around(node)
  #       @stack << TreeNode.new(node.type, [])
  #
  #       # visit all children of this node
  #       yield
  #
  #       # The last node on the stack is the root of the tree.
  #       return if @stack.size == 1
  #
  #       # Pop the last node off the stack and add it to the parent
  #       @stack[-2].children << @stack.pop
  #     end
  #   end
  class Visitor
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
      visit_node(@node)
      self
    end

    # @abstract The default implementation does nothing.
    #
    # @example Create callback to count all nodes in a tree.
    #   def on(node)
    #     @count += 1
    #   end
    sig { overridable.params(node: TreeStand::Node).void }
    def on(node) = nil

    # @abstract The default implementation yields to visit all children.
    #
    # @example Use around hooks to run logic before & after visiting a node. Pairs will with a stack.
    #   def around(node)
    #     @stack << TreeNode.new(node.type, [])
    #
    #     # visit all children of this node
    #     yield
    #
    #     # The last node on the stack is the root of the tree.
    #     return if @stack.size == 1
    #
    #     # Pop the last node off the stack and add it to the parent
    #     @stack[-2].children << @stack.pop
    #   end
    sig { overridable.params(node: TreeStand::Node, block: T.proc.void).void }
    def around(node, &block) = yield

    private

    def visit_node(node)
      if respond_to?("on_#{node.type}")
        public_send("on_#{node.type}", node)
      else
        on(node)
      end

      if respond_to?("around_#{node.type}")
        public_send("around_#{node.type}", node) do
          node.each { |child| visit_node(child) }
        end
      else
        around(node) do
          node.each { |child| visit_node(child) }
        end
      end
    end
  end
end
