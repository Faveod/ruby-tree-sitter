# frozen_string_literal: true

module TreeSitter
  # A sequence of {TreeSitter::QueryCapture} associated with a given {TreeSitter::QueryCursor}.
  class QueryCaptures
    include Enumerable

    def initialize(cursor, query, src)
      @cursor = cursor
      @query = query
      @src = src
    end

    # Iterator over captures.
    #
    # @yieldparam match [TreeSitter::QueryMatch]
    # @yieldparam capture_index [Integer]
    def each(&)
      return enum_for __method__ if !block_given?

      while (capture_index, match = @cursor.next_capture)
        next if !match.is_a?(TreeSitter::QueryMatch)

        if match.satisfies_text_predicate?(@query, @src)
          yield [match, capture_index]
        end
      end
    end
  end
end
