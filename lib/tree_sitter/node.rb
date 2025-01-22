# frozen_string_literal: true

module TreeSitter
  # Node is a wrapper around a tree-sitter node.
  class Node
    include Enumerable

    # @return [Array<Symbol>] the node's named fields
    def fields
      return @fields if @fields

      @fields = Set.new
      child_count.times do |i|
        name = field_name_for_child(i)
        @fields << name.to_sym if name
      end

      @fields.to_a
    end

    # @param field [String, Symbol]
    def field?(field)
      fields.include?(field.to_sym)
    end

    # Access node's named children.
    #
    # It's similar to {#fetch}, but differs in input type, return values, and
    # the internal implementation.
    #
    # Both of these methods exist for separate use cases, but also because
    # sometime tree-sitter does some monkey business and having both separate
    # implementations can help.
    #
    # Comparison with {#fetch}:
    #
    #              []                            | fetch
    #              ------------------------------+----------------------
    # input types  Integer, String, Symbol       | Array<String, Symbol>
    #              Array<Integer, String, Symbol>|
    #              ------------------------------+----------------------
    # returns      1-to-1 correspondance with    | unique nodes
    #              input                         |
    #              ------------------------------+----------------------
    # uses         named_child                   | field_name_for_child
    #              child_by_field_name           |   via each_node
    #              ------------------------------+----------------------
    #
    # @param keys [Integer | String | Symbol | Array<Integer, String, Symbol>, #read]
    #
    # @return [Node | Array<Node>]
    def [](*keys)
      case keys.length
      when 0 then raise ArgumentError, "#{self.class.name}##{__method__} requires a key."
      when 1
        case k = keys.first
        when Integer then named_child(k)
        when String, Symbol
          raise IndexError, "Cannot find field #{k.to_sym}. Available: #{fields.to_a}" unless fields.include?(k.to_sym)

          child_by_field_name(k.to_s)
        else raise ArgumentError, <<~ERR
          #{self.class.name}##{__method__} accepts Integer and returns named child at given index,
              or a (String | Symbol) and returns the child by given field name.
        ERR
        end
      else
        keys.map { |key| self[key] }
      end
    end

    # @!visibility private
    #
    # Allows access to child_by_field_name without using [].
    def method_missing(method_name, *_args, &)
      if fields.include?(method_name)
        child_by_field_name(method_name.to_s)
      else
        super
      end
    end

    # @!visibility private
    #
    def respond_to_missing?(*args)
      args.length == 1 && fields.include?(args[0])
    end

    # Iterate over a node's children.
    #
    # @yieldparam child [Node] the child
    def each(&)
      return enum_for __method__ if !block_given?

      (0...child_count).each do |i|
        yield child(i)
      end
    end

    # Iterate over a node's children assigned to a field.
    #
    # @yieldparam name [NilClass | String] field name.
    # @yieldparam child [Node] the child.
    def each_field
      return enum_for __method__ if !block_given?

      each.with_index do |c, i|
        f = field_name_for_child(i)
        next if f.nil? || f.empty?

        yield f, c
      end
    end

    # Iterate over a node's named children
    #
    # @yieldparam child [Node] the child
    def each_named
      return enum_for __method__ if !block_given?

      (0...(named_child_count)).each do |i|
        yield named_child(i)
      end
    end

    # @return [Array<TreeSitter::Node>] all the node's children
    def to_a
      each.to_a
    end

    # Access node's named children.
    #
    # It's similar to {#[]}, but differs in input type, return values, and
    # the internal implementation.
    #
    # Both of these methods exist for separate use cases, but also because
    # sometime tree-sitter does some monkey business and having both separate
    # implementations can help.
    #
    # Comparison with {#fetch}:
    #
    #              []                            | fetch
    #              ------------------------------+----------------------
    # input types  Integer, String, Symbol       | String, Symbol
    #              Array<Integer, String, Symbol>| Array<String, Symbol>
    #              ------------------------------+----------------------
    # returns      1-to-1 correspondance with    | unique nodes
    #              input                         |
    #              ------------------------------+----------------------
    # uses         named_child                   | field_name_for_child
    #              child_by_field_name           |   via each_node
    #              ------------------------------+----------------------
    #
    # See {#[]}.
    def fetch(*keys)
      keys = keys.map(&:to_s)
      key_set = keys.to_set
      fields = {}
      each_field do |f, _c|
        fields[f] = self[f] if key_set.delete(f)

        break if key_set.empty?
      end
      fields.values_at(*keys)
    end

    # Regex for line annotation extraction from sexpr with source.
    #
    # @!visibility private
    LINE_ANNOTATION = /\0\{(.*?)\0\}/

    # Pretty-prints the node's sexp.
    #
    # The default call to {to_s} or {to_string} calls tree-sitter's
    # `ts_node_string`. It's displayed on a single line, so reading a rich node
    # becomes tiresome.
    #
    # This provides a better sexpr where you can control the "screen" width to
    # decide when to break.
    #
    # @param indent   [Integer]
    #   indentation for nested nodes.
    # @param width    [Integer]
    #   the screen's width.
    # @param source   [Nil|String]
    #   display source on the margin if not `nil`.
    # @param vertical [Nil|Boolean]
    #   fit as much sexpr on a single line if `false`, else, go vertical.
    #   This is always `true` if `source` is not `nil`.
    #
    # @return [String] the pretty-printed sexpr.
    def sexpr(indent: 2, width: 120, source: nil, vertical: nil)
      res =
        sexpr_recur(
          indent:,
          width:,
          source:,
          vertical: !source.nil? || !!vertical,
        ).output
      return res if source.nil?

      max_width = 0
      res
        .lines
        .map { |line|
          extracted = line.scan(LINE_ANNOTATION).flatten.first || ''
          base = line.gsub(LINE_ANNOTATION, '').rstrip
          max_width = [max_width, base.length].max
          [base, extracted]
        }
        .map { |base, extracted| ("%-#{max_width}s | %s" % [base, extracted]).rstrip }
        .join("\n")
    end

    # Helper function for {sexpr}.
    #
    # @!visibility private
    def sexpr_recur(indent: 2, width: 120, out: nil, source: nil, vertical: false)
      out ||= Oppen::Wadler.new(width:)
      out.group(indent:) {
        out.text "(#{type}"
        if source.is_a?(String) && child_count.zero?
          out.text "\0{#{source.byteslice(start_byte...end_byte)}\0}", width: 0
        end
        brk(out, vertical) if child_count.positive?
        each.with_index do |child, index|
          if field_name = field_name_for_child(index)
            out
              .text("#{field_name}:")
              .group(indent:) {
                brk(out, vertical)
                child.sexpr_recur(indent:, width:, out:, vertical:, source:)
              }
          else
            child.sexpr_recur(indent:, width:, out:, vertical:, source:)
          end
          brk(out, vertical) if index < child_count - 1
        end
        out.text ')'
      }
      out
    end

    # Break helper
    #
    # !@visibility private
    def brk(out, vertical)
      if vertical
        out.break
      else
        out.breakable
      end
    end
  end
end
