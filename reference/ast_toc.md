# Build a table of contents from a document's headings

**\[experimental\]**

## Usage

``` r
ast_toc(x, max_level = 3L, ...)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
  document, a
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper, or a list of blocks.

- max_level:

  Deepest heading level to include (default `3`).

- ...:

  Unused; for future extension.

## Value

A
[`pandoc_bullet_list`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
block (empty when there are no qualifying headings).

## Details

Walks the headings of a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) document in
order and returns a nested
[`pandoc_bullet_list`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
linking to each one, the q2r analog of mq's `section::toc()`. The result
is an ordinary block, so it can be spliced into the document with
[`insert_after()`](https://rundel.github.io/q2r/reference/select_nodes.md)
or wrapped in a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) and
rendered with
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md).

Each entry links to the heading's explicit identifier (`@attr@id`) when
it has one; otherwise an approximate Pandoc-style slug of the heading
text is used. Headings deeper than `max_level` are omitted.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("# A\n\n## B\n\ntext\n\n# C\n")
toc = ast_toc(doc)
doc |> insert_before(is(pandoc_header), .what = toc)
} # }
```
