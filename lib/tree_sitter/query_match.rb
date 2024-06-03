# frozen_string_literal: true

require_relative 'query_captures'

module TreeSitter
  # A match for a {Query}.
  class QueryMatch
    # All nodes at a given capture index.
    #
    # @param index [Integer]
    #
    # @return [TreeSitter::Node]
    def nodes_for_capture_index(index) = captures.filter_map { |capture| capture.node if capture.index == index }

    # Whether the {QueryMatch} satisfies the text predicates in the query.
    #
    # This is a translation from the [rust bindings](https://github.com/tree-sitter/tree-sitter/blob/e553578696fe86071846ed612ee476d0167369c1/lib/binding_rust/lib.rs#L2502).
    # Because it's a direct translation, it's way too long and we need to shut up rubocop.
    # TODO: refactor + simplify when satable.
    def satisfies_text_predicate?(query, src) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return true if query.text_predicates[pattern_index].nil?

      query # rubocop:disable Metrics/BlockLength
        .text_predicates[pattern_index]
        .all? do |predicate|
          case predicate.type
          in TextPredicateCapture::EQ_CAPTURE
            fst_nodes = nodes_for_capture_index(predicate.fst)
            snd_nodes = nodes_for_capture_index(predicate.snd)
            res = nil
            consumed = 0
            fst_nodes.zip(snd_nodes).each do |node1, node2|
              text1 = node_text(node1, src)
              text2 = node_text(node2, src)
              if (text1 == text2) != predicate.positive? && predicate.match_all?
                res = false
                break
              end
              if (text1 == text2) == predicate.positive? && !predicate.match_all?
                res = true
                break
              end
              consumed += 1
            end
            (res.nil? && consumed == fst_nodes.length && consumed == snd_nodes.length) \
              || res

          in TextPredicateCapture::EQ_STRING
            nodes = nodes_for_capture_index(predicate.fst)
            res = true
            nodes.each do |node|
              text = node_text(node, src)
              if (predicate.snd == text) != predicate.positive? && predicate.match_all?
                res = false
                break
              end
              if (predicate.snd == text) == predicate.positive? && !predicate.match_all?
                res = true
                break
              end
            end
            res

          in TextPredicateCapture::MATCH_STRING
            nodes = nodes_for_capture_index(predicate.fst)
            res = true
            nodes.each do |node|
              text = node_text(node, src)
              if predicate.snd.match?(text) != predicate.positive? && predicate.match_all?
                res = false
                break
              end
              if predicate.snd.match?(text) == predicate.positive? && !predicate.match_all?
                res = true
                break
              end
            end
            res

          in TextPredicateCapture::ANY_STRING
            nodes = nodes_for_capture_index(predicate.fst)
            res = true
            nodes.each do |node|
              text = node_text(node, src)
              if predicate.snd.any? { |v| v == text } != predicate.positive?
                res = false
                break
              end
            end
            res

          end
        end
    end

    private

    def node_text(node, text) = text.byteslice(node.start_byte...node.end_byte)
  end
end
