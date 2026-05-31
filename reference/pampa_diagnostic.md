# Parse diagnostic produced by the pampa parser

Structured representation of a single diagnostic message returned by the
Quarto parser. Pretty-printed output is generated on demand by the
[`format()`](https://rdrr.io/r/base/format.html)/[`print()`](https://rdrr.io/r/base/print.html)
methods (which hand the structured fields back to the Rust renderer).

## Usage

``` r
pampa_diagnostic(
  kind = "error",
  code = NA_character_,
  title = "",
  problem = NULL,
  details = list(),
  hints = character(0),
  location = NULL,
  source_text = "",
  source_filename = "<text>"
)
```

## Slots

- `kind`:

  One of `"error"`, `"warning"`, `"info"`, `"note"`.

- `code`:

  Optional error code (e.g. `"Q-1-1"`), or `NA`.

- `title`:

  Brief title.

- `problem`:

  Optional problem statement as a list
  `list(format = "plain" | "markdown", text = <chr>)`, or `NULL`.

- `details`:

  List of detail records, each a list with `kind`, `content` (same shape
  as `problem`), and optional `location`.

- `hints`:

  Character vector of hint strings.

- `location`:

  Optional source location, a named list with `file`, `start_offset`,
  `start_row`, `start_column`, `end_offset`, `end_row`, `end_column`.
  `NULL` if no location is attached.

- `source_text`:

  Original input text the parser saw. Carried so the diagnostic can be
  re-rendered against its source.

- `source_filename`:

  Filename shown in the rendered output.
