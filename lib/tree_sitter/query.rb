# frozen_string_literal: true

require_relative 'helpers'

module TreeSitter
  # Query is a wrapper around a tree-sitter query.
  class Query
    attr_reader :capture_names
    attr_reader :capture_quantifiers
    attr_reader :text_predicates
    attr_reader :property_predicates
    attr_reader :property_settings
    attr_reader :general_predicates

    private

    # Called from query.c on initialize.
    #
    # Prepares all the predicates so we could process them in places like
    # {QueryMatch#satisfies_text_predicate?}.
    #
    # This is translation from the [rust bindings](https://github.com/tree-sitter/tree-sitter/blob/e553578696fe86071846ed612ee476d0167369c1/lib/binding_rust/lib.rs#L1860)
    # Because it's a direct translation, it's way too long and we need to shut up rubocop.
    # TODO: refactor + simplify when stable.
    def process(source) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      string_count = self.string_count
      capture_count = self.capture_count
      pattern_count = self.pattern_count

      # Build a vector of strings to store the capture names.
      capture_names = capture_count.times.map { |i| capture_name_for_id(i) }

      # Build a vector to store capture qunatifiers.
      capture_quantifiers =
        pattern_count.times.map do |i|
          capture_count.times.map do |j|
            capture_quantifier_for_id(i, j)
          end
        end

      # Build a vector of strings to represent literal values used in predicates.
      string_values = string_count.times.map { |i| string_value_for_id(i) }

      # Build a vector of predicates for each pattern.
      pattern_count.times do |i| # rubocop:disable Metrics/BlockLength
        predicate_steps = predicates_for_pattern(i)
        byte_offset = start_byte_for_pattern(i)
        row = source[0...byte_offset].count("\n")
        text_predicates = []
        property_predicates = []
        property_settings = []
        general_predicates = []

        array_split_like_rust(predicate_steps) { |s| s.type == QueryPredicateStep::DONE } # rubocop:disable Metrics/BlockLength
          .each do |p|
            next if p.empty?

            if p[0] == QueryPredicateStep::STRING
              cap = capture_names[p[0].value_id]
              raise ArgumentError, <<~MSG.chomp
                L#{row}: Expected predicate to start with a function name. Got @#{cap}.
              MSG
            end

            # Build a predicate for each of the known predicate function names.
            operator_name = string_values[p[0].value_id]

            case operator_name
            in 'any-eq?' | 'any-not-eq?' | 'eq?' | 'not-eq?'
              if p.size != 3
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: Wrong number of arguments to ##{operator_name} predicate. Expected 2, got #{p.size - 1}.
                MSG
              end

              if p[1].type != QueryPredicateStep::CAPTURE
                lit = string_values[p[1].value_id]
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: First argument to ##{operator_name} predicate must be a capture name. Got literal "#{lit}".
                MSG
              end

              is_positive = %w[eq? any-eq?].include?(operator_name)
              match_all = %w[eq? not-eq?].include?(operator_name)
              # NOTE: in the rust impl, match_all can hit an unreachable! but I am simplifying
              # for readability. Same applies for the other `in` branches.
              text_predicates <<
                if p[2].type == QueryPredicateStep::CAPTURE
                  TextPredicateCapture.eq_capture(p[1].value_id, p[2].value_id, is_positive, match_all)
                else
                  TextPredicateCapture.eq_string(p[1].value_id, string_values[p[2].value_id], is_positive, match_all)
                end

            in 'match?' | 'not-match?' | 'any-match?' | 'any-not-match?'
              if p.size != 3
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: Wrong number of arguments to ##{operator_name} predicate. Expected 2, got #{p.size - 1}.
                MSG
              end

              if p[1].type != QueryPredicateStep::CAPTURE
                lit = string_values[p[1].value_id]
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: First argument to ##{operator_name} predicate must be a capture name. Got literal "#{lit}".
                MSG
              end

              if p[2].type == QueryPredicateStep::CAPTURE
                cap = capture_names[p[2].value_id]
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: First argument to ##{operator_name} predicate must be a literal. Got capture @#{cap}".
                MSG
              end

              is_positive = %w[match? any-match?].include?(operator_name)
              match_all = %w[match? not-match?].include?(operator_name)
              regex = /#{string_values[p[2].value_id]}/

              text_predicates << TextPredicateCapture.match_string(p[1].value_id, regex, is_positive, match_all)

            in 'set!'
              property_settings << 'todo!'

            in 'is?' | 'is-not?'
              property_predicates << 'todo!'

            in 'any-of?' | 'not-any-of?'
              if p.size < 2
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: Wrong number of arguments to ##{operator_name} predicate. Expected at least 1, got #{p.size - 1}.
                MSG
              end

              if p[1].type != QueryPredicateStep::CAPTURE
                lit = string_values[p[1].value_id]
                raise ArgumentError, <<~MSG.chomp
                  L#{row}: First argument to ##{operator_name} predicate must be a capture name. Got literal "#{lit}".
                MSG
              end

              is_positive = operator_name == 'any_of'
              values = []

              p[2..].each do |arg|
                if arg.type == QueryPredicateStep::CAPTURE
                  lit = string_values[arg.value_id]
                  raise ArgumentError, <<~MSG.chomp
                    L#{row}: First argument to ##{operator_name} predicate must be a capture name. Got literal "#{lit}".
                  MSG
                end
                values << string_values[arg.value_id]
              end

              # TODO: is the map to to_s necessary in ruby?
              text_predicates <<
                TextPredicateCapture.any_string(p[1].value_id, values.map(&:to_s), is_positive, match_all)
            else
              general_predicates <<
                QueryPredicate.new(
                  operator_name,
                  p[1..].map do |a|
                    if a.type == QueryPredicateStep::CAPTURE
                      { capture: a.value_id }
                    else
                      { string: string_values[a.value_id] }
                    end
                  end,
                )
            end

            @text_predicates << text_predicates
            @property_predicates << property_predicates
            @property_settings << property_settings
            @general_predicates << general_predicates
          end

        @capture_names = capture_names
        @capture_quantifiers = capture_quantifiers
      end
    end

    # TODO
    def parse_property
      # todo
    end
  end
end
