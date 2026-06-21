# Select the blocks belonging to a heading section

**\[experimental\]**

## Usage

``` r
select_section(x, path, levels = 1:6, include_heading = TRUE)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
  document, a
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper, or a plain `list` of top-level blocks.

- path:

  Character vector of glob patterns naming the heading chain to match,
  outermost first.

- levels:

  Integer vector of heading levels (1-6) that count as section
  boundaries. Defaults to all levels.

- include_heading:

  Whether to include the matched heading block itself in the result
  (default `TRUE`).

## Value

A `list` of blocks (consistent with
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)).
Wrap it in `pandoc(blocks = pandoc_blocks(result))` to render it with
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md).

## Details

Slices the contiguous run of top-level blocks introduced by a heading
whose title (and ancestor titles) match `path`. This is the Pandoc
analog of parsermd's `by_section()`: where
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
can find the
[`pandoc_header`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
node, `select_section()` returns the header together with everything
beneath it, up to the next heading of equal or higher level.

`path` is a character vector of glob patterns, outermost heading first,
matched against the enclosing-heading chain from
[`ast_sections()`](https://rundel.github.io/q2r/reference/ast_sections.md)
(collapsed to the non-`NA` levels selected by `levels`). A section
anchor matches when its collapsed heading chain has the same length as
`path` and each element glob-matches, so
`path = c("Results", "Model *")` selects each `Model *` subsection
nested directly under a `Results` heading. `levels` restricts only which
headings can *start* a selected section; a heading at or above the
matched heading's level still ends the section even when its own level
is excluded from `levels`.

Section membership depends on document order, which a per-node predicate
(evaluated on one node in isolation) cannot see; that is why this is a
dedicated verb rather than a `has_*()` mask helper.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("# Intro\n\na\n\n## Setup\n\nb\n\n# Other\n\nc\n")
select_section(doc, "Intro")
select_section(doc, c("Intro", "Setup"), include_heading = FALSE)
} # }
```
