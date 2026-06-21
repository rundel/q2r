# Heading-section path for each top-level block

**\[experimental\]**

## Usage

``` r
ast_sections(x, ...)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
  document, a
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper, or a plain `list` of top-level blocks.

## Value

A `list` with one element per top-level block, each a named character
vector `c(h1, h2, h3, h4, h5, h6)` with `NA` where no heading at that
level is in scope.

## Details

Walks the top-level block stream of a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) document
and, for each block, reports the chain of enclosing
[`pandoc_header`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
titles. Because the Pandoc block list is flat (headings are siblings of
the content they introduce, not parents of it), this is the piece of
structure that q2r does not otherwise expose. It is the analog of
parsermd's `rmd_node_sections()` and the basis for
[`select_section()`](https://rundel.github.io/q2r/reference/select_section.md).

Each block is assigned a length-6 named character vector (`h1`..`h6`). A
header is considered part of the section it opens, so a level-2 header
`## Methods` carries `h2 = "Methods"` itself and resets any deeper
(`h3`..`h6`) entries. Heading titles are the flattened text of the
header
([`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("# A\n\nintro\n\n## B\n\nbody\n")
ast_sections(doc)
} # }
```
