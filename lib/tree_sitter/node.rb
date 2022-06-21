# frozen_string_literal: true

module TreeSitter
  class Node
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
  end
end
