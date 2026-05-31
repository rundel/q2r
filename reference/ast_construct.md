# Coerce flexible input into pandoc_inlines or pandoc_blocks

**\[experimental\]**

## Usage

``` r
as_inlines(x)

as_blocks(x)
```

## Arguments

- x:

  A character vector, a single inline/block node, a list of nodes, or a
  `pandoc_inlines`/`pandoc_blocks` wrapper.

## Value

A
[`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
or
[`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
wrapper.

## Details

Smooth over the verbosity of pandoc constructors by accepting plain
strings, single nodes, lists of nodes, or already-wrapped sequences, and
producing the canonical wrapper type. Inspired by Pandoc Lua filters,
where constructors like `pandoc.Para("hi")` coerce strings to inline
sequences automatically.

For `as_inlines()`:

- A character vector is split on whitespace, producing
  [`pandoc_str`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  runs joined by
  [`pandoc_space()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md);
  embedded newlines (or multi-element character vectors) become
  [`pandoc_soft_break()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md).

- A single
  [`pandoc_inline`](https://rundel.github.io/q2r/reference/pandoc_node.md)
  is wrapped in
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md).

- A list is validated and wrapped.

- An existing
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  is returned as-is.

For `as_blocks()`:

- A character vector becomes one
  [`pandoc_paragraph`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  per non-empty element (each paragraph's content is
  `as_inlines(line)`).

- A single
  [`pandoc_block`](https://rundel.github.io/q2r/reference/pandoc_node.md)
  is wrapped in
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md).

- A list is validated and wrapped.

- An existing
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  is returned as-is.

These exist as ergonomic shortcuts for use inside
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
handlers and ad-hoc AST construction; the strict-typed constructors
([`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
[`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
[`pandoc_str`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
...) remain the canonical way to build nodes.

## Examples

``` r
if (FALSE) { # \dontrun{
pandoc_emph(content = as_inlines("hello world"))
as_blocks(c("first paragraph", "second paragraph"))
} # }
```
