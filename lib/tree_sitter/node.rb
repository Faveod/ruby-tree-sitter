# frozen_string_literal: true

module TreeSitter
  class Node
    def fields
      return @fields if @fields

      @fields = Set.new
      child_count.times do |i|
        name = field_name_for_child(i)
        @fields << name.to_sym if name
      end

      @fields
    end

    def field?(field)
      fields.include?(field)
    end

    # Access node's named children.
    #
    # It's similar to {#fetch}, but differes in input type, return values, and
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
      when 0 then raise "#{self.class.name}##{__method__} requires a key."
      when 1
        case k = keys.first
        when Numeric        then named_child(k)
        when String, Symbol
          if fields.include?(k.to_sym)
            child_by_field_name(k.to_s)
          else
            raise "Cannot find field #{k}"
          end
        else raise <<~ERR
          #{self.class.name}##{__method__} accepts Integer and returns named child at given index,
              or a (String | Symbol) and returns the child by given field name.
        ERR
        end
      else
        keys.map { |key| self[key] }
      end
    end

    # Allows access to child_by_field_name without using [].
    def method_missing(method_name, *_args, &_block)
      if fields.include?(method_name)
        child_by_field_name(method_name.to_s)
      else
        super
      end
    end

    def respond_to_missing?(*args)
      args.length == 1 && fields.include?(args[0])
    end

    # Iterate over a node's children.
    #
    # @yieldparam child [Node] the child
    def each
      return enum_for __method__ if !block_given?

      (0...(child_count)).each do |i|
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

    def to_a
      each.to_a
    end

    # Access node's named children.
    #
    # It's similar to {#fetch}, but differes in input type, return values, and
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
    # @param all [Boolean] If `true`, return an array of nodes for all the
    # demanded keys, putting `nil` for missing ones.  If `false`, return the
    # same array after calling `compact`. Defaults to `false`.
    #
    # See {#fetch_all}.
    def fetch(*keys, all: false, **_kwargs)
      dict = {}
      keys.each.with_index do |k, i|
        dict[k.to_s] = i
      end

      res = {}
      each_field do |f, c|
        if dict.key?(f)
          res[f] = c
          dict.delete(f)
        end
        break if dict.empty?
      end

      res = keys.uniq.map { |k| res[k.to_s] }
      res = res.compact if !all
      res
    end

    # Access all named children of a node, returning `nil` for missing ones.
    #
    # Equivalent to `fetch(…, all: true)`.
    #
    # See {#fetch}.
    def fetch_all(*keys, **kwargs)
      kwargs[:all] = true
      fetch(*keys, **kwargs)
    end
  end
end
