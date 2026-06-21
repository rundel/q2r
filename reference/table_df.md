# Convert between pandoc tables and data frames

**\[experimental\]**

## Usage

``` r
as_df(x, ...)

as_table(df, caption = NULL, align = NULL, id = "")
```

## Arguments

- x:

  A
  [`pandoc_table`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  (returns one `data.frame`), or a
  [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) /
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  / list of blocks (returns a list of `data.frame`s, one per table found
  in document order).

- df:

  A `data.frame` (or object coercible to one).

- caption:

  Table caption as a string, or `NULL` for none. Defaults to the
  `"q2r_caption"` attribute of `df` if present.

- align:

  Column alignments, one of `"left"`, `"right"`, `"center"`, or
  `"default"` per column (recycled to the number of columns). Defaults
  to the `"q2r_align"` attribute of `df`, else `"default"`.

- id:

  Table identifier (the Quarto `#tbl-` label). Defaults to the
  `"q2r_id"` attribute of `df`, else `""`.

## Value

`as_df()` returns a `data.frame` (or list thereof); `as_table()` returns
a
[`pandoc_table`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md).

## Details

Bridge the
[`pandoc_table`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
node and the data structure R users work in. `as_df()` flattens a parsed
table into a `data.frame` (the header row becomes column names, each
cell is rendered to plain text with
[`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md));
`as_table()` builds a
[`pandoc_table`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
from a `data.frame` so it can be spliced into a document and written
back with
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md). Together
they are the q2r analog of mq's `table::` module.

Column alignments, the table caption, and the table identifier ride
along on the returned `data.frame` as the attributes `"q2r_align"`,
`"q2r_caption"`, and `"q2r_id"`, and `as_table()` reads them back when
its own `align` / `caption` / `id` arguments are left at their defaults.
A `as_df()` then `as_table()` round trip therefore preserves alignment
and caption without extra bookkeeping.

Cells are reduced to plain text, so inline formatting (emphasis, links,
code) inside a cell is dropped. Cell row and column spans are not
modelled: each cell maps to exactly one column.

Only the first header row becomes the column names; any further header
rows and any body group-header rows are flattened into ordinary data
rows.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("| a | b |\n|--:|:--|\n| 1 | x |\n")
df = as_df(doc)[[1]]
as_table(df, caption = "demo")
} # }
```
