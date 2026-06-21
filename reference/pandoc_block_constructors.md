# Block constructors

Constructors for the concrete Pandoc block-level node classes. Each
returns an S7 object extending
[pandoc_block](https://rundel.github.io/q2r/reference/pandoc_node.md).
See [pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md)
for the abstract hierarchy and
[pandoc_inline_constructors](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
for the inline nodes.

## Usage

``` r
pandoc_plain(content = pandoc_inlines(list()))

pandoc_paragraph(content = pandoc_inlines(list()))

pandoc_line_block(content = list())

pandoc_code_block(attr = pandoc_attr(), text = "")

pandoc_raw_block(format = "", text = "")

pandoc_block_quote(content = pandoc_blocks(list()))

pandoc_ordered_list(attr = pandoc_list_attributes(), content = list())

pandoc_bullet_list(content = list())

pandoc_definition_list(content = list())

pandoc_header(
  level = 1L,
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_horizontal_rule()

pandoc_figure(
  attr = pandoc_attr(),
  caption = pandoc_caption(),
  content = pandoc_blocks(list())
)

pandoc_div(attr = pandoc_attr(), content = pandoc_blocks(list()))

pandoc_table(
  attr = pandoc_attr(),
  caption = pandoc_caption(),
  colspec = list(),
  head = pandoc_table_head(),
  bodies = list(),
  foot = pandoc_table_foot()
)

pandoc_block_metadata(meta = pandoc_meta_value())

pandoc_note_definition_para(id = "", content = pandoc_inlines(list()))

pandoc_note_definition_fenced_block(id = "", content = pandoc_blocks(list()))

pandoc_caption_block(content = pandoc_inlines(list()))

pandoc_custom_block(type_name = "", slots = list(), attr = pandoc_attr())
```

## Notes

`pandoc_block_metadata()` is parse-only and lossy: the reader never
populates its `@meta` slot (it stays the empty default) and pampa's
writer does not emit it, so it round-trips as an empty node. The slot is
kept for forward compatibility.

## See also

[pandoc_inline_constructors](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
[pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md),
[pandoc_support_types](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
