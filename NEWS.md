# q2r 0.0.0.9000

## Upstream

* Pins `pampa` and `tree-sitter-qmd` to quarto-dev/q2 `4ecbd278` (v0.36.0), with `quarto-source-map` 0.3.0, `quarto-error-reporting` 0.4.0 and `quarto-yaml` 0.5.0 from crates.io.

## Fixes and behavior changes

* Deleting a block from a tree-sitter container no longer leaves a doubled blank line in `to_qmd()` output.
* `ast_text()` on a `pandoc_cite` flattens `@citations`, so `-@ref` and `[-@ref]` give the same text.
* Single-file `write_qmd()` / `edit_qmd()` and `write_qmd_dir()` refuse (override with `force = TRUE`) to overwrite documents that carry error-kind parse diagnostics; `has_error_diagnostics()` is exported.
* Parse failures are classed conditions (`q2r_parse_error` / `q2r_parse_warning`) carrying the structured diagnostics.
* Mid-document metadata blocks round-trip through `to_qmd()`.
* `format()` on a `pampa_diagnostic` no longer panics on malformed location offsets; `ts_query()` warns about predicates the matcher ignores.
* `walk_nodes()` works on a tree-sitter AST and visits in document order on both ASTs.
* Mutation verbs applied to a whole `ts_tree` render and reparse the result, so chained mutations keep inter-block whitespace intact, and `insert_before()` / `insert_after()` / `splice_nodes()` synthesize the separators needed to keep inserted blocks distinct.
* `parse_qmd_dir(recurse = FALSE)` no longer picks up directories; `write_qmd_dir()` errors on colliding target basenames.
* S7 validators reject out-of-range integers, unknown enum strings, malformed `pandoc_attr` values and mis-shaped meta values instead of letting them cross the FFI.
* Cell options round-trip safely (block scalars, escapes, numeric-looking strings, `!expr` tags); option lines follow knitr's `#| ` contract; CRLF cells stay CRLF. New setters: `set_cell_engine()`, `set_cell_code()`.
* Select predicates that return a non-scalar, non-logical or NA result warn once per query instead of silently dropping nodes.
* Figure and table captions and table head/foot are reachable by the mutation verbs; `ast_text()` includes quote marks for `pandoc_quoted`.
* `has_id()`, `has_attr()`, `has_text()`, `has_label()`, `has_option()` and `has_engine()` are also exported as node-first functions.
* `as_df()` handles empty header cells; `as_table()` avoids scientific notation; `split_sections()` carries frontmatter into every part; `pandoc_slug()` keeps unicode letters.
* The `pandoc_blocks` / `pandoc_inlines` / `ts_nodes` wrappers behave like lists; pandoc-only verbs give a friendly error on a `ts_tree`.

## Initial version

* First development version. Wraps the `pampa` Rust crate from [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto's QMD parser to R.
* `parse_qmd()` returns either a Pandoc AST (`pandoc`) or a tree-sitter AST (`ts_tree`), with structured parse diagnostics attached.
* `to_qmd()` renders an R-held AST back to QMD (Pandoc via pampa's writer, tree-sitter via byte recovery).
* A tidyselect-style query/rewrite vocabulary works across both ASTs: `select_nodes()`, `select_descendants()`, `select_children()`, `select_first()`, `walk_nodes()`, `map_nodes()`, `replace_nodes()`, `delete_nodes()`, `splice_nodes()`, `insert_before()`, `insert_after()`.
* Document-level helpers (`ast_summary()`, `ast_sections()`, `select_section()`, `ast_toc()`, `split_sections()`), code-cell helpers (`cell_options()`, `set_cell_options()`, `collect_code()`), table bridges (`as_df()`, `as_table()`), file I/O (`read_qmd()`, `write_qmd()`, `edit_qmd()`), multi-document collections (`parse_qmd_dir()`), and a tree-sitter query escape hatch (`ts_query()`).
