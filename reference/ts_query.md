# Run a tree-sitter `.scm` query against QMD source

**\[experimental\]**

## Usage

``` r
ts_query(input, query_text)
```

## Arguments

- input:

  Either a
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md)
  (re-renders to QMD via
  [`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) then
  re-parses), a single string treated as text/file path (per
  [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md)'s
  rules), or raw text.

- query_text:

  A tree-sitter query string (S-expression form). See
  <https://github.com/quarto-dev/q2/tree/main/crates/tree-sitter-qmd/tree-sitter-markdown/queries/>
  for live examples.

## Value

A list with one element per match. Each match is itself a named list
whose names are the capture identifiers in `query_text` and whose values
are [`ts_node`](https://rundel.github.io/q2r/reference/ts_point.md)
objects. Returns [`list()`](https://rdrr.io/r/base/list.html) when no
matches are found.

## Details

Power-user escape hatch alongside
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md).
Compiles `query_text` against the tree-sitter-qmd grammar and returns
one entry per match, with captures keyed by name.

This bypasses the tidyselect-style mask entirely; use
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
if a CSS/predicate query is enough. `ts_query()` is the right tool when
you need full structural pattern matching, captures, or predicates
(`#eq?`, `#match?`, ...) from the tree-sitter query language.

## Examples

``` r
if (FALSE) { # \dontrun{
ts = parse_qmd("# Heading\n\nbody\n", ast = "ts")
ts_query(ts, "(atx_heading) @h")
} # }
```
