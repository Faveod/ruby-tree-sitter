# frozen_string_literal: true

module TreeSitter
  # Base tree-sitter error.
  class TreeSitterError < StandardError
  end

  # Raised when the language symbol is found, but loading it returns nothing.
  class LanguageLoadError < TreeSitterError
  end

  # Raised when a parser is not found.
  class ParserNotFoundError < TreeSitterError
  end

  # Raised when the parser version is incompatible with the current tree-sitter.
  class ParserVersionError < TreeSitterError
  end

  # Raised when a parser is not found.
  class SymbolNotFoundError < TreeSitterError
  end
end
