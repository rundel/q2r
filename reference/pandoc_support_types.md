# Pandoc AST support types

Helper value types that appear inside concrete block and inline nodes:
attributes, ordered-list attributes, citations, captions,
definition-list items, and table cells/rows/columns. Each returns a
plain S7 object (these are not
[pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md)
subclasses).

## Usage

``` r
pandoc_attr(id = "", classes = character(0), attributes = character(0))

pandoc_list_attributes(start = 1L, style = "Decimal", delim = "Period")

pandoc_citation(
  id = "",
  mode = "NormalCitation",
  prefix = pandoc_inlines(list()),
  suffix = pandoc_inlines(list()),
  note_num = 0L,
  hash = 0L
)

pandoc_caption(short = NULL, long = pandoc_blocks(list()))

pandoc_definition_item(term = pandoc_inlines(list()), defs = list())

pandoc_col_spec(alignment = "Default", width = NULL)

pandoc_cell(
  attr = pandoc_attr(),
  alignment = "Default",
  row_span = 1L,
  col_span = 1L,
  content = pandoc_blocks(list())
)

pandoc_row(attr = pandoc_attr(), cells = list())
```

## Notes

For pandoc_caption, `short` is either `NULL` or a
[pandoc_inlines](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
and `long` is a
[pandoc_blocks](https://rundel.github.io/q2r/reference/pandoc_blocks.md).

## See also

[pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md),
[pandoc_block_constructors](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md),
[pandoc_inline_constructors](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
