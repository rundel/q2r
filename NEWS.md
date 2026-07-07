# q2r 0.0.0.9000

## Fixes and behavior changes (2026-07 review)

* `walk_nodes()` on a tree-sitter AST now works (it previously errored or
  silently mis-fired) and visits in pre-order (document order) on both ASTs.
* Mutation verbs applied to a whole `ts_tree` render and reparse the result,
  so chained mutations no longer corrupt inter-block whitespace, and
  `insert_before()`/`insert_after()`/`splice_nodes()` synthesize the
  separators needed to keep inserted blocks distinct on reparse.
* `write_qmd_dir()` aborts (override with `force = TRUE`) when a document in
  the collection carries error-kind parse diagnostics, instead of silently
  overwriting unparseable source; it also errors on colliding target
  basenames. `parse_qmd_dir(recurse = FALSE)` no longer picks up directories.
* S7 validators now reject out-of-range integers (negative list starts and
  cell spans, header levels outside 1-6), unknown enum strings (citation
  mode, alignments, list style/delim), malformed `pandoc_attr` values
  (non-scalar/NA ids, NA classes, unnamed or duplicate attributes),
  non-scalar single-string slots, and meta values whose shape does not match
  their kind - all of which previously crossed the FFI silently and
  corrupted output.
* Cell options round-trip safely: embedded newlines serialize as block
  scalars, backslashes are escaped, numeric-looking strings stay strings,
  `!expr` values keep their tag (and no longer leak a yaml warning), and
  `set_cell_options()` aborts on an unreadable option block instead of
  silently discarding it. Verbatim `` ```{{r}} `` cells are no longer
  treated as executable. Option lines now follow knitr's contract (`#| ` at
  line start only). CRLF cells stay CRLF. New setters: `set_cell_engine()`,
  `set_cell_code()`.
* Select predicates that return a non-scalar, non-logical, or NA result now
  warn (once per query) instead of silently dropping nodes;
  `has_option()` compares numeric values across integer/double.
* Figure/table captions and table head/foot are now reachable by the
  mutation verbs (replace or reset-to-empty). `ast_text()` includes quote
  marks for `pandoc_quoted`, matching pandoc's stringify.
* `has_id()`, `has_attr()`, `has_text()`, `has_label()`, `has_option()`,
  and `has_engine()` are now also exported as ordinary node-first functions.
* `as_df()` no longer produces garbage column names from empty header
  cells; `as_table()` formats numerics without scientific notation;
  `split_sections()` carries the document's frontmatter into every part;
  `pandoc_slug()` keeps unicode letters.
* The `pandoc_blocks` / `pandoc_inlines` / `ts_nodes` wrappers behave like
  lists (`length()`, `[[`, `[`, `as.list()`); pandoc-only verbs give a
  friendly error on a `ts_tree`; mutation verbs hint when `.f` / `.with` /
  `.what` is passed positionally.

## Initial version

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
