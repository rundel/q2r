# Inline constructors

Constructors for the concrete Pandoc inline node classes. Each returns
an S7 object extending
[pandoc_inline](https://rundel.github.io/q2r/reference/pandoc_node.md).
See [pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md)
for the abstract hierarchy and
[pandoc_block_constructors](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
for the block-level nodes.

## Usage

``` r
pandoc_str(source_info = pandoc_source_info(), text = "")

pandoc_emph(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_underline(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_strong(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_strikeout(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_superscript(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_subscript(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_small_caps(
  source_info = pandoc_source_info(),
  content = pandoc_inlines(list())
)

pandoc_quoted(
  source_info = pandoc_source_info(),
  quote_type = "double",
  content = pandoc_inlines(list())
)

pandoc_cite(
  source_info = pandoc_source_info(),
  citations = list(),
  content = pandoc_inlines(list())
)

pandoc_code(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  text = ""
)

pandoc_space(source_info = pandoc_source_info())

pandoc_soft_break(source_info = pandoc_source_info())

pandoc_line_break(source_info = pandoc_source_info())

pandoc_math(
  source_info = pandoc_source_info(),
  math_type = "inline",
  text = ""
)

pandoc_raw_inline(source_info = pandoc_source_info(), format = "", text = "")

pandoc_link(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list()),
  url = "",
  title = ""
)

pandoc_image(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list()),
  url = "",
  title = ""
)

pandoc_note(
  source_info = pandoc_source_info(),
  content = pandoc_blocks(list())
)

pandoc_span(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_shortcode(
  source_info = pandoc_source_info(),
  name = "",
  is_escaped = FALSE,
  positional_args = list(),
  keyword_args = list()
)

pandoc_note_reference(source_info = pandoc_source_info(), id = "")

pandoc_attr_inline(source_info = pandoc_source_info(), attr = pandoc_attr())

pandoc_insert(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_delete(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_highlight(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_edit_comment(
  source_info = pandoc_source_info(),
  attr = pandoc_attr(),
  content = pandoc_inlines(list())
)

pandoc_custom_inline(
  source_info = pandoc_source_info(),
  type_name = "",
  slots = list(),
  attr = pandoc_attr()
)
```

## Notes

`pandoc_str()` holds a maximal run of non-whitespace characters: Pandoc
represents spaces as pandoc_space and line breaks as pandoc_soft_break /
pandoc_line_break. Embedding ASCII whitespace in `@text` would emit
literal whitespace that re-parses into separate inlines, so it is
rejected.

`pandoc_shortcode()` carries `positional_args` and `keyword_args` as
lists of arg records. Each arg record is a list with `kind` ∈
`"string"`, `"number"`, `"boolean"`, `"shortcode"`, `"kv"`,
`"kv_group"`. `string`/`number`/`boolean` carry a `value`; `shortcode`
carries a nested `pandoc_shortcode` in `value`; `kv` carries `key`
(character) and `value` (another arg record); `kv_group` carries `value`
as a list of `kv` records (used for positional KeyValue bundles).

## See also

[pandoc_block_constructors](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md),
[pandoc_node](https://rundel.github.io/q2r/reference/pandoc_node.md),
[pandoc_support_types](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
