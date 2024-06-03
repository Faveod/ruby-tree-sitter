# frozen_string_literal: true

module TreeSitter
  # A {Query} predicate generic representation.
  class QueryPredicate
    attr_accessor :operator
    attr_accessor :args

    def initialize(operator, args)
      @operator = operator
      @args = args
    end
  end
end
