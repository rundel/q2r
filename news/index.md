# Changelog

## q2r (development version)

- First development version. Wraps the `pampa` Rust crate from
  [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto’s
  QMD parser to R.
- [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md)
  returns either a Pandoc AST (`pandoc`) or a tree-sitter AST
  (`ts_tree`), with structured parse diagnostics attached.
- [`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) renders
  an R-held AST back to QMD (Pandoc via pampa’s writer, tree-sitter via
  byte recovery).
- A tidyselect-style query/rewrite vocabulary works across both ASTs:
  [`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`select_descendants()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`select_children()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`select_first()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`walk_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`replace_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`delete_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`splice_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`insert_before()`](https://rundel.github.io/q2r/reference/select_nodes.md),
  [`insert_after()`](https://rundel.github.io/q2r/reference/select_nodes.md).
- Document-level helpers
  ([`ast_summary()`](https://rundel.github.io/q2r/reference/ast_summary.md),
  [`ast_sections()`](https://rundel.github.io/q2r/reference/ast_sections.md),
  [`select_section()`](https://rundel.github.io/q2r/reference/select_section.md),
  [`ast_toc()`](https://rundel.github.io/q2r/reference/ast_toc.md),
  [`split_sections()`](https://rundel.github.io/q2r/reference/split_sections.md)),
  code-cell helpers
  ([`cell_options()`](https://rundel.github.io/q2r/reference/code_cell.md),
  [`set_cell_options()`](https://rundel.github.io/q2r/reference/code_cell.md),
  [`collect_code()`](https://rundel.github.io/q2r/reference/code_cell.md)),
  table bridges
  ([`as_df()`](https://rundel.github.io/q2r/reference/table_df.md),
  [`as_table()`](https://rundel.github.io/q2r/reference/table_df.md)),
  file I/O
  ([`read_qmd()`](https://rundel.github.io/q2r/reference/read_qmd.md),
  [`write_qmd()`](https://rundel.github.io/q2r/reference/read_qmd.md),
  [`edit_qmd()`](https://rundel.github.io/q2r/reference/read_qmd.md)),
  multi-document collections
  ([`parse_qmd_dir()`](https://rundel.github.io/q2r/reference/qmd_collection.md)),
  and a tree-sitter query escape hatch
  ([`ts_query()`](https://rundel.github.io/q2r/reference/ts_query.md)).
