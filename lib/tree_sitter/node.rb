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
          raise IndexError, "Cannot find field #{k}. Available: #{fields}" unless fields.include?(k.to_sym)

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
    def method_missing(method_name, *_args, &_block)
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
    def each(&_block)
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
  end
end
