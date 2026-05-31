# Dump pampa's raw tree-sitter tree for QMD input

**\[experimental\]**

## Usage

``` r
pampa_tree(input)
```

## Arguments

- input:

  A single string, handled like
  [`pampa_parse_pd()`](https://rundel.github.io/q2r/reference/pampa_parse_pd.md).

## Value

A character vector of lines.

## Details

Test helper that returns the `print_whole_tree` lines pampa emits when
run with `-v`. Use
[`pampa_parse_ts()`](https://rundel.github.io/q2r/reference/pampa_parse_ts.md)
for a structured AST.
