# Flatten a pandoc subtree to plain text

**\[experimental\]**

## Usage

``` r
ast_text(x, ...)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md),
  [`pandoc_node`](https://rundel.github.io/q2r/reference/pandoc_node.md),
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
  or list thereof.

## Value

A single character string.

## Details

Recursively concatenates the textual content of a pandoc AST, dropping
all formatting. The output of a
[`pampa_parse_pd()`](https://rundel.github.io/q2r/reference/pampa_parse_pd.md)
result fed back through `ast_text()` is roughly what readers would see
if the document were rendered as a flat string.

Equivalent in spirit to `pandoc.utils.stringify()` from Pandoc Lua
filters: handy for matching on document content (titles, captions, link
labels) without descending the AST manually.

Leaf rules:

- [`pandoc_str`](https://rundel.github.io/q2r/reference/pandoc_str.md),
  [`pandoc_code`](https://rundel.github.io/q2r/reference/pandoc_code.md),
  [`pandoc_math`](https://rundel.github.io/q2r/reference/pandoc_math.md),
  [`pandoc_raw_inline`](https://rundel.github.io/q2r/reference/pandoc_raw_inline.md),
  [`pandoc_raw_block`](https://rundel.github.io/q2r/reference/pandoc_raw_block.md),
  [`pandoc_code_block`](https://rundel.github.io/q2r/reference/pandoc_code_block.md)
  emit their `@text` slot.

- [`pandoc_space`](https://rundel.github.io/q2r/reference/pandoc_space.md)
  and
  [`pandoc_soft_break`](https://rundel.github.io/q2r/reference/pandoc_soft_break.md)
  emit a single space.

- [`pandoc_line_break`](https://rundel.github.io/q2r/reference/pandoc_line_break.md)
  emits a newline.

- [`pandoc_horizontal_rule`](https://rundel.github.io/q2r/reference/pandoc_horizontal_rule.md)
  emits a newline.

Container rules:

- Block containers
  ([`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md),
  [`pandoc_div`](https://rundel.github.io/q2r/reference/pandoc_div.md),
  [`pandoc_block_quote`](https://rundel.github.io/q2r/reference/pandoc_block_quote.md),
  list types, etc.) join children with two newlines.

- Inline containers
  ([`pandoc_emph`](https://rundel.github.io/q2r/reference/pandoc_emph.md),
  [`pandoc_strong`](https://rundel.github.io/q2r/reference/pandoc_strong.md),
  [`pandoc_link`](https://rundel.github.io/q2r/reference/pandoc_link.md),
  etc.) concatenate children without separator.

- [`pandoc_note`](https://rundel.github.io/q2r/reference/pandoc_note.md)
  emits its block content (joined with newlines) wrapped in `[^...]` to
  flag it; rarely useful in match logic.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = pampa_parse_pd("# Hello *world*\n\nSecond paragraph.\n")
ast_text(doc)
# "Hello world\n\nSecond paragraph."
} # }
```
