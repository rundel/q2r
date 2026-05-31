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
pandoc_plain(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_paragraph(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_line_block(source_info = pandoc_source_info(), content = list())

pandoc_code_block(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  text = ""
)

pandoc_raw_block(source_info = pandoc_source_info(), format = "", text = "")

pandoc_block_quote(
  source_info = pandoc_source_info(),
  content = pandoc_blocks(list())
)

pandoc_ordered_list(
  source_info = pandoc_source_info(),
  attr = pandoc_list_attributes(),
  content = list()
)

pandoc_bullet_list(source_info = pandoc_source_info(), content = list())

pandoc_definition_list(source_info = pandoc_source_info(), content = list())

pandoc_header(
  source_info = pandoc_source_info(),
  level = 1L,
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_horizontal_rule(source_info = pandoc_source_info())

pandoc_figure(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  caption = pandoc_caption(),
  content = pandoc_blocks(list())
)

pandoc_div(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_blocks(list())
)

pandoc_table(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  caption = pandoc_caption(),
  colspec = list(),
  head = pandoc_table_head(),
  bodies = list(),
  foot = pandoc_table_foot()
)

pandoc_block_metadata(
  source_info = pandoc_source_info(),
  meta = pandoc_meta_value()
)

pandoc_note_definition_para(
  source_info = pandoc_source_info(),
  id = "",
  content = pandoc_inlines(list())
)

pandoc_note_definition_fenced_block(
  source_info = pandoc_source_info(),
  id = "",
  content = pandoc_blocks(list())
)

pandoc_caption_block(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_custom_block(
  source_info = pandoc_source_info(),
  type_name = "",
  slots = list(),
  attr = pandoc_attr()
)
```

## See also

[pandoc_inline_constructors](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
[pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md),
[pandoc_support_types](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
