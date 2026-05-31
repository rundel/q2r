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
#' Nodes without an `@attr` slot are handled defensively: predicates
#' return `FALSE` / `""` / `NA`, setters error with a clear message.
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
#' - `get_attr(x, key)` / `set_attr(x, key, value)` /
#'   `remove_attr(x, key)` manipulate `@attr@attributes`. `get_attr()`
#'   returns `NA_character_` for missing keys.
#'
#' @param x A [`pandoc_node`] (typically one with an `@attr` slot).
#' @param cls A character vector of class names.
#' @param id A single string.
#' @param key A single string naming an attribute.
#' @param value A single string value.
#'
#' @return Predicates return a logical scalar (or a string, for getters).
#'   Setters return a node of the same class as `x`.
#'
#' @examples
#' \dontrun{
#' doc = pampa_parse("# title {.unnumbered}\n")
#' doc |> map_nodes(is(pandoc_header), .f = function(h) {
#'   h |> add_class("highlight") |> set_id("intro")
#' })
#' }
#'
#' @name ast_attr
NULL


# ---- internal helpers ---------------------------------------------------

ast_attr_get_slot = function(x, op) {
  if (!"attr" %in% S7::prop_names(x)) {
    stop("`", op, "()`: node of class <", S7::S7_class(x)@name,
         "> has no @attr slot.", call. = FALSE)
  }
  x@attr
}

ast_attr_set_slot = function(x, new_attr) {
  S7::prop(x, "attr") = new_attr
  x
}

ast_attr_maybe_get = function(x) {
  if (!"attr" %in% S7::prop_names(x)) NULL else x@attr
}


# ---- class manipulation -------------------------------------------------

#' @rdname ast_attr
#' @export
has_class = function(x, cls) {
  a = ast_attr_maybe_get(x)
  if (is.null(a)) return(FALSE)
  any(cls %in% a@classes)
}

#' @rdname ast_attr
#' @export
add_class = function(x, cls) {
  a = ast_attr_get_slot(x, "add_class")
  new_classes = unique(c(a@classes, cls))
  ast_attr_set_slot(x, pandoc_attr(
    id         = a@id,
    classes    = new_classes,
    attributes = a@attributes
  ))
}

#' @rdname ast_attr
#' @export
remove_class = function(x, cls) {
  a = ast_attr_get_slot(x, "remove_class")
  new_classes = setdiff(a@classes, cls)
  ast_attr_set_slot(x, pandoc_attr(
    id         = a@id,
    classes    = new_classes,
    attributes = a@attributes
  ))
}


# ---- id manipulation ----------------------------------------------------

#' @rdname ast_attr
#' @export
get_id = function(x) {
  a = ast_attr_maybe_get(x)
  if (is.null(a)) "" else a@id
}

#' @rdname ast_attr
#' @export
set_id = function(x, id) {
  if (!is.character(id) || length(id) != 1L) {
    stop("`set_id()`: `id` must be a single string.", call. = FALSE)
  }
  a = ast_attr_get_slot(x, "set_id")
  ast_attr_set_slot(x, pandoc_attr(
    id         = id,
    classes    = a@classes,
    attributes = a@attributes
  ))
}


# ---- generic attribute manipulation -------------------------------------

#' @rdname ast_attr
#' @export
get_attr = function(x, key) {
  a = ast_attr_maybe_get(x)
  if (is.null(a)) return(NA_character_)
  if (!(key %in% names(a@attributes))) return(NA_character_)
  unname(a@attributes[key])
}

#' @rdname ast_attr
#' @export
set_attr = function(x, key, value) {
  if (!is.character(key) || length(key) != 1L) {
    stop("`set_attr()`: `key` must be a single string.", call. = FALSE)
  }
  if (!is.character(value) || length(value) != 1L) {
    stop("`set_attr()`: `value` must be a single string.", call. = FALSE)
  }
  a = ast_attr_get_slot(x, "set_attr")
  new_attrs = a@attributes
  new_attrs[key] = value
  ast_attr_set_slot(x, pandoc_attr(
    id         = a@id,
    classes    = a@classes,
    attributes = new_attrs
  ))
}

#' @rdname ast_attr
#' @export
remove_attr = function(x, key) {
  a = ast_attr_get_slot(x, "remove_attr")
  new_attrs = a@attributes[!names(a@attributes) %in% key]
  ast_attr_set_slot(x, pandoc_attr(
    id         = a@id,
    classes    = a@classes,
    attributes = new_attrs
  ))
}
