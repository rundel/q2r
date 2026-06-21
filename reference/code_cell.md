# Quarto code-cell helpers

**\[experimental\]**

## Usage

``` r
is_code_cell(x)

cell_engine(x)

cell_options(x)

cell_code(x)

cell_label(x)

set_cell_options(x, ...)

set_cell_label(x, value)

collect_code(x, engine = NULL, eval_only = FALSE, label_comments = TRUE)
```

## Arguments

- x:

  For the accessors and setters, a
  [`pandoc_code_block`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md):
  the accessors return empty / `NA` on a non-cell, and the setters
  require an executable cell (braced engine). For `collect_code()`, any
  node or document to gather cells from.

- ...:

  For `set_cell_options()`, named `key = value` option pairs.

- value:

  For `set_cell_label()`, the new label string.

- engine:

  For `collect_code()`, keep only cells with this engine.

- eval_only:

  For `collect_code()`, drop cells whose `eval` option is `FALSE`.

- label_comments:

  For `collect_code()`, prefix each cell's code with a `# <label>`
  comment when it has a label.

## Value

Accessors return a scalar (or named list, for `cell_options()`); setters
return a new
[`pandoc_code_block`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md);
`collect_code()` returns a single string.

## Details

A Quarto executable cell parses to a
[`pandoc_code_block`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
whose engine is carried as a braced class (`{r}`, `{python}`, `{ojs}`,
...) and whose cell options live in leading `#|` (or `//|` / `--|`)
comment lines inside `@text`. None of that is surfaced by the raw node,
so these helpers read and edit it: they are the q2r analog of mq's
`.code(lang)` selector and of parsermd's `rmd_node_engine()` /
`rmd_node_label()` / `rmd_node_options()` family.

A plain fenced code block (```` ```r ````, class `r` with no braces) is
*not* a cell: `is_code_cell()` is `FALSE`, `cell_engine()` is `NA`, and
`cell_options()` is empty.

## Helpers

- `is_code_cell(x)` `TRUE` when `x` is an executable cell (a
  [`pandoc_code_block`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md)
  with a braced engine class).

- `cell_engine(x)` the engine name (`"r"`, `"python"`, ...) or `NA`.

- `cell_label(x)` the `label` option, falling back to `@attr@id`, or
  `NA`.

- `cell_code(x)` the cell body with the leading option lines stripped.

- `cell_options(x)` the `#|` options parsed from YAML into a named list.

- `set_cell_options(x, ...)` returns a new cell with options set from
  named `key = value` pairs (a `NULL` value removes that option,
  mirroring
  [`set_attr()`](https://rundel.github.io/q2r/reference/ast_attr.md)).

- `set_cell_label(x, value)` convenience for
  `set_cell_options(x, label = value)`.

- `collect_code(x, ...)` tangles the code of every cell under `x` into
  one string.

Inside a
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
/
[`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
predicate the mask also exposes `is_code_cell()` (zero-argument, tests
the current node) and `has_option(key)` / `has_option(key, value)`, so
`select_nodes(doc, is_code_cell() & has_option("eval", FALSE))` works.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("```{r}\n#| label: fig-1\n#| echo: false\nplot(1)\n```\n")
cell = select_first(doc, is(pandoc_code_block))
cell_engine(cell)
cell_options(cell)
set_cell_options(cell, echo = TRUE, eval = NULL)
} # }
```
