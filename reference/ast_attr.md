# Attribute manipulation helpers

**\[experimental\]**

## Usage

``` r
has_class(x, cls)

add_class(x, cls)

remove_class(x, cls)

get_id(x)

set_id(x, id)

get_attr(x, key)

set_attr(x, ...)
```

## Arguments

- x:

  A
  [`pandoc_node`](https://rundel.github.io/q2r/reference/pandoc_node.md)
  (typically one with an `@attr` slot).

- cls:

  A character vector of class names.

- id:

  A single string.

- key:

  A single string naming an attribute (for `get_attr()`).

- ...:

  For `set_attr()`, named `key = value` pairs; each `value` is a single
  string, or `NULL` to remove that key. Quote names that are not
  syntactic R identifiers (e.g. `"data-level" = "2"`), and use rlang's
  `!!!` / `:=` to supply dynamic keys.

## Value

Predicates return a logical scalar (or a string, for getters). Setters
return a node of the same class as `x`.

## Details

Concise getters and setters for the
[`pandoc_attr`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)
slot found on many pandoc node types
([`pandoc_header`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md),
[`pandoc_div`](https://rundel.github.io/q2r/reference/pandoc_block_constructors.md),
[`pandoc_code`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
[`pandoc_link`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
[`pandoc_image`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
[`pandoc_span`](https://rundel.github.io/q2r/reference/pandoc_inline_constructors.md),
etc.). Modelled on Pandoc Lua filters' direct field access
(`el.classes`, `el.identifier`, `el.attributes`) but using R's immutable
value semantics: every setter returns a new node, the input is never
modified.

Nodes without a standard `@attr` slot are handled defensively: the
getters return `FALSE` / `""` / `NA` (including nodes such as ordered
and bullet lists, whose `@attr` is a `pandoc_list_attributes` rather
than a
[`pandoc_attr`](https://rundel.github.io/q2r/reference/pandoc_support_types.md)),
while setters error with a clear message.

## Available helpers

- `has_class(x, cls)` `TRUE` if any of `cls` is in `@attr@classes`. When
  used inside a
  [`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  /
  [`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
  predicate, the data-mask version is bound to the current node
  automatically; the exported version here takes the node as its first
  argument.

- `add_class(x, cls)` add one or more classes (idempotent: classes
  already present are not duplicated).

- `remove_class(x, cls)` remove one or more classes; no-op on classes
  that are not present.

- `get_id(x)` / `set_id(x, id)` read or replace `@attr@id`.

- `get_attr(x, key)` reads a single attribute, returning `NA_character_`
  for missing keys.

- `set_attr(x, key = value, ...)` sets one or more attributes from named
  `key = value` pairs. A `value` of `NULL` removes that key (the named
  map's idiomatic R removal, mirroring Lua's
  `el.attributes[key] = nil`), so a single call can both set and drop:
  `set_attr(x, target = "_blank", lang = NULL)`.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("# title {.unnumbered}\n")
doc |> map_nodes(is(pandoc_header), .f = function(h) {
  h |> add_class("highlight") |> set_id("intro")
})
} # }
```
