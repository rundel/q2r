# q2r: R Interface to the pampa Quarto Parser

Exploratory R bindings to the `pampa` Rust crate from the quarto-dev/q2
project. See
[`pampa_parse_pd()`](https://rundel.github.io/q2r/reference/pampa_parse_pd.md)
and
[`pampa_parse_ts()`](https://rundel.github.io/q2r/reference/pampa_parse_ts.md).

## Package options

The following [`options()`](https://rdrr.io/r/base/options.html) tune
how `pandoc` / `ts_tree` are displayed. Each is read lazily at print
time, so changes take effect on the next
[`print()`](https://rdrr.io/r/base/print.html) call.

- `q2r.print_max_width`:

  Integer. Maximum number of characters used when rendering a node's
  `text` / `url` / `title` in the tree display. Longer strings are
  passed to
  [`stringr::str_trunc()`](https://stringr.tidyverse.org/reference/str_trunc.html).
  Default `40`.

- `q2r.print_trunc_side`:

  One of `"right"` (default), `"left"`, or `"center"`. Forwarded to the
  `side` argument of
  [`stringr::str_trunc()`](https://stringr.tidyverse.org/reference/str_trunc.html)
  to control where the ellipsis is inserted.

## See also

Useful links:

- <https://github.com/rundel/q2r>

- <https://rundel.github.io/q2r/>

- Report bugs at <https://github.com/rundel/q2r/issues>

## Author

**Maintainer**: Colin Rundel <cr173@duke.edu>

Authors:

- Colin Rundel <cr173@duke.edu>
