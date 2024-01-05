# frozen_string_literal: true
# typed: true

module TreeStand
  # Wrapper around a TreeSitter tree.
  #
  # This class exposes a convient API for working with the tree. There are
  # dangers in using this class. The tree is mutable and the document can be
  # changed. This class does not protect against that.
  #
  # Some of the moetods on this class edit and re-parse the document updating
  # the tree. Because the document is re-parsed, the tree will be different. Which
  # means all outstanding nodes & ranges will be invalid.
  #
  # Methods that edit the document are suffixed with `!`, e.g. `#edit!`.
  #
  # It's often the case that you will want perfrom multiple edits. One such
  # pattern is to call #query & #edit on all matches in a loop. It's important
  # to keep the destructive nature of #edit in mind and re-issue the query
  # after each edit.
  #
  # Another thing to keep in mind is that edits done later in the document will
  # likely not affect the ranges that occur earlier in the document. This can
  # be a convient property that could allow you to apply edits in a reverse order.
  # This is not always possible and depends on the edits you make, beware that
  # the tree will be different after each edit and this approach may cause bugs.
  class Tree
    extend T::Sig
    extend Forwardable
    include Enumerable

    sig { returns(String) }
    attr_reader :document

    sig { returns(TreeSitter::Tree) }
    attr_reader :ts_tree

    sig { returns(TreeStand::Parser) }
    attr_reader :parser

    # @!method query(query_string)
    #   (see TreeStand::Node#query)
    #   @note This is a convenience method that calls {TreeStand::Node#query} on
    #     {#root_node}.
    #
    # @!method find_node(query_string)
    #   (see TreeStand::Node#find_node)
    #   @note This is a convenience method that calls {TreeStand::Node#find_node} on
    #     {#root_node}.
    #
    # @!method find_node!(query_string)
    #   (see TreeStand::Node#find_node!)
    #   @note This is a convenience method that calls {TreeStand::Node#find_node!} on
    #     {#root_node}.
    #
    # @!method walk(&block)
    #   (see TreeStand::Node#walk)
    #
    #   @note This is a convenience method that calls {TreeStand::Node#walk} on
    #     {#root_node}.
    #
    #   @example Tree includes Enumerable
    #     tree.any? { |node| node.type == :error }
    #
    # @!method text
    #   (see TreeStand::Node#text)
    #   @note This is a convenience method that calls {TreeStand::Node#text} on
    #     {#root_node}.
    def_delegators(
      :root_node,
      :query,
      :find_node,
      :find_node!,
      :walk,
      :text,
    )

    alias_method :each, :walk

    # @api private
    sig { params(parser: TreeStand::Parser, tree: TreeSitter::Tree, document: String).void }
    def initialize(parser, tree, document)
      @parser = parser
      @ts_tree = tree
      @document = document
    end

    sig { returns(TreeStand::Node) }
    def root_node
      TreeStand::Node.new(self, @ts_tree.root_node)
    end

    # This method replaces the section of the document specified by range and
    # replaces it with the provided text. Then it will reparse the document and
    # update the tree!
    sig { params(range: TreeStand::Range, replacement: String).void }
    def edit!(range, replacement)
      new_document = +''
      new_document << @document[0...range.start_byte]
      new_document << replacement
      new_document << @document[range.end_byte..]
      replace_with_new_doc(new_document)
    end

    # This method deletes the section of the document specified by range. Then
    # it will reparse the document and update the tree!
    sig { params(range: TreeStand::Range).void }
    def delete!(range)
      new_document = +''
      new_document << @document[0...range.start_byte]
      new_document << @document[range.end_byte..]
      replace_with_new_doc(new_document)
    end

    private

    def replace_with_new_doc(new_document)
      @document = new_document
      new_tree = @parser.parse_string(@document, tree: self)
      @ts_tree = new_tree.ts_tree
    end
  end
end
