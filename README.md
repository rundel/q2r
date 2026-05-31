

<!-- README.md is generated from README.qmd. Please edit that file -->

# q2r

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

`q2r` is an exploratory R package that wraps the
[`pampa`](https://github.com/quarto-dev/q2) Rust crate to expose
Quarto’s QMD parser to R. It parses QMD text or files and returns either
the tree-sitter AST or the Pandoc AST, together with any parse
diagnostics.

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
#> └─document
#>   ├─metadata "---\ntitle: Example\n---\n"
#>   ├─section "\n"
#>   └─section
#>     ├─atx_heading
#>     │ ├─atx_h1_marker "#"
#>     │ └─pandoc_str "Heading"
#>     └─pandoc_paragraph
#>       ├─pandoc_str "Some"
#>       ├─pandoc_emph
#>       │ ├─emphasis_delimiter " *"
#>       │ ├─pandoc_str "emphasized"
#>       │ └─emphasis_delimiter "*"
#>       ├─pandoc_space " "
#>       ├─pandoc_str "text"
#>       ├─pandoc_space " "
#>       ├─pandoc_str "with"
#>       ├─pandoc_space " "
#>       ├─pandoc_str "a"
#>       ├─pandoc_space " "
#>       ├─pandoc_span
#>       │ ├─"[" "["
#>       │ ├─content
#>       │ │ └─pandoc_str "link"
#>       │ └─target
#>       │   ├─url "https://example.com"
#>       │   └─")" ")"
#>       └─pandoc_str "."
```

### Rendering back to QMD

`to_qmd()` renders a parsed AST (a `pandoc` or `ts_tree` object) back to
QMD source. A `pandoc` object is written by pampa’s QMD writer; a
`ts_tree` is recovered from its source bytes.

``` r
cat(to_qmd(pd))
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
bad = pampa_parse_pd(
  "# Heading {.cls bad}

See [my page](https://example.com/some path) for details.
"
)
#> Error:
#> ! Error: Parse error
#>    ╭─[ <text>:1:17 ]
#>    │
#>  1 │ # Heading {.cls bad}
#>    │                 ─┬─  
#>    │                  ╰─── unexpected character or token here
#> ───╯
#> 
#> Error: [Q-2-33] Spaces in link targets
#>    ╭─[ <text>:3:40 ]
#>    │
#>  3 │ See [my page](https://example.com/some path) for details.
#>    │                                        ──┬─  
#>    │                                          ╰─── Link targets cannot contain spaces. Replace spaces with %20.
#> ───╯
```

## Related

- [`quarto-dev/q2`](https://github.com/quarto-dev/q2) — upstream Rust
  workspace containing `pampa` and the tree-sitter-qmd grammar.
