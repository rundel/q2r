# A collection of QMD documents

**\[experimental\]**

## Usage

``` r
qmd_collection(docs = list(), paths = character(0))

parse_qmd_dir(
  dir = ".",
  pattern = "\\.qmd$",
  recurse = TRUE,
  quiet = TRUE,
  prune_errors = TRUE
)

write_qmd_dir(x, dir = NULL)
```

## Arguments

- dir:

  For `parse_qmd_dir()`, the directory to scan. For `write_qmd_dir()`,
  the destination directory; `NULL` (the default) writes each document
  back to the path it was read from.

- pattern:

  A regular expression selecting files (default `"\\.qmd$"`).

- recurse:

  Whether to descend into subdirectories.

- quiet:

  Suppress per-file diagnostic signaling (default `TRUE`; diagnostics
  are still attached to each document's `@diagnostics`).

- prune_errors:

  Passed to
  [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md).

- x:

  A `qmd_collection`.

## Value

`parse_qmd_dir()` returns a `qmd_collection`. `write_qmd_dir()` returns
its input invisibly.

## Details

`qmd_collection` is a lightweight container holding several parsed
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) documents,
modeled on parsermd's document collections. It lets you parse a
directory of `.qmd` files once and then run the same selection and
rewriting verbs across every document in a single pipe.

The selection and mutation verbs from
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
dispatch on a collection:

- Selection verbs (`select_nodes`, `select_descendants`,
  `select_children`, `select_first`) map over the documents and return a
  named list of per-document results (so you keep track of which
  document each match came from).

- Mutation verbs (`map_nodes`, `replace_nodes`, `delete_nodes`,
  `splice_nodes`, `insert_before`, `insert_after`) rewrite every
  document and return a new `qmd_collection`.

- `walk_nodes` applies a side effect to every document and returns the
  collection invisibly.

- [`ast_summary()`](https://rundel.github.io/q2r/reference/ast_summary.md)
  returns a combined `data.frame` with a leading `doc` column naming the
  source document, and
  [`as_df()`](https://rundel.github.io/q2r/reference/table_df.md)
  returns a per-document named list of its tables.

The document-level helpers
([`ast_sections()`](https://rundel.github.io/q2r/reference/ast_sections.md),
[`ast_toc()`](https://rundel.github.io/q2r/reference/ast_toc.md),
[`select_section()`](https://rundel.github.io/q2r/reference/select_section.md),
[`split_sections()`](https://rundel.github.io/q2r/reference/split_sections.md),
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md))
are *not* collection-aware; map them over `@docs` yourself.

## Examples

``` r
if (FALSE) { # \dontrun{
coll = parse_qmd_dir("docs", pattern = "\\.qmd$")
coll |>
  map_nodes(is(pandoc_header), .f = \(h) add_class(h, "tagged")) |>
  write_qmd_dir("docs-tagged")
ast_summary(coll)
} # }
```
