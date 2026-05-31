# Print a Pandoc AST

Renders a [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
document or any individual
[`pandoc_node`](https://rundel.github.io/q2r/reference/pandoc_node.md)
(block or inline) as an indented tree.

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md),
  [`pandoc_node`](https://rundel.github.io/q2r/reference/pandoc_node.md),
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
  or
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  object.

- color:

  For `pandoc`, whether to use ANSI colour when printing attached
  diagnostics. Defaults to whether the terminal supports it.

- ...:

  Unused; present for S3/S7 compatibility.

## Value

`x`, invisibly.
