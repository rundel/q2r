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
