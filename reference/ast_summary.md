# Tabular overview of a document's top-level blocks

**\[experimental\]**

## Usage

``` r
ast_summary(x, max_text = 40L)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
  document, a
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper, or a plain `list` of top-level blocks.

- max_text:

  Maximum width of the truncated `text` preview.

## Value

A `data.frame` with columns `type` (S7 class name), `level` (header
level or `NA`), `id` (`@attr@id` or `NA`), `section` (deepest enclosing
heading title, from
[`ast_sections()`](https://rundel.github.io/q2r/reference/ast_sections.md)),
`text` (truncated
[`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md)
preview), and `node` (a list-column of the block objects). The `node`
column displays as compact `<type>` placeholders but holds the live S7
objects for piping back through the verbs.

## Details

Returns a one-row-per-top-level-block `data.frame` summarising a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) document,
the analog of parsermd's `as_tibble.rmd_ast()`. It makes a document
graspable at a glance and bridges to base/dplyr filtering: the `node`
list-column holds the live S7 objects, so a filtered frame can be fed
straight back through the selection and mutation verbs.

The view is deliberately shallow (top-level blocks only) to mirror
parsermd's flat model; reach for
[`select_descendants()`](https://rundel.github.io/q2r/reference/select_nodes.md)
to inspect nested content.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("# A\n\nsome text\n\n## B\n\nmore\n")
ast_summary(doc)
} # }
```
