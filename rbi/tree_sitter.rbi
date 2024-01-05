# typed: true

module TreeSitter
  class Node
    sig { returns(Integer) }
    def start_byte; end

    sig { returns(Integer) }
    def end_byte; end

    sig { returns(TreeSitter::Point) }
    def start_point; end

    sig { returns(TreeSitter::Point) }
    def end_point; end

    sig { returns(TreeSitter::Node) }
    def parent; end
  end

  class Tree
    sig { returns(TreeSitter::Node) }
    def root_node; end
  end

  class Query
    sig { params(language: TreeSitter::Language, source: String).void }
    def initialize(language, source); end

    sig { params(id: Integer).returns(String) }
    def capture_name_for_id(id); end
  end

  class QueryCursor
    sig { params(query: TreeSitter::Query, node: TreeSitter::Node).returns(TreeSitter::QueryCursor) }
    def self.exec(query, node); end

    sig { returns(T.nilable(TreeSitter::QueryMatch)) }
    def next_match; end
  end

  class QueryMatch
    sig { returns(T::Array[TreeSitter::QueryCapture]) }
    def captures; end
  end

  class QueryCapture
    sig { returns(Integer) }
    def index; end

    sig { returns(TreeSitter::Node) }
    def node; end
  end

  class Point
    sig { returns(Integer) }
    def row; end

    sig { returns(Integer) }
    def column; end
  end

  class Language
    sig { params(name: String, path: String).returns(TreeSitter::Language) }
    def self.load(name, path); end
  end

  class Parser
  end

  class TreeCursor
  end

  class Range
  end
end
