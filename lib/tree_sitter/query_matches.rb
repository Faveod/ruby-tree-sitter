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
    def each(&)
      return enum_for __method__ if !block_given?

      while match = @cursor.next_match
        if match.satisfies_text_predicate?(@query, @src)
          yield match
        end
      end
    end

    # Iterate over all the results presented as hashes of `capture name => node`.
    #
    # @yieldparam match [Hash<String, TreeSitter::Node>]
    def each_capture_hash(&)
      # TODO: should we return [Array<Hash<Symbol, TreeSitter::Node]>>] instead?
      return enum_for __method__ if !block_given?

      each do |match|
        yield match.captures.to_h { |cap| [@query.capture_name_for_id(cap.index), cap.node] }
      end
    end
  end
end
