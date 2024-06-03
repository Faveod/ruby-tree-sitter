# frozen_string_literal: true

module TreeSitter
  # A Cursor for {Query}.
  class QueryCursor
    # Iterate over all of the matches in the order that they were found.
    #
    # Each match contains the index of the pattern that matched, and a list of
    # captures. Because multiple patterns can match the same set of nodes,
    # one match may contain captures that appear *before* some of the
    # captures from a previous match.
    def matches(query, node, src)
      self.exec(query, node)
      QueryMatches.new(self, query, src)
    end

    # Iterate over all of the individual captures in the order that they
    # appear.
    #
    # This is useful if you don't care about which pattern matched, and just
    # want a single, ordered sequence of captures.
    def captures(query, node, src)
      self.exec(query, node)
      QueryCaptures.new(self, query, src)
    end
  end
end
