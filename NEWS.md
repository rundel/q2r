# q2r 0.0.0.9000

## Upstream sync

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `10e16e0c` (211
  commits after v0.32.0: bd-an9gkxnp, bd-star-as-str-qigl02pz,
  bd-bare-at-literal-w3ytmu8e, bd-angle-bracket-u27e8, bd-nycn85a8,
  bd-html-element-runaway-k1eo50h8, bd-ieldbghj; quarto-source-map 0.3.0,
  quarto-error-reporting 0.3.2). Block-level editorial marks `::: ++` /
  `::: --` / `::: >>` / `::: !!` now parse: on the pandoc path as a
  `pandoc_div` whose first class is `quarto-insert` / `quarto-delete` /
  `quarto-edit-comment` / `quarto-highlight` followed by the user's own
  attributes, on the tree-sitter path as a new `editorial_div` node with an
  `insert_delimiter` / `delete_delimiter` / `edit_comment_delimiter` /
  `highlight_delimiter` leaf. `to_qmd()` writes any div whose first class is
  one of the four with the block marker, so `::: {.quarto-delete .x}`
  canonicalizes to `::: -- {.x}`; a bare div info string may no longer start
  with `-` (`::: --foo` raises the new Q-2-53). Whitespace-adjacent `*` `_`
  `~` `^` runs (`a * b`, `~5`, `2^10`), a bare or word-internal `@` (`a @ b`,
  `user@example.com`), every non-ASCII punctuation or symbol character
  (`⟨hunk⟩`, `「引用」`), and a `<` that cannot start a tag (`<6.1`, `<-`,
  `<5>`) now parse as `pandoc_str` instead of raising a parse error, and
  `to_qmd()` escapes them (`a \* b`, `a \@ b`, `\<5\>`). A tag candidate no
  longer crosses a blank line, a backtick run inside a code span no longer
  closes it early (`` `x``y` `` is one `pandoc_code`), and a literal token
  at the start of an ATX heading no longer leaves a leading `pandoc_space`.
  Because `~a b~` no longer reads back as a subscript, `to_qmd()` writes
  every space or soft break inside a `pandoc_subscript` / `pandoc_superscript`
  as `\ `, which re-reads as a no-break space. `Smith@{key}` now raises
  Q-2-41 instead of reading as a str plus a braced citation.

* The tree-sitter rebuild path now takes the junction separator for siblings
  created by `insert_before()` / `insert_after()` / `splice_nodes()` from the
  gaps on either side of the anchor child instead of the container's first
  inter-child gap, so a block inserted into an `editorial_div` (whose opener
  `::: ++ {.x}` has a lone space between its first two tokens) gets its
  blank-line boundary instead of being glued onto the previous paragraph.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `c406ce5c` (v0.32.0,
  bd-t7i6oanu / bd-khect2gq / bd-w0x91nmh, quarto-source-map 0.2.0,
  quarto-error-reporting 0.3.0). The reader no longer dumps the concrete
  syntax tree on every parse and folds its nesting-depth guard into the
  conversion walk, so `parse_qmd()` is cheaper and holds up to deeper
  nesting before the R stack runs out. The set of accepted documents is
  unchanged (a concrete tree deeper than 99 nodes is still rejected with
  Q-0-99), but that diagnostic now reads "too deeply nested (more than 99
  levels)" instead of quoting the measured depth against 100. No AST or
  `to_qmd()` change.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `890b3755` (q2#672).
  Unicode format characters (zero width space, soft hyphen, bidi marks and
  controls, word joiner, the MathML invisible operators, U+FEFF, and the rest
  of category Cf) now parse raw in prose on both ASTs instead of raising a
  parse error, and `to_qmd()` spells them as character references (the
  preferred WHATWG name such as `&ZeroWidthSpace;` or `&shy;`, otherwise
  `&#xXXXX;`); ZWNJ / ZWJ still parse and write raw. `to_qmd()` also escapes
  a literal `&` that would lex as a named or numeric character reference, so
  a `str` holding `&copy;` writes as `\&copy;` and re-reads as text rather
  than as `©`; `AT&T` and `a & b` are untouched.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `c1d23393`. A `---`
  inside a YAML frontmatter value no longer truncates the metadata: every
  later key survives in `@meta`, a quoted `"a --- b"` no longer raises
  Q-0-99, and an em dash in a frontmatter string (which `to_qmd()` spells
  `---`) now round-trips. On the tree-sitter AST the `metadata` node gains a
  `yaml` child (field `body`) holding the YAML between the delimiters; the
  delimiter lines stay hidden, so `metadata` keeps its verbatim `@text` and
  `to_qmd()` still reproduces the block byte for byte. Editing that `yaml`
  leaf with the mutation verbs rewrites the frontmatter, and `ts_query()`
  can capture it as `(metadata body: (yaml) @body)`.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `5a12a773` (past the
  v0.30.0 tag). None of the crates q2r links changed in this range, so
  `parse_qmd()`, `to_qmd()`, and the diagnostic surface are unchanged; the
  bump only restamps the git-sourced q2 crates to 0.30.0 in `Cargo.lock`.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `b7e7c96a`. A
  paragraph opening with a block-level raw HTML tag is now split rather than
  kept verbatim: runs of block tags become one `pandoc_raw_block` joined by
  newlines and the prose between them parses as a `pandoc_plain` with full
  inline markup, so a tight `<div>` around a line of prose yields three
  blocks and an HTML comment followed by text on the same line yields two.
  `<pre>`, `<script>`, `<style>`, and `<textarea>` stay one verbatim raw
  block. `to_qmd()` writes block-level raw HTML (tag runs, raw-text
  elements, comments) bare instead of inside a `{=html}` fence and keeps the
  fence for anything else. Because blocks are written blank-line separated, a
  split interior re-reads as a `pandoc_paragraph`; the shape is stable from
  the first write on. Known upstream regression: an authored `{=html}` fence
  around a `<style>` or `<script>` element is also written bare, and when its
  content contains braces the output does not re-parse.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `914f2069` (v0.29.0).
  A paragraph that opens with a block-level raw HTML tag (`<div>`,
  `<details>`, `<pre>`, an HTML comment, ...) now parses as a
  `pandoc_raw_block` holding the paragraph verbatim instead of a paragraph of
  `pandoc_raw_inline`s, and `to_qmd()` writes an HTML-comment raw block
  natively rather than as a `{=html}` fence. Fenced-div openers with no space
  after the colons (`:::{.foo}`, `:::foo`) now parse on both ASTs. A
  shortcode delimiter missing its space is reported as a single Q-2-52 error
  that suppresses any later diagnostics (with a hint saying so), and Q-2-50
  also fires on a doubled-brace opener nested inside a display fence.

* The pins between `65a888b0` and `914f2069` (`1ba0f2ec`, `f8df9521`,
  `fdf55e77`, `596ceb57`, `eda49bc4`) also changed what `parse_qmd()` and
  `to_qmd()` produce. Reserved `id=` / `class=` key-value attributes are
  promoted into the id and class slots (a later `id=` overrides `#id`), and
  an id the `#id` shorthand cannot spell writes back as `id="..."`. Values
  under `brand:` in front matter arrive as plain `string` scalars rather than
  markdown inlines, so `brand: _brand.yml` no longer warns. A metadata value
  that fails to parse as markdown (Q-1-20) now carries the child parse's
  diagnostics as located details. Naked shortcode values accept backslash
  escapes, non-ASCII, `*`, `^`, and `|`, with a decoded `>` written back
  quoted. A braced language with extra classes writes as `{python .marimo}`.
  `...` is an ellipsis at every position, `--` / `---` and straight quotes
  canonicalize on read and write, adjacent footnote definitions no longer
  merge, named entities decode in prose (a decoded `"` writes back as `\"`),
  and `<user@example.com>` parses as a mailto link with the `email` class.
  Literal braces raise Q-2-41 inside emphasis, strong, quotes, superscript,
  and pipe-table cells as well as in plain prose.

* Pinned `pampa` / `tree-sitter-qmd` to quarto-dev/q2 `65a888b0`, which adds
  GFM task lists. A `- [ ]` / `- [x]` list item now parses with a ballot-box
  `pandoc_str` (`"☐"` / `"☒"`) and a space at the head of its first
  paragraph, so `ast_text()` on such an item includes that prefix; `to_qmd()`
  writes the bracket syntax back. On the tree-sitter side the markers are
  named leaves (`task_list_marker_checked` / `task_list_marker_unchecked`).

## Fixes and behavior changes

* `ast_text()` on a `pandoc_cite` now always flattens `@citations` (prefix,
  `@id` or `-@id` for a suppress-author citation, suffix) and ignores
  `@content`. pampa fills `@content` with the source text for an in-text
  citation (`-@ref`) but leaves it empty for a bracketed one (`[-@ref]`), so
  the text of a citation used to depend on which spelling the author chose:
  `-@ref` gave `-@ref` while `[-@ref]` gave `@ref`. Both now give `-@ref`,
  and `has_text()` / `ast_summary()` see the same text after a `to_qmd()`
  round trip, which canonicalizes the bare form to `[-@ref]`. An R-built
  citation with no `@citations` still falls back to its `@content`.

## Fixes and behavior changes (2026-07 review)

* Follow-up review fixes: single-file `write_qmd()` / `edit_qmd()` now refuse
  (override with `force = TRUE`) to overwrite documents that carry error-kind
  parse diagnostics, and `has_error_diagnostics()` is exported. Mid-document
  metadata blocks (`pandoc_block_metadata`) now round-trip through `to_qmd()`
  with their payload instead of erroring on a cleanly parsed document.
  `format()` on a `pampa_diagnostic` no longer panics on inverted or
  mid-character location offsets and accepts double-valued offsets.
  `ts_query()` warns about predicates the matcher ignores. Parse failures are
  now classed conditions (`q2r_parse_error` / `q2r_parse_warning`) carrying
  the structured diagnostics (and, for errors, the parsed object in
  `$result`). `to_qmd()` renders `ts_nodes` wrappers and lists of `ts_node`
  element-wise. Wrapper `[` subscripts out of range now error clearly, and
  `parse_qmd()` input mistakes (vectors of lines, NA) get friendly messages.

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
