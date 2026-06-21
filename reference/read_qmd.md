# Read, write, and edit QMD files

**\[experimental\]**

## Usage

``` r
read_qmd(path, ast = c("pd", "ts"), ...)

write_qmd(x, path)

edit_qmd(path, .f, ...)
```

## Arguments

- path:

  Path to a `.qmd` file.

- ast:

  Which AST to build, `"pd"` (Pandoc, default) or `"ts"` (tree-sitter);
  passed to
  [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md).

- ...:

  Further arguments passed to
  [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md).

- x:

  A [`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) or
  [`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md) object
  to render.

- .f:

  A function (or rlang formula) taking the parsed AST and returning the
  edited AST.

## Value

`read_qmd()` returns a
[`pandoc`](https://rundel.github.io/q2r/reference/pandoc.md) or
[`ts_tree`](https://rundel.github.io/q2r/reference/ts_point.md);
`write_qmd()` and `edit_qmd()` return the (edited) AST invisibly.

## Details

Thin file-oriented conveniences around
[`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md) and
[`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) that
close the parse-edit-write loop (parsermd's `as_document()` role):

- `read_qmd()` parses a file path (and, unlike
  [`parse_qmd()`](https://rundel.github.io/q2r/reference/parse_qmd.md),
  errors if the path does not exist rather than treating it as inline
  text).

- `write_qmd()` renders an AST with
  [`to_qmd()`](https://rundel.github.io/q2r/reference/to_qmd.md) and
  writes it verbatim, with no added trailing newline so the round trip
  stays byte-faithful. Returns its input invisibly so it can end a pipe.

- `edit_qmd()` is the in-place one-liner: read, apply `.f`, write back.

## Examples

``` r
path = tempfile(fileext = ".qmd")
writeLines("# Title\n\nSome text.\n", path)

read_qmd(path)
#> pandoc
#> ├─header level=1 (#title)
#> │ └─str "Title"
#> └─paragraph
#>   ├─str "Some"
#>   ├─space
#>   └─str "text."

edit_qmd(path, \(d) map_nodes(d, is(pandoc_header),
                              .f = \(h) add_class(h, "done")))
cat(readLines(path), sep = "\n")
#> # Title {.done}
#> 
#> Some text.
```
