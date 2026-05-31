# Mark a value as "use as-is, do not descend" inside ast_filter()

**\[experimental\]**

## Usage

``` r
ast_skip(x)
```

## Arguments

- x:

  A pandoc node, or `NULL`.

## Value

A small marker object recognised by
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md).

## Details

Sentinel for use inside an
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
pre-order handler. When a handler returns `ast_skip(x)`, the walker
installs `x` at that position and stops descending into its children.
Equivalent to Pandoc Lua filters' `return el, false` under
`traverse = 'topdown'`.

Has no effect under the default post-order traversal (where descent has
already happened by the time a handler runs).

## See also

[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
