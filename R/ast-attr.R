#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R pd-ast-support.R
NULL


#' Attribute manipulation helpers
#'
#' `r lifecycle::badge("experimental")`
#'
#' Concise getters and setters for the [`pandoc_attr`] slot found on
#' many pandoc node types ([`pandoc_header`], [`pandoc_div`],
#' [`pandoc_code`], [`pandoc_link`], [`pandoc_image`], [`pandoc_span`],
#' etc.). Modelled on Pandoc Lua filters' direct field access
#' (`el.classes`, `el.identifier`, `el.attributes`) but using R's
#' immutable value semantics: every setter returns a new node, the
#' input is never modified.
#'
#' Nodes without a standard `@attr` slot are handled defensively: the
#' getters return `FALSE` / `""` / `NA` (including nodes such as ordered
#' and bullet lists, whose `@attr` is a `pandoc_list_attributes` rather
#' than a [`pandoc_attr`]), while setters error with a clear message.
#'
#' @section Available helpers:
#' - `has_class(x, cls)` `TRUE` if any of `cls` is in `@attr@classes`.
#'   When used inside a [`select_nodes()`] / [`map_nodes()`] predicate,
#'   the data-mask version is bound to the current node automatically;
#'   the exported version here takes the node as its first argument.
#' - `add_class(x, cls)` add one or more classes (idempotent: classes
#'   already present are not duplicated).
#' - `remove_class(x, cls)` remove one or more classes; no-op on
#'   classes that are not present.
#' - `get_id(x)` / `set_id(x, id)` read or replace `@attr@id`.
#' - `get_attr(x, key)` reads a single attribute, returning
#'   `NA_character_` for missing keys.
#' - `set_attr(x, key = value, ...)` sets one or more attributes from
#'   named `key = value` pairs. A `value` of `NULL` removes that key
#'   (the named map's idiomatic R removal, mirroring Lua's
#'   `el.attributes[key] = nil`), so a single call can both set and
#'   drop: `set_attr(x, target = "_blank", lang = NULL)`.
#'
#' @param x A [`pandoc_node`] (typically one with an `@attr` slot).
#' @param cls A character vector of class names.
#' @param id A single string.
#' @param key A single string naming an attribute (for `get_attr()`).
#' @param ... For `set_attr()`, named `key = value` pairs; each `value`
#'   is a single string, or `NULL` to remove that key. Quote names that
#'   are not syntactic R identifiers (e.g. `"data-level" = "2"`), and
#'   use rlang's `!!!` / `:=` to supply dynamic keys.
#'
#' @return Predicates return a logical scalar (or a string, for getters).
#'   Setters return a node of the same class as `x`.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# title {.unnumbered}\n")
#' doc |> map_nodes(is(pandoc_header), .f = function(h) {
#'   h |> add_class("highlight") |> set_id("intro")
#' })
#' }
#'
#' @name ast_attr
NULL


# ---- internal helpers ---------------------------------------------------

ast_attr_maybe_get = function(x) {
  if (!"attr" %in% S7::prop_names(x)) NULL else x@attr
}

# Read a node's `@attr` for a setter. Errors when the node has no `@attr`
# slot, or carries a non-standard attribute shape (e.g. the
# `pandoc_list_attributes` on ordered/bullet lists) that has no
# id/classes/attributes to modify, rather than reaching into an absent
# slot and surfacing an opaque internal S7 error.
ast_attr_get_slot = function(x, op) {
  if (!"attr" %in% S7::prop_names(x)) {
    stop("`", op, "()`: node of class <", S7::S7_class(x)@name,
         "> has no @attr slot.", call. = FALSE)
  }
  a = x@attr
  if (!S7::S7_inherits(a, pandoc_attr)) {
    stop("`", op, "()`: node of class <", S7::S7_class(x)@name,
         "> has a non-standard @attr (<", S7::S7_class(a)@name,
         ">) with no id/classes/attributes to modify.", call. = FALSE)
  }
  a
}

ast_attr_set_slot = function(x, new_attr) {
  S7::prop(x, "attr") = new_attr
  x
}

# Rebuild a node's `pandoc_attr`, leaving unspecified fields unchanged.
ast_attr_modify = function(x, a, id, classes, attributes) {
  ast_attr_set_slot(x, pandoc_attr(
    id         = if (missing(id)) a@id else id,
    classes    = if (missing(classes)) a@classes else classes,
    attributes = if (missing(attributes)) a@attributes else attributes
  ))
}

# Type-guarded readers shared with the predicate-mask helpers in select.R:
# each returns its no-match value (FALSE / "" / NA) when `a` is not a
# `pandoc_attr`, covering both NULL and `pandoc_list_attributes`.
attr_has_class = function(a, cls) {
  if (!S7::S7_inherits(a, pandoc_attr) || length(cls) == 0L) return(FALSE)
  any(cls %in% a@classes)
}

attr_get_id = function(a) {
  if (!S7::S7_inherits(a, pandoc_attr)) "" else a@id
}

attr_get = function(a, key) {
  if (!S7::S7_inherits(a, pandoc_attr)) return(NA_character_)
  if (!(key %in% names(a@attributes))) return(NA_character_)
  unname(a@attributes[key])
}


# ---- class manipulation -------------------------------------------------

#' @rdname ast_attr
#' @export
has_class = function(x, cls) {
  attr_has_class(ast_attr_maybe_get(x), cls)
}

#' @rdname ast_attr
#' @export
add_class = function(x, cls) {
  a = ast_attr_get_slot(x, "add_class")
  ast_attr_modify(x, a, classes = unique(c(a@classes, cls)))
}

#' @rdname ast_attr
#' @export
remove_class = function(x, cls) {
  a = ast_attr_get_slot(x, "remove_class")
  ast_attr_modify(x, a, classes = setdiff(a@classes, cls))
}


# ---- id manipulation ----------------------------------------------------

#' @rdname ast_attr
#' @export
get_id = function(x) {
  attr_get_id(ast_attr_maybe_get(x))
}

#' @rdname ast_attr
#' @export
set_id = function(x, id) {
  if (!is.character(id) || length(id) != 1L) {
    stop("`set_id()`: `id` must be a single string.", call. = FALSE)
  }
  a = ast_attr_get_slot(x, "set_id")
  ast_attr_modify(x, a, id = id)
}


# ---- generic attribute manipulation -------------------------------------

#' @rdname ast_attr
#' @export
get_attr = function(x, key) {
  attr_get(ast_attr_maybe_get(x), key)
}

#' @rdname ast_attr
#' @export
set_attr = function(x, ...) {
  pairs = rlang::list2(...)
  nms = names(pairs)
  if (length(pairs) && (is.null(nms) || !all(nzchar(nms)))) {
    stop("`set_attr()`: attributes must be supplied as named `key = value` pairs.",
         call. = FALSE)
  }
  a = ast_attr_get_slot(x, "set_attr")
  new_attrs = a@attributes
  for (i in seq_along(pairs)) {
    value = pairs[[i]]
    if (!is.null(value) && (!is.character(value) || length(value) != 1L)) {
      stop("`set_attr()`: `", nms[[i]],
           "` must be a single string, or NULL to remove it.", call. = FALSE)
    }
    if (is.null(value)) {
      new_attrs = new_attrs[names(new_attrs) != nms[[i]]]
    } else {
      new_attrs[nms[[i]]] = value
    }
  }
  ast_attr_modify(x, a, attributes = new_attrs)
}
