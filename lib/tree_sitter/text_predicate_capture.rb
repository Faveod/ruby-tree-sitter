# frozen_string_literal: true

module TreeSitter
  # A representation for text predicates.
  class TextPredicateCapture
    EQ_CAPTURE = 0   # Equality Capture
    EQ_STRING = 1    # Equality String
    MATCH_STRING = 2 # Match String
    ANY_STRING = 3   # Any String

    attr_reader :fst
    attr_reader :snd
    attr_reader :type

    # Create a TextPredicateCapture for {EQ_CAPTURE}.
    def self.eq_capture(...) = new(EQ_CAPTURE, ...)
    # Create a TextPredicateCapture for {EQ_STRING}.
    def self.eq_string(...) = new(EQ_STRING, ...)
    # Create a TextPredicateCapture for {MATCH_STRING}.
    def self.match_string(...) = new(MATCH_STRING, ...)
    # Create a TextPredicateCapture for {ANY_STRING}.
    def self.any_string(...) = new(ANY_STRING, ...)

    def initialize(type, fst, snd, positive, match_all)
      @type = type
      @fst = fst
      @snd = snd
      @positive = positive
      @match_all = match_all
    end

    # `#eq` is positive, `#not-eq` is not.
    def positive? = @positive
    # `#any-` means don't match all.
    def match_all? = @match_all
  end
end
