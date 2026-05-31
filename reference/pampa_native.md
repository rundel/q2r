# Render QMD input to Pandoc native AST text

**\[experimental\]**

## Usage

``` r
pampa_native(input)
```

## Arguments

- input:

  A single string, handled like
  [`pampa_parse()`](https://rundel.github.io/q2r/reference/pampa_parse.md).

## Value

A character vector of lines (empty if parsing failed).

## Details

Test helper that returns pampa's native-format rendering of the parsed
document.
