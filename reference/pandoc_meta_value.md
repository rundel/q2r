# Pandoc meta / config value

Pandoc meta / config value

## Usage

``` r
pandoc_meta_value(kind = "map", value = list())

pandoc_config_value(kind = "map", value = list())
```

## Arguments

- kind:

  The value kind, one of `"string"`, `"int"`, `"real"`, `"bool"`,
  `"null"`, `"inlines"`, `"blocks"`, `"list"`, `"map"`, `"path"`,
  `"glob"`, or `"expr"`.

- value:

  The payload, whose R type depends on `kind` (a scalar for the scalar
  kinds, a named list for `"map"`, an unnamed list for `"list"`, a
  [pandoc_inlines](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  /
  [pandoc_blocks](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  for those kinds).
