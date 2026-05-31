# Parse QMD input with tree-sitter and return the tree-sitter AST

**\[experimental\]**

## Usage

``` r
pampa_parse_ts(input, quiet = FALSE, prune_errors = TRUE)
```

## Arguments

- input:

  A single string. Treated as a file path if it does not contain
  newlines and [`file.exists()`](https://rdrr.io/r/base/files.html)
  returns TRUE; otherwise treated as raw text.

- quiet:

  If `FALSE` (the default) any error-kind diagnostics are raised as R
  errors (after attaching diagnostics to the result), and warning-kind
  diagnostics are emitted as R warnings. If `TRUE` no signal is raised;
  diagnostics are still attached to the returned object's `@diagnostics`
  slot.

- prune_errors:

  If `TRUE` (the default, matching the pampa CLI) parser-error
  diagnostics are deduplicated by tree-sitter `ERROR` node, keeping the
  earliest per node. Set to `FALSE` to see every raw diagnostic pampa
  produces (useful for debugging the parser).

## Value

A [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) object
with any parse diagnostics attached in its `@diagnostics` slot.
Tree-sitter parsing itself never fails; the diagnostics surface
higher-level pampa errors.
