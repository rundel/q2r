#' q2r: R Interface to the pampa Quarto Parser
#'
#' Exploratory R bindings to the `pampa` Rust crate from the
#' quarto-dev/q2 project. See [`pampa_parse()`].
#'
#' @section Package options:
#' The following [`options()`] tune how `pandoc` / `ts_tree` are
#' displayed. Each is read lazily at print time, so changes take
#' effect on the next `print()` call.
#'
#' \describe{
#'   \item{`q2r.print_max_width`}{Integer. Maximum number of
#'     characters used when rendering a node's `text` / `url` /
#'     `title` in the tree display. Longer strings are passed to
#'     [`stringr::str_trunc()`]. Default `40`.}
#'   \item{`q2r.print_trunc_side`}{One of `"right"` (default),
#'     `"left"`, or `"center"`. Forwarded to the `side` argument of
#'     [`stringr::str_trunc()`] to control where the ellipsis is
#'     inserted.}
#' }
#'
#' @keywords internal
"_PACKAGE"
