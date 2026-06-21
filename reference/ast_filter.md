# Apply a table of type-keyed handlers to a pandoc AST

**\[experimental\]**

## Usage

``` r
ast_filter(x, ...)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md)
  document, any
  [`pandoc_node`](https://rundel.github.io/q2r/reference/pandoc_node.md),
  a
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  /
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper, or a plain `list` of nodes.

- ...:

  Named functions, where each name is an exported S7 class (e.g.
  `pandoc_strong`, `pandoc_header`, `pandoc_block`).

- .order:

  Traversal direction: `"post"` (default, children rewritten before
  parent's handler runs) or `"pre"` (parent's handler runs first; wrap
  the return value with
  [`ast_skip()`](https://rundel.github.io/q2r/reference/ast_skip.md) to
  skip descent).

## Value

A rewritten value of the same outer shape as `x`.

## Details

Borrows the Pandoc Lua filter idiom of dispatching on element type: the
user provides one named function per S7 class to rewrite, and
`ast_filter()` walks the AST once, invoking the matching handler at each
node. Handlers honour the same return-value contract as
[`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
(return a node to replace, a `list` of nodes to splice, `NULL` to
delete, or the input to no-op).

Dispatch is by S7 class with inheritance: a `pandoc_block = \(b) ...`
handler will run on every block subtype. When several handler names
match a node, the first listed in `...` wins, so put more specific
classes (e.g. `pandoc_header`) before more general ones
(`pandoc_block`).

Traversal is post-order by default: a parent's handler sees its children
after they have been rewritten. This matches Pandoc Lua filters'
default. Pass `.order = "pre"` for a top-down walk in which a parent's
handler runs first; from a pre-order handler, return
[`ast_skip()`](https://rundel.github.io/q2r/reference/ast_skip.md) to
use the (possibly modified) node as-is without descending into its
children. This mirrors Lua filters' `traverse = 'topdown'` plus
`return el, false`.

Two special handler names trigger list-level dispatch on entire
inline/block sequences (Lua's `Inlines` / `Blocks` filters):

- `pandoc_inlines = \(xs) ...` is called once per
  [`pandoc_inlines`](https://rundel.github.io/q2r/reference/pandoc_blocks.md)
  wrapper after its contents have been rewritten. Return a
  `pandoc_inlines` (or a `list` of inlines, or `NULL` for empty).

- `pandoc_blocks = \(xs) ...` is the equivalent for
  [`pandoc_blocks`](https://rundel.github.io/q2r/reference/pandoc_blocks.md).
  These are useful for sliding-window / context-aware transforms that
  cannot be expressed at single-element level (e.g. merging adjacent
  runs, dropping siblings based on neighbours).

## See also

[`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
for predicate-based rewriting,
[`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md) for
stringifying a subtree.

## Examples

``` r
doc = parse_qmd("# Hello\n\n**bold** and *italic*\n")
doc |> ast_filter(
  pandoc_strong = \(el) pandoc_small_caps(content = el@content),
  pandoc_header = \(el) {
    if (el@level == 1L) {
      pandoc_header(level = 2L, content = el@content, attr = el@attr)
    } else el
  }
)
#> pandoc
#> ├─header level=2 (#hello)
#> │ └─str "Hello"
#> └─paragraph
#>   ├─small_caps
#>   │ └─str "bold"
#>   ├─space
#>   ├─str "and"
#>   ├─space
#>   └─emph
#>     └─str "italic"
```
