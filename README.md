

<!-- README.md is generated from README.qmd. Please edit that file -->

# q2r

<!-- badges: start -->

<!-- badges: end -->

`q2r` is an exploratory R package that wraps the
[`pampa`](https://github.com/quarto-dev/q2) Rust crate to expose
Quarto’s QMD parser to R. It parses QMD text or files and returns either
the tree-sitter concrete syntax tree or the Pandoc AST, together with
any parse diagnostics.

## Installation

`q2r` is not on CRAN. You can install the development version from
GitHub with:

``` r
# install.packages("pak")
pak::pak("rundel/q2r")
```

Building from source requires a working Rust toolchain with
`rustc >= 1.85` (edition 2024). [`rustup`](https://rustup.rs/) is the
most reliable way to get this. The first build fetches the upstream `q2`
workspace (~40 crates) via cargo; subsequent builds use the cargo cache.

## Usage

The two main entry points are `pampa_parse_pd()`, which returns a
`pandoc` S7 object holding the Pandoc AST, and `pampa_parse_ts()`, which
returns a `ts_tree` S7 object holding the tree-sitter concrete syntax
tree. Both accept either a file path or a string of QMD text, and attach
any parse diagnostics to the returned object’s `@diagnostics` slot.

``` r
library(q2r)
```

``` r
qmd = "---
title: Example
---

# Heading

Some *emphasized* text with a [link](https://example.com).
"
```

### Pandoc AST

``` r
pd = pampa_parse_pd(qmd)
pd
#> pandoc
#> ├─header level=1 (#heading)
#> │ └─str "Heading"
#> └─paragraph
#>   ├─str "Some"
#>   ├─space
#>   ├─emph
#>   │ └─str "emphasized"
#>   ├─space
#>   ├─str "text"
#>   ├─space
#>   ├─str "with"
#>   ├─space
#>   ├─str "a"
#>   ├─space
#>   ├─link url="https://example.com"
#>   │ └─str "link"
#>   └─str "."
```

### Tree-sitter AST

``` r
ts = pampa_parse_ts(qmd)
ts
#> ts_tree language=qmd
#> └─document (0, 0) - (7, 0)
#>   ├─metadata (0, 0) - (3, 0) "---\ntitle: Example\n---\n"
#>   ├─section (3, 0) - (4, 0) "\n"
#>   └─section (4, 0) - (7, 0)
#>     ├─atx_heading (4, 0) - (5, 0)
#>     │ ├─atx_h1_marker (4, 0) - (4, 1) "#"
#>     │ └─pandoc_str (4, 2) - (4, 9) "Heading"
#>     └─pandoc_paragraph (6, 0) - (7, 0)
#>       ├─pandoc_str (6, 0) - (6, 4) "Some"
#>       ├─pandoc_emph (6, 4) - (6, 17)
#>       │ ├─emphasis_delimiter (6, 4) - (6, 6) " *"
#>       │ ├─pandoc_str (6, 6) - (6, 16) "emphasized"
#>       │ └─emphasis_delimiter (6, 16) - (6, 17) "*"
#>       ├─pandoc_space (6, 17) - (6, 18) " "
#>       ├─pandoc_str (6, 18) - (6, 22) "text"
#>       ├─pandoc_space (6, 22) - (6, 23) " "
#>       ├─pandoc_str (6, 23) - (6, 27) "with"
#>       ├─pandoc_space (6, 27) - (6, 28) " "
#>       ├─pandoc_str (6, 28) - (6, 29) "a"
#>       ├─pandoc_space (6, 29) - (6, 30) " "
#>       ├─pandoc_span (6, 30) - (6, 57)
#>       │ ├─"[" (6, 30) - (6, 31) "["
#>       │ ├─content (6, 31) - (6, 35)
#>       │ │ └─pandoc_str (6, 31) - (6, 35) "link"
#>       │ └─target (6, 35) - (6, 57)
#>       │   ├─url (6, 37) - (6, 56) "https://example.com"
#>       │   └─")" (6, 56) - (6, 57) ")"
#>       └─pandoc_str (6, 57) - (6, 58) "."
```

### Rendering back to QMD

`pampa_to_qmd()` renders a parsed AST (or text / file path) back to QMD
source via pampa’s writer.

``` r
cat(pampa_to_qmd(pd))
#> # Heading
#> 
#> Some *emphasized* text with a [link](https://example.com).
```

### Diagnostics

Parse errors and warnings are returned as structured `pampa_diagnostic`
objects attached to the parsed result. By default `pampa_parse_*()`
signals error-kind diagnostics as R errors and warning-kind diagnostics
as R warnings; pass `quiet = TRUE` to suppress signalling and inspect
them directly.

``` r
bad = pampa_parse_pd("::: {.callout-note\nunterminated\n", quiet = TRUE)
bad@diagnostics
#> [[1]]
#> Error: Parse error
#>    ╭─[ <text>:2:1 ]
#>    │
#>  2 │ unterminated
#>    │ ──────┬─────  
#>    │       ╰─────── unexpected character or token here
#> ───╯
```

## Related

- [`quarto-dev/q2`](https://github.com/quarto-dev/q2) — upstream Rust
  workspace containing `pampa` and the tree-sitter-qmd grammar.
