# frozen_string_literal: true

require_relative 'helpers'

parser = TreeSitter::Parser.new
language = TreeSitter.lang('json')
parser.language = language

# from https://www.json.org/example.html
src = <<~JSON
{
  "glossary": {
    "title": "example glossary",
    "GlossDiv": {
      "title": "S",
      "GlossList": {
        "GlossEntry": {
          "ID": "SGML",
          "SortAs": "SGML",
          "GlossTerm": "Standard Generalized Markup Language",
          "Acronym": "SGML",
          "Abbrev": "ISO 8879:1986",
          "GlossDef": {
            "para": "A meta-markup language, used to create markup languages such as DocBook.",
            "GlossSeeAlso": ["GML", "XML"]
          },
          "GlossSee": "markup"
        }
      }
    }
  }
}
JSON

tree = parser.parse_string(nil, src)
root = tree.root_node
puts root.sexpr

# $ bundle exec ruby examples/06-sexp.rb
# (document
#   (object
#     ({)
#     (pair
#       key: (string (") (string_content) ("))
#       (:)
#       value:
#         (object
#           ({)
#           (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#           (,)
#           (pair
#             key: (string (") (string_content) ("))
#             (:)
#             value:
#               (object
#                 ({)
#                 (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                 (,)
#                 (pair
#                   key: (string (") (string_content) ("))
#                   (:)
#                   value:
#                     (object
#                       ({)
#                       (pair
#                         key: (string (") (string_content) ("))
#                         (:)
#                         value:
#                           (object
#                             ({)
#                             (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                             (,)
#                             (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                             (,)
#                             (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                             (,)
#                             (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                             (,)
#                             (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                             (,)
#                             (pair
#                               key: (string (") (string_content) ("))
#                               (:)
#                               value:
#                                 (object
#                                   ({)
#                                   (pair
#                                     key: (string (") (string_content) ("))
#                                     (:)
#                                     value: (string (") (string_content) (")))
#                                   (,)
#                                   (pair
#                                     key: (string (") (string_content) ("))
#                                     (:)
#                                     value:
#                                       (array
#                                         ([)
#                                         (string (") (string_content) ("))
#                                         (,)
#                                         (string (") (string_content) ("))
#                                         (])))
#                                   (})))
#                             (,)
#                             (pair key: (string (") (string_content) (")) (:) value: (string (") (string_content) (")))
#                             (})))
#                       (})))
#                 (})))
#           (})))
#     (})))
