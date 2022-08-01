# frozen_string_literal: true

module TreeSitter
  class Node
    attr_reader :fields

    def init_fields
      if !@fields
        @fields = Set.new
        child_count.times do |i|
          name = field_name_for_child(i)
          @fields << name.to_sym if name
        end
      end
    end

    private :init_fields

    # Access node's named children
    #
    # @param idx [Integer | String | Symbol, #read]
    #
    # @return [Node] The named child @idx `if idx.is_a?(Numeric)`, or the named child
    # for the given field name `if idx.is_a(String) || idx.is_a?(Symbol).`
    def [](idx)
      case idx
      when Numeric        then named_child(idx)
      when String, Symbol then child_by_field_name(idx.to_s)
      else raise <<~ERR
        Node#[] accepts Integer and returns named child at given index,
          or a (String | Symbol) and returns the child by given field name.
      ERR
      end
    end

    # Allows access to child_by_field_name without using [].
    def method_missing(method_name, *_args, &_block)
      init_fields
      if @fields.include?(method_name)
        child_by_field_name(method_name.to_s)
      else
        super
      end
    end

    def respond_to_missing?(*args)
      init_fields
      args.length == 1 && @fields.include?(args[0])
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
  end
end
