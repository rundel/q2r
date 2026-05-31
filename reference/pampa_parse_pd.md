# Parse QMD input with pampa and return the Pandoc AST

**\[experimental\]**

## Usage

``` r
pampa_parse_pd(input, quiet = FALSE, prune_errors = TRUE)
```

## Arguments

- input:

  A single string. Treated as a file path if it does not contain
  newlines and [`file.exists()`](https://rdrr.io/r/base/files.html)
  returns TRUE; otherwise treated as raw text. To parse an R-held
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) as
  Pandoc, render it first with
  [`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) and
  feed the result back in.

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

A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) object
with any parse diagnostics attached in its `@diagnostics` slot. If pampa
fails to produce a Pandoc AST the returned object has an empty
`@blocks`; the diagnostics explain why.
