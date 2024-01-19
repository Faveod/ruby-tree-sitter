# frozen_string_literal: true
# typed: true

module TreeStand
  # An experimental class to modify the AST. It re-runs the query on the
  # modified document every loop to ensure that the match is still valid.
  # @see TreeStand::Tree
  # @api experimental
  class AstModifier
    extend T::Sig

    sig { params(tree: TreeStand::Tree).void }
    def initialize(tree)
      @tree = tree
    end

    # @param query [String]
    # @yieldparam self [self]
    # @yieldparam match [TreeStand::Match]
    # @return [void]
    def on_match(query)
      matches = @tree.query(query)

      while !matches.empty?
        yield self, matches.first
        matches = @tree.query(query)
      end
    end
  end
end
