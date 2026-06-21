# Split a document into per-section sub-documents

**\[experimental\]**

## Usage

``` r
split_sections(x, level = 1L, ...)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
  document, a
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper, or a list of blocks.

- level:

  Heading level at which to split (default `1`). Headings at other
  levels stay inside their enclosing section.

- ...:

  Unused; for future extension.

## Value

A named `list` of
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) documents.
Names follow the heading text, so two headings sharing a title yield
repeated names; index by position to keep such sections distinct.

## Details

Partitions the top-level block stream of a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) document at
every heading of a given `level`, returning a named list of
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) documents
(one per section, named by the heading text), the q2r analog of mq's
`section::split()`. Any blocks before the first boundary heading become
a leading preamble document named `""`.

Each returned document can be rendered with
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md),
[`render_qmd()`](https://rundel.github.io/q2r/reference/render_qmd.md),
or written out; wrap the list in a
[`qmd_collection`](https://rundel.github.io/q2r/reference/qmd_collection.md)
if you want to run the batch verbs over it.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("intro\n\n# A\n\na\n\n# B\n\nb\n")
parts = split_sections(doc, level = 1)
names(parts)
} # }
```
