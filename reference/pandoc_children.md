# Children of a pandoc AST node for tree display

Generic returning a named list of child subtrees. A child may be a
`pandoc_node`, a `pandoc_blocks`/`pandoc_inlines` wrapper, or a plain
list of either (used for multi-item containers such as bullet lists).
`NULL` entries are skipped.

## Usage

``` r
pandoc_children(x, ...)
```

## Arguments

- x:

  An AST node.
