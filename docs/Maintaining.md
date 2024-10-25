# Maintaining

## Release

Make sure you make a PR to bump tree-sitter version if necessary, and the gem's
version in `lib/tree_sitter/version.rb`.

Once everything is merged, we'll have a draft release; edit it, removing all old
artifacts (old version gems if they exist), assign a label corresponding to the
new gem version, and release. This will automatically trigger the release
workflow, making a github release and pushing all cross-compiled gems to
[rubygems.org](https://rubygems.org/gems/ruby_tree_sitter).

In the future, this will be far more simplified, and the maintainer will have to
just launch a script locally.

## Automatic tree-sitter version bump

There's a schedueled workflow that checks for new releases of tree-sitter. Once
we detect one, we will create a draft PR bumping the tree-sitter version. In
order to integrate the PR, mark it as ready for review, removing its draft
status, and then close and immediately reopen the PR to trigger the CI and
cross-compile workflows.

Unfortunately, this is the least complicated solution that works for now.
