# Tree-sitter AST classes

S7 classes representing the tree-sitter (`tree-sitter-qmd`) AST produced
by pampa for a QMD document. Unlike the Pandoc AST, tree-sitter node
kinds are open-ended grammar-defined strings, so a single `ts_node`
class with a `kind` string property is used.

## Usage

``` r
ts_point(row = NA_integer_, column = NA_integer_)

ts_range(
  start_byte = NA_integer_,
  end_byte = NA_integer_,
  start_point = ts_point(),
  end_point = ts_point()
)

ts_nodes(content = list())

ts_node(
  kind = "",
  is_named = TRUE,
  field_name = NULL,
  range = ts_range(),
  text = NULL,
  children = ts_nodes(list())
)

ts_tree(root = ts_node(), language = "qmd", diagnostics = list())
```

## Arguments

- row, column:

  For ts_point, the 0-based row and column.

- start_byte, end_byte:

  For ts_range, the byte offsets of the span.

- start_point, end_point:

  For ts_range, the start/end ts_points.

- content:

  For ts_nodes, a list of ts_nodes.

- kind:

  For ts_node, the grammar node kind (a string).

- is_named:

  For ts_node, whether the node is named (vs anonymous).

- field_name:

  For ts_node, the parent field name, or `NULL`.

- range:

  For ts_node, its ts_range.

- text:

  For ts_node, the source text it carries, or `NULL`.

- children:

  For ts_node, its child ts_nodes.

- root:

  For ts_tree, the root ts_node.

- language:

  For ts_tree, the grammar name (default `"qmd"`).

- diagnostics:

  For ts_tree, a list of
  [pampa_diagnostic](https://rundel.github.io/q2r/reference/pampa_diagnostic.md)s.
