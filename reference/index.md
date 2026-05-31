# Package index

## Parsing and rendering

Convert between QMD text/files and q2r’s two AST representations, and
render an AST back to QMD source.

- [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md)
  **\[experimental\]** : Parse QMD input with pampa
- [`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md)
  **\[experimental\]** : Render an R-side AST back to QMD text

## Diagnostics

Structured parse diagnostics emitted by the reader, plus the lazy text
renderer used by [`print()`](https://rdrr.io/r/base/print.html) /
[`format()`](https://rdrr.io/r/base/format.html).

- [`pampa_diagnostic()`](https://rundel.github.io/q2r/reference/pampa_diagnostic.md)
  : Parse diagnostic produced by the pampa parser

## Querying and rewriting the AST

A predicate-driven query/rewrite vocabulary shared across both the
Pandoc S7 AST and the tree-sitter AST.

### Locating nodes

tidyselect-style verbs for locating nodes by predicate. Predicates are
unquoted expressions evaluated against a per-node data mask that exposes
slot names and helpers (`is()`,
[`has_class()`](https://rundel.github.io/q2r/reference/ast_attr.md),
`has_id()`, `has_attr()`, `is_leaf()`, …).

- [`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`select_descendants()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`select_children()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`select_first()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`walk_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`replace_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`delete_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`splice_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`insert_before()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`insert_after()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  **\[experimental\]** : Select, filter, and rewrite nodes in a Pandoc
  or tree-sitter AST

### Mutating nodes

Predicate-driven mutation verbs. Each return value is a node, a list of
nodes (splice), or `NULL` (delete). The walker is post-order, matching
Pandoc Lua filters’ default.

- [`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`select_descendants()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`select_children()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`select_first()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`walk_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`replace_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`delete_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`splice_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`insert_before()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  [`insert_after()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  **\[experimental\]** : Select, filter, and rewrite nodes in a Pandoc
  or tree-sitter AST

### Filter-table rewriting (Lua-filter-style)

[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
rewrites multiple node types in one pass using a table of S7-class-keyed
handlers, with optional top-down traversal and list-level dispatch on
`pandoc_inlines` / `pandoc_blocks`.
[`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md)
flattens a subtree to plain text.

- [`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
  **\[experimental\]** : Apply a table of type-keyed handlers to a
  pandoc AST
- [`ast_skip()`](https://rundel.github.io/q2r/reference/ast_skip.md)
  **\[experimental\]** : Mark a value as "use as-is, do not descend"
  inside ast_filter()
- [`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md)
  **\[experimental\]** : Flatten a pandoc subtree to plain text

## Attribute helpers

Concise immutable getters and setters for the `@attr` slot (id, classes,
key-value attributes) found on headers, divs, code, links, spans, and
friends.

- [`has_class()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`add_class()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`remove_class()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`get_id()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`set_id()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`get_attr()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`set_attr()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  [`remove_attr()`](https://rundel.github.io/q2r/reference/ast_attr.md)
  **\[experimental\]** : Attribute manipulation helpers

## Constructing content

Ergonomic coercion helpers that accept strings, single nodes, or lists
and produce the canonical `pandoc_inlines` / `pandoc_blocks` wrappers.

- [`as_inlines()`](https://rundel.github.io/q2r/reference/ast_construct.md)
  [`as_blocks()`](https://rundel.github.io/q2r/reference/ast_construct.md)
  **\[experimental\]** : Coerce flexible input into pandoc_inlines or
  pandoc_blocks

## Tree-sitter queries

Raw tree-sitter `.scm` query escape hatch with capture support, for
cases where the predicate API is not expressive enough.

- [`ts_query()`](https://rundel.github.io/q2r/reference/ts_query.md)
  **\[experimental\]** :

  Run a tree-sitter `.scm` query against QMD source

## Pandoc AST

The S7 class hierarchy returned by
[`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md)
(the default `ast = "pd"`) and accepted by
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md).

### Root and abstract classes

`pandoc` is the document root and `pandoc_node` the common ancestor for
every concrete node (with the abstract `pandoc_block` / `pandoc_inline`
parents). `pandoc_blocks` / `pandoc_inlines` are the strict-typed list
wrappers used in content slots. `pandoc_children` /
`pandoc_format_label` are the generics behind the tree display, which
`print.pandoc` documents.

- [`pandoc()`](https://rundel.github.io/q2r/reference/pandoc.md) :
  Top-level Pandoc document
- [`pandoc_node()`](https://rundel.github.io/q2r/reference/pandoc_node.md)
  [`pandoc_block()`](https://rundel.github.io/q2r/reference/pandoc_node.md)
  [`pandoc_inline()`](https://rundel.github.io/q2r/reference/pandoc_node.md)
  : Virtual parent classes
- [`pandoc_blocks()`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  [`pandoc_inlines()`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  : Typed list wrappers
- [`pandoc_children()`](https://rundel.github.io/q2r/reference/pandoc_children.md)
  : Children of a pandoc AST node for tree display
- [`pandoc_format_label()`](https://rundel.github.io/q2r/reference/pandoc_format_label.md)
  : Label a pandoc AST node for tree display
- [`print.pandoc`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  [`print.pandoc_node`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  [`print.pandoc_blocks`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  [`print.pandoc_inlines`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  : Print a Pandoc AST

### Block constructors

Constructors for the concrete block-level node classes, collected on a
single page (one alias and usage entry per constructor).

- [`pandoc_plain()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_paragraph()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_line_block()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_code_block()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_raw_block()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_block_quote()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_ordered_list()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_bullet_list()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_definition_list()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_header()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_horizontal_rule()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_figure()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_div()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_table()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_block_metadata()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_note_definition_para()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_note_definition_fenced_block()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_caption_block()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  [`pandoc_custom_block()`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  : Block constructors

### Inline constructors

Constructors for the concrete inline node classes, collected on a single
page (one alias and usage entry per constructor).

- [`pandoc_str()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_emph()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_underline()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_strong()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_strikeout()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_superscript()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_subscript()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_small_caps()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_quoted()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_cite()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_code()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_space()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_soft_break()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_line_break()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_math()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_raw_inline()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_link()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_image()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_note()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_span()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_shortcode()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_note_reference()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_attr_inline()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_insert()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_delete()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_highlight()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_edit_comment()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  [`pandoc_custom_inline()`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md)
  : Inline constructors

### Support types

Helper types that appear inside concrete nodes: attributes, table
substructures, citations, captions, metadata.

- [`pandoc_source_info()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_attr()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_list_attributes()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_citation()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_caption()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_definition_item()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_col_spec()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_cell()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  [`pandoc_row()`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
  : Pandoc AST support types
- [`pandoc_table_head()`](https://rundel.github.io/q2r/reference/pandoc_table_head.md)
  [`pandoc_table_body()`](https://rundel.github.io/q2r/reference/pandoc_table_head.md)
  [`pandoc_table_foot()`](https://rundel.github.io/q2r/reference/pandoc_table_head.md)
  : Table head / body / foot
- [`pandoc_meta_value()`](https://rundel.github.io/q2r/reference/pandoc_meta_value.md)
  [`pandoc_config_value()`](https://rundel.github.io/q2r/reference/pandoc_meta_value.md)
  : Pandoc meta / config value

## Tree-sitter AST

S7 classes for the tree-sitter concrete syntax tree returned by
`parse_qmd(ast = "ts")`. The tree is structurally faithful to the source
bytes; use it when
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md)
round-trip equivalence matters. `print.ts_tree` documents the tree
display and its `position` / `ascii` knobs.

- [`ts_point()`](https://rundel.github.io/q2r/reference/ts_point.md)
  [`ts_range()`](https://rundel.github.io/q2r/reference/ts_point.md)
  [`ts_nodes()`](https://rundel.github.io/q2r/reference/ts_point.md)
  [`ts_node()`](https://rundel.github.io/q2r/reference/ts_point.md)
  [`ts_tree()`](https://rundel.github.io/q2r/reference/ts_point.md) :
  Tree-sitter AST classes
- [`print.ts_tree`](https://rundel.github.io/q2r/reference/print.ts_tree.md)
  [`print.ts_node`](https://rundel.github.io/q2r/reference/print.ts_tree.md)
  : Print a tree-sitter AST
