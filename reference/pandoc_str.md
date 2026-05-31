# Literal string

A `pandoc_str` is a maximal run of non-whitespace characters: Pandoc
represents spaces as
[pandoc_space](https://rundel.github.io/q2r/reference/pandoc_space.md)
and line breaks as
[pandoc_soft_break](https://rundel.github.io/q2r/reference/pandoc_soft_break.md)
/
[pandoc_line_break](https://rundel.github.io/q2r/reference/pandoc_line_break.md).
Embedding ASCII whitespace in `@text` would emit literal whitespace that
re-parses into separate inlines, so it is rejected.

## Usage

``` r
pandoc_str(source_info = pandoc_source_info(), text = "")
```
