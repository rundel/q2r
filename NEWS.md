# q2r 0.0.0.9000

* Initial development version, wrapping the `pampa` Rust crate from [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto's QMD parser to R. Pins q2 at `4ecbd278` (v0.36.0).
* `parse_qmd()` returns a Pandoc AST (`pandoc`) or a tree-sitter AST (`ts_tree`), with parse diagnostics attached and signalled as `q2r_parse_error` / `q2r_parse_warning` conditions.
* `to_qmd()` renders either AST back to QMD source.
* Query and rewrite verbs that work on both ASTs: `select_nodes()`, `select_descendants()`, `select_children()`, `select_first()`, `walk_nodes()`, `map_nodes()`, `replace_nodes()`, `delete_nodes()`, `splice_nodes()`, `insert_before()`, `insert_after()`, plus the Lua-filter-style `ast_filter()`.
* Document helpers: `ast_summary()`, `ast_sections()`, `select_section()`, `ast_toc()`, `split_sections()`, `ast_text()`, and attribute accessors such as `get_attr()` / `set_attr()` / `has_class()`.
* Code-cell helpers (`cell_options()`, `set_cell_options()`, `set_cell_engine()`, `set_cell_code()`, `collect_code()`) and table bridges (`as_df()`, `as_table()`).
* File and collection I/O: `read_qmd()`, `write_qmd()`, `edit_qmd()`, `parse_qmd_dir()`, `write_qmd_dir()`, and `render_qmd()`. Writers refuse to overwrite documents with parse errors unless `force = TRUE`.
* `ts_query()` runs a tree-sitter `.scm` query against a document.
