# frozen_string_literal: true
# typed: true

module TreeStand
  # Global configuration for the gem.
  # @api private
  class Config
    extend T::Sig

    sig { returns(String) }
    attr_accessor :parser_path
  end
end
