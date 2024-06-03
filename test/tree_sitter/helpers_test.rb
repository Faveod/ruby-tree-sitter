# frozen_string_literal: true

require_relative '../test_helper'
require 'tree_sitter/helpers'

describe 'array_split_like_rust' do
  it 'handles an empty array' do
    arr = []
    result = array_split_like_rust(arr) { |x| x == 1 }
    _(result).must_equal []
  end

  it 'handles no delimiters' do
    arr = [1, 2, 3]
    result = array_split_like_rust(arr) { |_| false }
    _(result).must_equal [[1, 2, 3]]
  end

  it 'handles all elements as delimiters' do
    arr = [1, 1, 1]
    result = array_split_like_rust(arr) { |x| x == 1 }
    _(result).must_equal [[], [], [], []]
  end

  it 'handles no split points' do
    arr = [1, 2, 3]
    result = array_split_like_rust(arr) { |x| x == 4 }
    _(result).must_equal [[1, 2, 3]]
  end

  it 'splits the array at the start' do
    arr = [1, 2]
    result = array_split_like_rust(arr) { |x| x == 1 }
    _(result).must_equal [[], [2]]
  end

  it 'splits the array at the end' do
    arr = [1, 2, 3]
    result = array_split_like_rust(arr) { |x| x == 3 }
    _(result).must_equal [[1, 2], []]
  end

  it 'splits the array at specified element' do
    arr = [1, 2, 3, 4, 5]
    result = array_split_like_rust(arr) { |x| x == 3 }
    _(result).must_equal [[1, 2], [4, 5]]
  end

  it 'handles multiple split points' do
    arr = [1, 2, 3, 4, 3, 5, 3, 6]
    result = array_split_like_rust(arr) { |x| x == 3 }
    _(result).must_equal [[1, 2], [4], [5], [6]]
  end
end
