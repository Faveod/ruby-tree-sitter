# Examples

## Run

From the project root:

```console
bundle exec ruby examples/01-json.rb
```

## Setup

These examples are meant to showcase the use of the API.

The examples will automatically download and build the language parsers via
`bin/get`.

## Specific language?

Edit the scripts and call 

```ruby
language = load(name, lib)
```

Where `lib` points directly to the dynamic library, i.e. your local build for
your local parser.
