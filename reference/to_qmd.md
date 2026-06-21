# Render an R-side AST back to QMD text

**\[experimental\]**

## Usage

``` r
to_qmd(x, ...)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md),
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md), or
  [`ts_node`](https://rundel.github.io/q2r/reference/ts_point.md)
  object.

## Value

A single string with the rendered QMD.

## Details

`to_qmd()` is the single entry point for turning an R-held AST back into
QMD source text. Two top-level methods are defined:

- `to_qmd(pandoc)` rebuilds pampa's `Pandoc` value in Rust from the
  tagged-list shape produced by `pandoc_to_list()` and runs
  `pampa::writers::qmd::write` on it. Pampa is the sole source of truth
  for QMD writing.

- `to_qmd(ts_tree)` recovers source bytes by walking the tree-sitter AST
  and falling back to each node's `@text` slot where children don't
  cover all of the parent's bytes (grammar gaps). This is byte-recovery,
  not "writing" - a tree-sitter AST already represents source bytes, and
  pampa exposes no public `ts_ast -> Pandoc` conversion that we could
  invoke independently of its reader.

On the pandoc side only whole-document dispatch is supported: there is
no method for an individual block or inline (wrap a fragment in a
minimal `pandoc` and route it through pampa). The tree-sitter side is
pure byte-recovery, so it also dispatches on a single
[`ts_node`](https://rundel.github.io/q2r/reference/ts_point.md).
