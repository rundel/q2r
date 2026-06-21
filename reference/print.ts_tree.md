# Print a tree-sitter AST

Renders a
[`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) or
[`ts_node`](https://rundel.github.io/q2r/reference/ts_point.md) as an
indented tree.

## Arguments

- x:

  A [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) or
  [`ts_node`](https://rundel.github.io/q2r/reference/ts_point.md).

- position:

  If `TRUE`, include each node's start-end `(row, column)` point range
  in the label. Defaults to `FALSE`.

- text:

  If `TRUE` (the default), include the source-text snippet for leaf
  nodes that carry one.

- color:

  For `ts_tree`, whether to use ANSI colour when printing attached
  diagnostics. Defaults to whether the terminal supports it.

- ...:

  Unused; present for S3/S7 compatibility.

## Value

`x`, invisibly.
