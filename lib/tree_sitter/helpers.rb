# frozen_string_literal: true

# splits an array like [rust](https://doc.rust-lang.org/std/primitive.slice.html#method.split)
def array_split_like_rust(array, &)
  return enum_for(__method__, array) if !block_given?

  return [] if array.empty?

  result = []
  current_slice = []

  array.each do |element|
    if yield(element)
      result << current_slice
      current_slice = []
    else
      current_slice << element
    end
  end

  result << current_slice
  result
end
