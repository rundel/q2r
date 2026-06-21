# Render an AST to an output document with Quarto

**\[experimental\]**

## Usage

``` r
render_qmd(x, output_file = NULL, output_format = NULL, ..., quiet = FALSE)
```

## Arguments

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) or
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) AST.

- output_file:

  Destination path for the rendered output. Its directory and base name
  are used; the extension follows from the rendered format. If `NULL`,
  the output is written to the working directory as `document.<ext>`.

- output_format:

  Quarto output format (e.g. `"html"`, `"pdf"`), passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).
  `NULL` uses the document / Quarto default.

- ...:

  Further arguments passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

- quiet:

  Suppress Quarto's rendering output.

## Value

The path to the rendered output file, invisibly.

## Details

Writes an in-memory AST back to QMD with
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) and
renders it with
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html),
the q2r analog of parsermd's `render()`. The document is rendered inside
a temporary directory and the resulting artifacts (the rendered file
plus any `*_files/` resource directory) are copied to the destination,
so it never clobbers your working directory mid-render.

Because rendering happens in a temporary directory, relative resource
references in the document (local images, includes, `{{< include >}}`
shortcodes) will not resolve. This wrapper is intended for
self-contained documents.

Requires the `quarto` package (in `Suggests`) and a Quarto installation.

## Examples

``` r
if (FALSE) { # \dontrun{
doc = parse_qmd("# Title\n\nHello world.\n")
render_qmd(doc, "hello.html")
} # }
```
