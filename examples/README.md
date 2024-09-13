# Examples

## Run

From the project root:

```console
bundle exec ruby examples/01-json.rb
```

## Setup

These examples are meant to showcase the use of the API.

Make sure to run `bin/setup` which uses
[`tsdl`](https://github.com/stackmystack/tsdl).

## Specific language?

Edit the scripts and call

```ruby
language = load(name, lib)
```

Where `lib` points directly to the dynamic library, i.e. your local build for
your local parser.
