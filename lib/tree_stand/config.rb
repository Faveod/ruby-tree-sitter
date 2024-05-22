# frozen_string_literal: true
# typed: true

require 'pathname'

module TreeStand
  # Global configuration for the gem.
  # @api private
  class Config
    extend T::Sig

    sig { returns(T.nilable(Pathname)) }
    attr_reader :parser_path

    def parser_path=(path)
      @parser_path = Pathname(path)
    end
  end
end
