# frozen_string_literal: true

module TreeSitter
  # A sequence of {QueryMatch} associated with a given {QueryCursor}.
  class QueryMatches
    include Enumerable

    def initialize(cursor, query, src)
      @cursor = cursor
      @query = query
      @src = src
    end

    # Iterator over matches.
    #
    # @yieldparam match [TreeSitter::QueryMatch]
    def each(&_block)
      return enum_for __method__ if !block_given?

      while match = @cursor.next_match
        if match.satisfies_text_predicate?(@query, @src)
          yield match
        end
      end
    end
  end
end
