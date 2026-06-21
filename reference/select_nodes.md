# Select, filter, and rewrite nodes in a Pandoc or tree-sitter AST

**\[experimental\]**

## Usage

``` r
select_nodes(x, ...)

select_descendants(x, ...)

select_children(x, ...)

select_first(x, ...)

walk_nodes(x, ..., .f)

map_nodes(x, ..., .f)

replace_nodes(x, ..., .with)

delete_nodes(x, ...)

splice_nodes(x, ..., .f)

insert_before(x, ..., .what)

insert_after(x, ..., .what)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md),
  [`pandoc_node`](https://rundel.github.io/q2r/reference/pandoc_node.md),
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md),
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md),
  [`ts_node`](https://rundel.github.io/q2r/reference/ts_point.md),
  [`ts_nodes`](https://rundel.github.io/q2r/reference/ts_point.md), or a
  plain `list` of nodes from a previous selection. For a plain list,
  each mutation verb is applied to every element in turn (insert and
  splice flatten their multi-node results back into one list).

- ...:

  Predicate expressions, combined with `&`. May be empty to match every
  node (use with care).

- .f:

  A function (or rlang formula like `~ ...`) called with each matching
  node. Return value follows the mutation contract above.

- .with:

  A constant replacement node or list of nodes.

- .what:

  The siblings to insert. May be a single node, a list of nodes, or a
  function called as `.what(node)`.

## Details

A tidyselect-style API for querying and rewriting either of q2r's two
AST representations: the
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) S7
hierarchy and the
[`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md)
tree-sitter AST. Each verb is an S7 generic with methods on the relevant
node types; the same verb name works on both ASTs.

Predicates are unquoted R expressions evaluated against each candidate
node with a per-AST data mask. The mask exposes the node's S7 slots as
bare names (`level`, `url`, `text`, `kind`, `is_named`, ...) plus a set
of helper functions (`is()`,
[`has_class()`](https://rundel.github.io/q2r/reference/ast_attr.md),
`has_id()`, `has_attr()`, `has_text()`, `has_label()`, `is_leaf()`).
Multiple predicates are combined with `&` (logical AND).

## Selection verbs

- `select_nodes()` descends the whole tree (including the root) and
  returns a flat list of matching nodes.

- `select_descendants()` is the same but excludes the root. Accepts a
  list of nodes (so pipe chains work).

- `select_children()` only checks the direct children.

- `select_first()` returns the first match or `NULL`.

## Iteration and mutation verbs

- `walk_nodes()` applies a side-effect function to every match; returns
  its input invisibly.

- `map_nodes()` rewrites every match via `.f`. The function may return a
  single node (in-place replacement), a list of nodes (spliced in at the
  match site), `NULL` (delete), or the original node (no-op). Applied to
  a document / tree / wrapper the result is the same class as the input;
  applied to a bare node the result follows the mutation contract
  directly (it may be a node, a list, or `NULL`).

- `replace_nodes()` is `map_nodes()` with a constant replacement.

- `delete_nodes()` is `map_nodes()` with `\(x) NULL`.

- `splice_nodes()` is `map_nodes()` whose `.f` must return a list.

- `insert_before()` / `insert_after()` inject siblings around each
  match.

## Mutation contract

`.f` is called with each matching node as its argument. Its return value
is interpreted by the walker:

- A single node of the appropriate kind replaces the original.

- A list of nodes is spliced into the parent's child list at the match's
  position.

- `NULL` removes the match from the parent.

- Returning the original node (or an `==` equivalent) is a no-op.

The mutation walker traverses bottom-up (post-order), so when a parent
is checked its children have already been rewritten. This matches Pandoc
Lua filters' default.

On a `ts_tree`, the three grammar-gap *content* kinds (`pandoc_math`,
`pandoc_display_math`, `code_fence_content`) round-trip through their
verbatim source bytes, so mutating *their* children is a no-op on
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) output.

## Predicate helpers (only available inside `...`)

These shadow nothing in the global R namespace because they are
installed into the predicate's data mask, not the package namespace.
Outside a `select_*`/`map_nodes`/etc. predicate they are unavailable.

- `is(<S7 class>)` honours S7 inheritance, so `is(pandoc_block)` matches
  any block. The attribute- and text-based helpers (`has_class`,
  `has_id`, `has_attr`, `has_text`, `has_label`) resolve `@attr` /
  [`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md),
  which exist only on the pandoc AST, so on a `ts_tree` they are a
  silent no-match. Use
  [`ts_query()`](https://rundel.github.io/q2r/reference/ts_query.md) or
  bare-slot predicates (`kind`, `text`) for tree-sitter queries.

- `has_class("foo")` / `has_class(c("foo", "bar"))` test `@attr@classes`
  membership (pandoc only).

- `has_id("intro")` tests `@attr@id` (pandoc only).

- `has_attr("key")` / `has_attr("key", "val")` test `@attr@attributes`
  (pandoc only).

- `has_text("Exercise")` tests the node's flattened text
  ([`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md))
  against one or more regex patterns (`fixed = TRUE` for literal
  matching); the analog of parsermd's `has_heading()` (pandoc only).

- `has_label("fig-*")` glob-matches the node's `@attr@id`, where Quarto
  labels surface as `#id`; for code cells without an attr id it falls
  back to the cell's `label` option. The analog of parsermd's
  `has_label()` (pandoc only).

- [`is_code_cell()`](https://rundel.github.io/q2r/reference/code_cell.md)
  matches an executable Quarto cell (see
  [`code_cell`](https://rundel.github.io/q2r/reference/code_cell.md)).

- `has_option("eval")` / `has_option("eval", FALSE)` test a cell's `#|`
  options.

- `has_engine("r")` / `has_engine(c("r", "python"))` test a cell's
  engine
  ([`cell_engine()`](https://rundel.github.io/q2r/reference/code_cell.md)).

- `is_leaf()` matches nodes with no children.

- `is_named` (a bare slot, tree-sitter only, not a function call) is the
  `ts_node` named/anonymous flag.

- `starts_with()`, `ends_with()`, `matches()`, `contains()` - string
  tests usable as e.g. `starts_with("http", url)`.

- `any_of(x)` and `all_of(x)` - splice a character vector for use with
  `%in%`.

- Bare slot access: `level`, `url`, `title`, `text`, `format`, `kind`,
  `class`, `quote_type`, `math_type`, etc. Missing slots resolve to
  `NULL` (so `NULL == 2` is `FALSE`, not an error).
