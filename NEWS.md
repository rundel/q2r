# q2r (development version)

* First development version. Wraps the `pampa` Rust crate from
  [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto's QMD
  parser to R.
* `parse_qmd()` returns either a Pandoc AST (`pandoc`) or a tree-sitter AST
  (`ts_tree`), with structured parse diagnostics attached.
* `to_qmd()` renders an R-held AST back to QMD (Pandoc via pampa's writer,
  tree-sitter via byte recovery).
* A tidyselect-style query/rewrite vocabulary works across both ASTs:
  `select_nodes()`, `select_descendants()`, `select_children()`,
  `select_first()`, `walk_nodes()`, `map_nodes()`, `replace_nodes()`,
  `delete_nodes()`, `splice_nodes()`, `insert_before()`, `insert_after()`.
* Document-level helpers (`ast_summary()`, `ast_sections()`,
  `select_section()`, `ast_toc()`, `split_sections()`), code-cell helpers
  (`cell_options()`, `set_cell_options()`, `collect_code()`), table bridges
  (`as_df()`, `as_table()`), file I/O (`read_qmd()`, `write_qmd()`,
  `edit_qmd()`), multi-document collections (`parse_qmd_dir()`), and a
  tree-sitter query escape hatch (`ts_query()`).
