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
    #
    # @note this will explode (SEGFAULT) if you give it the wrong name. Since we
    # don't have access to the language object to check whether the name exists
    # (through `Language#field_id_for_name`), there's not much we can de from withing.
    # You need to make sure that the field name you're calling exists before doing so.
    def [](idx)
      case idx
      when Numeric        then named_child(idx)
      when String, Symbol then child_by_field_name(idx.to_s)
      else raise 'Node#[] accepts Integer and returns named child at given index, or a (String | Symbol) and returns the child by given field name.'
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
      # NOTE: `puts` calls `to_ary` when you defing a `method missing`, even if
      # you have `to_s` and `to_str` implemented.
      #
      # You can't `def to_ary = [self]` because for some weird reason it will
      # print `[...]` suggesting that some infinite recursion is internally
      # happening.
      #
      # One _hack_ can be `def to_ary = [self.to_s]`, but that screws with the
      # semantics of the object.  But it works.
      #
      # It turns ou that it's enough to tell the Ruby runtime that we don't
      # support `to_ary`, so it defaults to the expected behavior of calling
      # `to_s` on the object.
      if args[0] == :to_ary
        return false
      end
      init_fields
      args.length == 1 && @fields.include?(args[0])
    end

    # Iterate over a node's named children.
    #
    # @yieldparam name [NilClass | String] field name if it exists.
    # @yieldparam child [Node] the child
    def each
      child_count.times.each do |i|
        next if !child(i).named?

        yield field_name_for_child(i), child(i)
      end
    end

    # Iterate over a node's named children
    #
    # @yieldparam child [Node] the child
    def each_named_child
      return enum_for __method__ if !block_given?

      (0...(named_child_count)).each do |i|
        yield named_child(i)
      end
    end

    # Iterate over a node's children
    #
    # @yieldparam child [Node] the child
    def each_child
      return enum_for __method__ if !block_given?

      (0...(child_count)).each do |i|
        yield child(i)
      end
    end
  end
end
