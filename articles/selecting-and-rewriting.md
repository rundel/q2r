# Selecting and rewriting AST nodes

q2r exposes two ASTs for a QMD document: the high-level \[`pandoc`\] S7
hierarchy and the \[`ts_tree`\] tree-sitter concrete syntax tree. The
`select_*` / `map_nodes` / `*_nodes` API lets you query and rewrite
either one with the same vocabulary.

``` r

library(q2r)

src = "
# Intro

Some **bold** prose with a [link](https://example.com).

::: callout-note
## Watch out

A callout with its own *emphasised* heading.
:::

## Conclusion

Final words.
"

doc = pampa_parse(src)
```

## Selecting

Predicates are unquoted R expressions evaluated against each candidate
node with a node-aware data mask. The mask exposes node slots (`level`,
`url`, `text`, `kind`, …) and a small set of helpers (`is()`,
[`has_class()`](https://rundel.github.io/q2r/reference/ast_attr.md),
`has_id()`, `has_attr()`, `is_leaf()`).

``` r

select_nodes(doc, is(pandoc_header))
#> [[1]]
#> header level=1 (#intro)
#> └─str "Intro"
#> 
#> [[2]]
#> header level=2 (#watch-out)
#> ├─str "Watch"
#> ├─space
#> └─str "out"
#> 
#> [[3]]
#> header level=2 (#conclusion)
#> └─str "Conclusion"
```

`is()` honours S7 inheritance, so `is(pandoc_block)` matches every block
kind:

``` r

length(select_nodes(doc, is(pandoc_block)))
#> [1] 7
```

Bare slot access lets you filter on properties without writing accessors
yourself:

``` r

select_nodes(doc, is(pandoc_header) & level == 2L)
#> [[1]]
#> header level=2 (#watch-out)
#> ├─str "Watch"
#> ├─space
#> └─str "out"
#> 
#> [[2]]
#> header level=2 (#conclusion)
#> └─str "Conclusion"
```

[`has_class()`](https://rundel.github.io/q2r/reference/ast_attr.md)
reads `@attr@classes`:

``` r

select_nodes(doc, is(pandoc_div) & has_class("callout-note"))
#> [[1]]
#> div (.callout-note)
#> ├─header level=2 (#watch-out)
#> │ ├─str "Watch"
#> │ ├─space
#> │ └─str "out"
#> └─paragraph
#>   ├─str "A"
#>   ├─space
#>   ├─str "callout"
#>   ├─space
#>   ├─str "with"
#>   ├─space
#>   ├─str "its"
#>   ├─space
#>   ├─str "own"
#>   ├─space
#>   ├─emph
#>   │ └─str "emphasised"
#>   ├─space
#>   └─str "heading."
```

## Chaining

The selection verbs accept a list of nodes, so a pipe chain narrows
without nesting:

``` r

doc |>
  select_nodes(is(pandoc_div) & has_class("callout-note")) |>
  select_descendants(is(pandoc_header))
#> [[1]]
#> header level=2 (#watch-out)
#> ├─str "Watch"
#> ├─space
#> └─str "out"
```

[`select_descendants()`](https://rundel.github.io/q2r/reference/select_nodes.md)
excludes the root(s) of its input;
[`select_children()`](https://rundel.github.io/q2r/reference/select_nodes.md)
only inspects direct children.

## Rewriting

[`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
rewrites every match in place. `.f` may return a single node (replace),
a list of nodes (splice into the parent’s child list), or `NULL`
(delete). The walker traverses bottom-up, matching Pandoc Lua filters’
default.

Promote every level-2 heading to level 1:

``` r

out = map_nodes(
  doc,
  is(pandoc_header) & level == 2L,
  .f = \(h) pandoc_header(level = 1L, attr = h@attr, content = h@content)
)

purrr::map_int(select_nodes(out, is(pandoc_header)), \(h) h@level)
#> [1] 1 1 1
```

Strip bold by splicing each `pandoc_strong`’s content up into the
parent:

``` r

out = map_nodes(doc, is(pandoc_strong), .f = ~ .x@content@content)
length(select_nodes(out, is(pandoc_strong)))
#> [1] 0
```

## Structural edits

[`insert_before()`](https://rundel.github.io/q2r/reference/select_nodes.md)
/
[`insert_after()`](https://rundel.github.io/q2r/reference/select_nodes.md)
add siblings around each match;
[`delete_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
removes them;
[`replace_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
swaps them out for a constant value.

``` r

banner = pandoc_paragraph(
  content = pandoc_inlines(list(pandoc_str(text = "[banner]")))
)

doc |>
  insert_before(is(pandoc_header) & level == 1L, .what = banner) |>
  select_children(is(pandoc_paragraph) | is(pandoc_header))
#> [[1]]
#> paragraph
#> └─str "[banner]"
#> 
#> [[2]]
#> header level=1 (#intro)
#> └─str "Intro"
#> 
#> [[3]]
#> paragraph
#> ├─str "Some"
#> ├─space
#> ├─strong
#> │ └─str "bold"
#> ├─space
#> ├─str "prose"
#> ├─space
#> ├─str "with"
#> ├─space
#> ├─str "a"
#> ├─space
#> ├─link url="https://example.com"
#> │ └─str "link"
#> └─str "."
#> 
#> [[4]]
#> header level=2 (#conclusion)
#> └─str "Conclusion"
#> 
#> [[5]]
#> paragraph
#> ├─str "Final"
#> ├─space
#> └─str "words."
```

## Type-keyed dispatch with `ast_filter()`

[`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
is most natural for single-type rewrites driven by a predicate. When you
want to rewrite *several* node types in a single pass,
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
accepts a table of handlers keyed by S7 class. This is the q2r analogue
of a Pandoc Lua filter
(`{ Header = function(el) ... end, Strong = ... }`).

``` r

out = doc |> ast_filter(
  pandoc_strong = \(el) pandoc_small_caps(content = el@content),
  pandoc_header = \(el) {
    if (el@level == 1L) {
      pandoc_header(level = 2L, attr = el@attr, content = el@content)
    } else el
  }
)

cat(to_qmd(out))
#> ## Intro
#> 
#> Some [bold]{.smallcaps} prose with a [link](https://example.com).
#> 
#> ::: {.callout-note}
#> 
#> ## Watch out
#> 
#> A callout with its own *emphasised* heading.
#> 
#> :::
#> 
#> ## Conclusion
#> 
#> Final words.
```

Handlers honour the same return-value contract as
[`map_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md):
return a node to replace, a list of nodes to splice, `NULL` to delete,
or the input to no-op.

Dispatch respects S7 inheritance, so an abstract-class handler acts as a
catch-all (first-match-wins, so put specific types before general ones):

``` r

visits = c()
invisible(doc |> ast_filter(
  pandoc_header = \(el) { visits <<- c(visits, "header"); el },
  pandoc_block  = \(el) { visits <<- c(visits, "block");  el }
))
table(visits)
#> visits
#>  block header 
#>      4      3
```

## Top-down traversal and skipping subtrees

Pass `.order = "pre"` to visit parents before children. From a pre-order
handler, return `ast_skip(x)` to install `x` at that position without
descending into its children. This mirrors Pandoc Lua filters’
`traverse = 'topdown'` plus `return el, false`.

``` r

# Strip ALL formatting inside callout divs, leaving the rest of the
# document alone.
out = doc |> ast_filter(
  .order = "pre",
  pandoc_div = \(d) {
    if (has_class(d, "callout-note")) {
      flattened = pandoc_div(
        attr    = d@attr,
        content = as_blocks(ast_text(d))
      )
      ast_skip(flattened)
    } else d
  }
)

cat(to_qmd(out))
#> # Intro
#> 
#> Some **bold** prose with a [link](https://example.com).
#> 
#> ::: {.callout-note}
#> 
#> Watch out
#> 
#> A callout with its own emphasised heading.
#> 
#> :::
#> 
#> ## Conclusion
#> 
#> Final words.
```

Without
[`ast_skip()`](https://rundel.github.io/q2r/reference/ast_skip.md), the
walker would still descend into the rewritten div’s content; the skip is
what makes “this whole subtree is now done” explicit.

## List-level filters

Two special handler names dispatch on entire inline/block sequences
after their contents have been rewritten:

- `pandoc_inlines = \(xs) ...` runs once per `pandoc_inlines` wrapper.
- `pandoc_blocks = \(xs) ...` is the equivalent for `pandoc_blocks`.

These are essential for context-aware transforms that single-element
handlers cannot express (merging adjacent runs, dropping siblings based
on neighbours, etc.).

``` r

# Drop any paragraph whose plain-text form contains "Final".
out = doc |> ast_filter(pandoc_blocks = \(xs) {
  keep = !purrr::map_lgl(xs@content, \(b) {
    S7::S7_inherits(b, pandoc_paragraph) &&
      grepl("Final", ast_text(b), fixed = TRUE)
  })
  pandoc_blocks(xs@content[keep])
})

select_children(out, is(pandoc_paragraph)) |>
  purrr::map_chr(ast_text)
#> [1] "Some bold prose with a link."
```

List-level and element-level handlers compose in a single pass:

``` r

out = doc |> ast_filter(
  pandoc_strong  = \(el) pandoc_small_caps(content = el@content),
  pandoc_inlines = \(xs) {
    # Append a marker whenever a paragraph ends up containing small caps.
    has_smallcaps = any(purrr::map_lgl(xs@content, S7::S7_inherits, pandoc_small_caps))
    if (has_smallcaps) {
      pandoc_inlines(c(xs@content, list(pandoc_str(text = "[!]"))))
    } else xs
  }
)

# the marker landed in the paragraph that had bold:
purrr::map_chr(select_children(out, is(pandoc_paragraph)), ast_text)
#> [1] "Some bold prose with a link.[!]" "Final words."
```

## Flattening to plain text with `ast_text()`

[`ast_text()`](https://rundel.github.io/q2r/reference/ast_text.md)
recursively concatenates the textual content of any subtree, dropping
all formatting. It is the q2r analogue of `pandoc.utils.stringify()` and
is handy for matching on document content without walking the AST
yourself.

``` r

ast_text(doc)
#> [1] "Intro\n\nSome bold prose with a link.\n\nWatch out\n\nA callout with its own emphasised heading.\n\nConclusion\n\nFinal words."
```

It works on any node, not just the root:

``` r

doc |>
  select_first(is(pandoc_div) & has_class("callout-note")) |>
  ast_text()
#> [1] "Watch out\n\nA callout with its own emphasised heading."
```

A common pattern: pick out matches by predicate, then summarise:

``` r

doc |>
  select_nodes(is(pandoc_header)) |>
  purrr::map_chr(ast_text)
#> [1] "Intro"      "Watch out"  "Conclusion"
```

## Editing attributes

The `@attr` slot carries id, classes, and key/value attributes for the
nodes that have one (headers, divs, code, links, spans, …). q2r ships
immutable getters/setters that read like Lua’s direct field access
(`el.classes`, `el.identifier`) but return a new node:

- `has_class(x, cls)` / `add_class(x, cls)` / `remove_class(x, cls)`
- `get_id(x)` / `set_id(x, id)`
- `get_attr(x, key)` / `set_attr(x, key, value)` / `remove_attr(x, key)`

``` r

out = doc |> ast_filter(pandoc_header = \(h) {
  h |> add_class("section") |> set_attr("data-level", as.character(h@level))
})

out |> select_nodes(is(pandoc_header)) |> purrr::map(\(h) h@attr)
#> [[1]]
#> <q2r::pandoc_attr>
#>  @ id        : chr "intro"
#>  @ classes   : chr "section"
#>  @ attributes: Named chr "1"
#>  .. - attr(*, "names")= chr "data-level"
#> 
#> [[2]]
#> <q2r::pandoc_attr>
#>  @ id        : chr "watch-out"
#>  @ classes   : chr "section"
#>  @ attributes: Named chr "2"
#>  .. - attr(*, "names")= chr "data-level"
#> 
#> [[3]]
#> <q2r::pandoc_attr>
#>  @ id        : chr "conclusion"
#>  @ classes   : chr "section"
#>  @ attributes: Named chr "2"
#>  .. - attr(*, "names")= chr "data-level"
```

Nodes without an `@attr` slot degrade gracefully for predicates
(`has_class(pandoc_str(...), "x")` returns `FALSE`) but error on setters
with a clear message.

## Recipes: porting Pandoc / Quarto Lua filters

The verbs above are general purpose, but most Lua filters in the wild
follow a handful of recognisable shapes. The recipes below pair the Lua
original with its q2r translation so the mapping is obvious.

A note on output formats first: Pandoc and Quarto Lua filters run as a
stage of the render pipeline, so the output target is known and exposed
via `FORMAT` / `quarto.doc.isFormat()`. q2r is a parsing and rewriting
library, not a pipeline, and
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
does not know what (if anything) the caller will do next with the AST.
Document metadata is still available on `doc@meta`, but the *target* is
not; filters that branch on it (Quarto’s `fancy-text`, `kbd`,
`color-box`, …) therefore become parameterised functions whose caller
picks the branch up front. The recipes below all describe
target-agnostic rewrites.

### Open external links in a new tab

A staple of HTML-rendering Lua filters. The Pandoc version sets two
attributes on every `Link` whose target is an absolute URL:

``` lua
function Link(l)
  if l.target:match('^https?://') then
    l.attributes['target'] = '_blank'
    l.attributes['rel']    = 'noopener'
  end
  return l
end
```

The q2r translation is a single `ast_filter` handler keyed on
`pandoc_link`, using
[`set_attr()`](https://rundel.github.io/q2r/reference/ast_attr.md)
immutably:

``` r

out = doc |> ast_filter(
  pandoc_link = \(l) {
    if (!grepl("^https?://", l@url)) return(l)
    l |>
      set_attr("target", "_blank") |>
      set_attr("rel", "noopener")
  }
)

out |>
  select_nodes(is(pandoc_link)) |>
  purrr::map(\(l) l@attr@attributes)
#> [[1]]
#>     target        rel 
#>   "_blank" "noopener"
```

### Auto-anchor headings

A common Pandoc recipe that wraps each heading’s content in a link
pointing at its own id, so readers can grab a permalink by clicking the
heading:

``` lua
function Header(h)
  if h.identifier == '' then return h end
  local link = pandoc.Link(h.content, '#' .. h.identifier)
  return pandoc.Header(h.level, link, h.attr)
end
```

pampa applies pandoc’s auto-identifier rules during parsing, so the
headings in `doc` already have ids; the translation reads them with
[`get_id()`](https://rundel.github.io/q2r/reference/ast_attr.md) and
rebuilds the inline content with
[`as_inlines()`](https://rundel.github.io/q2r/reference/ast_construct.md):

``` r

out = doc |> ast_filter(
  pandoc_header = \(h) {
    id = get_id(h)
    if (!nzchar(id)) return(h)
    link = pandoc_link(
      content = h@content,
      url     = paste0("#", id)
    )
    pandoc_header(
      level   = h@level,
      attr    = h@attr,
      content = as_inlines(link)
    )
  }
)

cat(to_qmd(out))
#> # [Intro](#intro) {#intro}
#> 
#> Some **bold** prose with a [link](https://example.com).
#> 
#> ::: {.callout-note}
#> 
#> ## [Watch out](#watch-out) {#watch-out}
#> 
#> A callout with its own *emphasised* heading.
#> 
#> :::
#> 
#> ## [Conclusion](#conclusion) {#conclusion}
#> 
#> Final words.
```

### Force every callout to “caution”

Straight from the Quarto docs: rewrite the class of every callout `Div`
so the whole document renders as caution callouts.

``` lua
function Div(d)
  for i, c in ipairs(d.classes) do
    if c:match('^callout%-') then
      d.classes[i] = 'callout-caution'
    end
  end
  return d
end
```

[`remove_class()`](https://rundel.github.io/q2r/reference/ast_attr.md)
accepts a vector, so the entire callout-prefixed sublist can be dropped
in one call before adding the replacement:

``` r

out = doc |> ast_filter(
  pandoc_div = \(d) {
    callout = purrr::keep(
      d@attr@classes,
      \(c) startsWith(c, "callout-")
    )
    if (!length(callout)) return(d)
    d |>
      remove_class(callout) |>
      add_class("callout-caution")
  }
)

out |>
  select_nodes(is(pandoc_div)) |>
  purrr::map(\(d) d@attr@classes)
#> [[1]]
#> [1] "callout-caution"
```

### Count words

A read-only traversal: count every `Str` that contains a non-punctuation
character. The Lua version accumulates into a file-level local because
Lua filters return one element at a time and have no first-class way to
fold across calls.

``` lua
local n = 0
function Str(s)
  if s.text:match('%P') then n = n + 1 end
end
function Pandoc(_) print(n .. ' words') end
```

In R the natural shape is just
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md) +
`map_lgl()` + [`sum()`](https://rdrr.io/r/base/sum.html) – no
accumulator, no side effects:

``` r

doc |>
  select_nodes(is(pandoc_str)) |>
  purrr::map_lgl(\(s) grepl("[^[:punct:][:space:]]", s@text)) |>
  sum()
#> [1] 19
```

### Extract a link inventory

When the goal is to *collect* rather than to rewrite,
[`select_nodes()`](https://rundel.github.io/q2r/reference/select_nodes.md)
plus `purrr` is usually shorter than an `ast_filter` handler with a
side-effecting accumulator:

``` lua
local links = {}
function Link(l)
  links[#links + 1] = { text = pandoc.utils.stringify(l), url = l.target }
end
```

``` r

links = select_nodes(doc, is(pandoc_link))

data.frame(
  text = purrr::map_chr(links, ast_text),
  url  = purrr::map_chr(links, \(l) l@url)
)
#>   text                 url
#> 1 link https://example.com
```

## Constructing content quickly

Pandoc constructors are strictly typed, so even a simple emphasised
phrase requires a few layers of wrapping.
[`as_inlines()`](https://rundel.github.io/q2r/reference/ast_construct.md)
and
[`as_blocks()`](https://rundel.github.io/q2r/reference/ast_construct.md)
accept strings (whitespace is converted to spaces, newlines to soft
breaks), single nodes, lists, or existing wrappers, and produce the
canonical wrapper type. Use them inside an
[`ast_filter()`](https://rundel.github.io/q2r/reference/ast_filter.md)
handler to keep the body terse.

``` r

# Append a "[Edited]" tag to every paragraph.
out = doc |> ast_filter(pandoc_paragraph = \(p) {
  pandoc_paragraph(content = as_inlines(c(
    p@content@content,
    list(pandoc_space(), pandoc_str(text = "[Edited]"))
  )))
})

select_children(out, is(pandoc_paragraph)) |>
  purrr::map_chr(ast_text)
#> [1] "Some bold prose with a link. [Edited]"
#> [2] "Final words. [Edited]"
```

[`as_blocks()`](https://rundel.github.io/q2r/reference/ast_construct.md)
makes the multi-paragraph case equally short:

``` r

note = as_blocks(c(
  "First paragraph of an appended note.",
  "Second paragraph with more detail."
))

doc |>
  insert_after(is(pandoc_header) & level == 1L, .what = note@content) |>
  to_qmd() |>
  cat()
#> # Intro
#> 
#> First paragraph of an appended note.
#> 
#> Second paragraph with more detail.
#> 
#> Some **bold** prose with a [link](https://example.com).
#> 
#> ::: {.callout-note}
#> 
#> ## Watch out
#> 
#> A callout with its own *emphasised* heading.
#> 
#> :::
#> 
#> ## Conclusion
#> 
#> Final words.
```

## The tree-sitter side

Every verb above works on a \[`ts_tree`\] too. The mask exposes the
ts-specific slots (`kind`, `is_named`, `field_name`, `text`):

``` r

ts = pampa_parse(src, ast = "ts")

select_nodes(ts, kind == "atx_heading")
#> [[1]]
#> atx_heading
#> ├─atx_h1_marker "#"
#> └─pandoc_str "Intro"
#> 
#> [[2]]
#> atx_heading
#> ├─atx_h2_marker "##"
#> ├─pandoc_str "Watch"
#> ├─pandoc_space " "
#> ├─pandoc_str "out"
#> └─block_continuation
#> 
#> [[3]]
#> atx_heading
#> ├─atx_h2_marker "##"
#> └─pandoc_str "Conclusion"
```

For full structural pattern matching, captures, and predicates (`#eq?`,
`#match?`, …) there’s a
\[[`ts_query()`](https://rundel.github.io/q2r/reference/ts_query.md)\]
escape hatch that runs a tree-sitter `.scm` query directly:

``` r

matches = ts_query(ts, "(atx_heading) @h")
length(matches)
#> [1] 3
matches[[1]]$h
#> atx_heading
#> ├─atx_h1_marker "#"
#> └─pandoc_str "Intro"
```

## Round-trips

Rewriting produces a new AST of the same class as the input, so the
result feeds straight back into the renderer:

``` r

out = doc |>
  map_nodes(
    is(pandoc_header) & level == 1L,
    .f = \(h) pandoc_header(level = 2L, attr = h@attr, content = h@content)
  )

cat(to_qmd(out))
#> ## Intro
#> 
#> Some **bold** prose with a [link](https://example.com).
#> 
#> ::: {.callout-note}
#> 
#> ## Watch out
#> 
#> A callout with its own *emphasised* heading.
#> 
#> :::
#> 
#> ## Conclusion
#> 
#> Final words.
```
