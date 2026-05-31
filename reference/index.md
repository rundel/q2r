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

## Querying the AST

tidyselect-style verbs for locating nodes by predicate. Works on both
the Pandoc S7 AST and the tree-sitter AST. Predicates are unquoted
expressions evaluated against a per-node data mask that exposes slot
names and helpers (`is()`,
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

## Rewriting the AST

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

## Filter-table rewriting (Lua-filter-style)

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

## Pandoc AST — root and abstract classes

The S7 class hierarchy. `pandoc` is the document root, `pandoc_node` the
common ancestor for every concrete node, and `pandoc_block` /
`pandoc_inline` the abstract block/inline parents. `pandoc_blocks` /
`pandoc_inlines` are the strict-typed list wrappers used in content
slots. `print.pandoc` documents the tree display and its `position` /
`ascii` knobs.

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
- [`print.pandoc`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  [`print.pandoc_node`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  [`print.pandoc_blocks`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  [`print.pandoc_inlines`](https://rundel.github.io/q2r/reference/print.pandoc.md)
  : Print a Pandoc AST

## Pandoc AST — block constructors

- [`pandoc_plain()`](https://rundel.github.io/q2r/reference/pandoc_plain.md)
  : Plain block
- [`pandoc_paragraph()`](https://rundel.github.io/q2r/reference/pandoc_paragraph.md)
  : Paragraph
- [`pandoc_header()`](https://rundel.github.io/q2r/reference/pandoc_header.md)
  : Header
- [`pandoc_block_quote()`](https://rundel.github.io/q2r/reference/pandoc_block_quote.md)
  : Block quote
- [`pandoc_div()`](https://rundel.github.io/q2r/reference/pandoc_div.md)
  : Div
- [`pandoc_code_block()`](https://rundel.github.io/q2r/reference/pandoc_code_block.md)
  : Code block
- [`pandoc_raw_block()`](https://rundel.github.io/q2r/reference/pandoc_raw_block.md)
  : Raw block
- [`pandoc_ordered_list()`](https://rundel.github.io/q2r/reference/pandoc_ordered_list.md)
  : Ordered list
- [`pandoc_bullet_list()`](https://rundel.github.io/q2r/reference/pandoc_bullet_list.md)
  : Bullet list
- [`pandoc_line_block()`](https://rundel.github.io/q2r/reference/pandoc_line_block.md)
  : Line block
- [`pandoc_definition_list()`](https://rundel.github.io/q2r/reference/pandoc_definition_list.md)
  : Definition list
- [`pandoc_definition_item()`](https://rundel.github.io/q2r/reference/pandoc_definition_item.md)
  : Definition-list item
- [`pandoc_figure()`](https://rundel.github.io/q2r/reference/pandoc_figure.md)
  : Figure
- [`pandoc_horizontal_rule()`](https://rundel.github.io/q2r/reference/pandoc_horizontal_rule.md)
  : Horizontal rule
- [`pandoc_caption_block()`](https://rundel.github.io/q2r/reference/pandoc_caption_block.md)
  : Caption block (orphan caption)
- [`pandoc_block_metadata()`](https://rundel.github.io/q2r/reference/pandoc_block_metadata.md)
  : Block metadata
- [`pandoc_note_definition_para()`](https://rundel.github.io/q2r/reference/pandoc_note_definition_para.md)
  : Note definition (paragraph form)
- [`pandoc_note_definition_fenced_block()`](https://rundel.github.io/q2r/reference/pandoc_note_definition_fenced_block.md)
  : Note definition (fenced block form)
- [`pandoc_custom_block()`](https://rundel.github.io/q2r/reference/pandoc_custom_block.md)
  : Custom block node (Quarto extensions: callouts, tabsets, ...)

## Pandoc AST — inline constructors

- [`pandoc_str()`](https://rundel.github.io/q2r/reference/pandoc_str.md)
  : Literal string
- [`pandoc_space()`](https://rundel.github.io/q2r/reference/pandoc_space.md)
  : Space
- [`pandoc_soft_break()`](https://rundel.github.io/q2r/reference/pandoc_soft_break.md)
  : Soft line break
- [`pandoc_line_break()`](https://rundel.github.io/q2r/reference/pandoc_line_break.md)
  : Hard line break
- [`pandoc_emph()`](https://rundel.github.io/q2r/reference/pandoc_emph.md)
  : Emphasized text
- [`pandoc_underline()`](https://rundel.github.io/q2r/reference/pandoc_underline.md)
  : Underlined text
- [`pandoc_strong()`](https://rundel.github.io/q2r/reference/pandoc_strong.md)
  : Strong text
- [`pandoc_strikeout()`](https://rundel.github.io/q2r/reference/pandoc_strikeout.md)
  : Struck-through text
- [`pandoc_superscript()`](https://rundel.github.io/q2r/reference/pandoc_superscript.md)
  : Superscript
- [`pandoc_subscript()`](https://rundel.github.io/q2r/reference/pandoc_subscript.md)
  : Subscript
- [`pandoc_small_caps()`](https://rundel.github.io/q2r/reference/pandoc_small_caps.md)
  : Small caps
- [`pandoc_quoted()`](https://rundel.github.io/q2r/reference/pandoc_quoted.md)
  : Quoted text
- [`pandoc_cite()`](https://rundel.github.io/q2r/reference/pandoc_cite.md)
  : Citation reference
- [`pandoc_code()`](https://rundel.github.io/q2r/reference/pandoc_code.md)
  : Inline code
- [`pandoc_math()`](https://rundel.github.io/q2r/reference/pandoc_math.md)
  : Math
- [`pandoc_raw_inline()`](https://rundel.github.io/q2r/reference/pandoc_raw_inline.md)
  : Raw inline
- [`pandoc_link()`](https://rundel.github.io/q2r/reference/pandoc_link.md)
  : Link
- [`pandoc_image()`](https://rundel.github.io/q2r/reference/pandoc_image.md)
  : Image
- [`pandoc_note()`](https://rundel.github.io/q2r/reference/pandoc_note.md)
  : Footnote
- [`pandoc_span()`](https://rundel.github.io/q2r/reference/pandoc_span.md)
  : Inline span
- [`pandoc_shortcode()`](https://rundel.github.io/q2r/reference/pandoc_shortcode.md)
  : Shortcode
- [`pandoc_insert()`](https://rundel.github.io/q2r/reference/pandoc_insert.md)
  : CriticMarkup: insertion
- [`pandoc_delete()`](https://rundel.github.io/q2r/reference/pandoc_delete.md)
  : CriticMarkup: deletion
- [`pandoc_highlight()`](https://rundel.github.io/q2r/reference/pandoc_highlight.md)
  : CriticMarkup: highlight
- [`pandoc_edit_comment()`](https://rundel.github.io/q2r/reference/pandoc_edit_comment.md)
  : CriticMarkup: comment
- [`pandoc_note_reference()`](https://rundel.github.io/q2r/reference/pandoc_note_reference.md)
  : Note reference
- [`pandoc_attr_inline()`](https://rundel.github.io/q2r/reference/pandoc_attr_inline.md)
  : Standalone attribute inline
- [`pandoc_custom_inline()`](https://rundel.github.io/q2r/reference/pandoc_custom_inline.md)
  : Custom inline node (Quarto extensions)

## Pandoc AST — support types

Helper types that appear inside concrete nodes: attributes, table
substructures, citations, captions, metadata.

- [`pandoc_attr()`](https://rundel.github.io/q2r/reference/pandoc_attr.md)
  : Pandoc attributes
- [`pandoc_caption()`](https://rundel.github.io/q2r/reference/pandoc_caption.md)
  : Caption (short + long)
- [`pandoc_citation()`](https://rundel.github.io/q2r/reference/pandoc_citation.md)
  : Citation
- [`pandoc_table()`](https://rundel.github.io/q2r/reference/pandoc_table.md)
  : Table
- [`pandoc_table_head()`](https://rundel.github.io/q2r/reference/pandoc_table_head.md)
  [`pandoc_table_body()`](https://rundel.github.io/q2r/reference/pandoc_table_head.md)
  [`pandoc_table_foot()`](https://rundel.github.io/q2r/reference/pandoc_table_head.md)
  : Table head / body / foot
- [`pandoc_row()`](https://rundel.github.io/q2r/reference/pandoc_row.md)
  : Table row
- [`pandoc_cell()`](https://rundel.github.io/q2r/reference/pandoc_cell.md)
  : Table cell
- [`pandoc_col_spec()`](https://rundel.github.io/q2r/reference/pandoc_col_spec.md)
  : Table column alignment and width
- [`pandoc_list_attributes()`](https://rundel.github.io/q2r/reference/pandoc_list_attributes.md)
  : Ordered list attributes
- [`pandoc_format_label()`](https://rundel.github.io/q2r/reference/pandoc_format_label.md)
  : Label a pandoc AST node for tree display
- [`pandoc_meta_value()`](https://rundel.github.io/q2r/reference/pandoc_meta_value.md)
  [`pandoc_config_value()`](https://rundel.github.io/q2r/reference/pandoc_meta_value.md)
  : Pandoc meta / config value
- [`pandoc_source_info()`](https://rundel.github.io/q2r/reference/pandoc_source_info.md)
  : Source location

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
