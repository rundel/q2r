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
pandoc_str(text = "")

pandoc_emph(content = pandoc_inlines(list()))

pandoc_underline(content = pandoc_inlines(list()))

pandoc_strong(content = pandoc_inlines(list()))

pandoc_strikeout(content = pandoc_inlines(list()))

pandoc_superscript(content = pandoc_inlines(list()))

pandoc_subscript(content = pandoc_inlines(list()))

pandoc_small_caps(content = pandoc_inlines(list()))

pandoc_quoted(quote_type = "double", content = pandoc_inlines(list()))

pandoc_cite(citations = list(), content = pandoc_inlines(list()))

pandoc_code(attr = pandoc_attr(), text = "")

pandoc_space()

pandoc_soft_break()

pandoc_line_break()

pandoc_math(math_type = "inline", text = "")

pandoc_raw_inline(format = "", text = "")

pandoc_link(
  attr = pandoc_attr(),
  content = pandoc_inlines(list()),
  url = "",
  title = ""
)

pandoc_image(
  attr = pandoc_attr(),
  content = pandoc_inlines(list()),
  url = "",
  title = ""
)

pandoc_note(content = pandoc_blocks(list()))

pandoc_span(attr = pandoc_attr(), content = pandoc_inlines(list()))

pandoc_shortcode(
  name = "",
  is_escaped = FALSE,
  positional_args = list(),
  keyword_args = list()
)

pandoc_note_reference(id = "")

pandoc_attr_inline(attr = pandoc_attr())

pandoc_insert(attr = pandoc_attr(), content = pandoc_inlines(list()))

pandoc_delete(attr = pandoc_attr(), content = pandoc_inlines(list()))

pandoc_highlight(attr = pandoc_attr(), content = pandoc_inlines(list()))

pandoc_edit_comment(attr = pandoc_attr(), content = pandoc_inlines(list()))

pandoc_custom_inline(type_name = "", slots = list(), attr = pandoc_attr())
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
