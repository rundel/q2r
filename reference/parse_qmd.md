# Parse QMD input with pampa

**\[experimental\]**

## Usage

``` r
parse_qmd(input, ast = c("pd", "ts"), quiet = FALSE, prune_errors = TRUE)
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

- ast:

  The AST to return: `"pd"` (the default) for the Pandoc AST as a
  [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) object,
  or `"ts"` for the tree-sitter AST as a
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md).

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

For `ast = "pd"` a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) object, for
`ast = "ts"` a
[`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) object,
with any parse diagnostics attached in the `@diagnostics` slot. If pampa
fails to produce a Pandoc AST the returned `pandoc` has an empty
`@blocks`; the diagnostics explain why. Tree-sitter parsing itself never
fails.

## Details

Parses QMD text or a file with pampa and returns the requested AST. With
`ast = "pd"` (the default) the Pandoc AST is returned as a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) object;
with `ast = "ts"` the tree-sitter concrete syntax tree is returned as a
[`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md). Either
way any parse diagnostics are attached to the returned object's
`@diagnostics` slot.
