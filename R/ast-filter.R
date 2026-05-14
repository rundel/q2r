#' @include pd-ast-pandoc.R pd-ast-block.R pd-ast-inline.R select.R select-pd.R pandoc-modify-children.R
NULL

#' Apply a table of type-keyed handlers to a pandoc AST
#'
#' `r lifecycle::badge("experimental")`
#'
#' Borrows the Pandoc Lua filter idiom of dispatching on element type:
#' the user provides one named function per S7 class to rewrite, and
#' `ast_filter()` walks the AST once, invoking the matching handler at
#' each node. Handlers honour the same return-value contract as
#' [`map_nodes()`] (return a node to replace, a `list` of nodes to
#' splice, `NULL` to delete, or the input to no-op).
#'
#' Dispatch is by S7 class with inheritance: a `pandoc_block = \(b) ...`
#' handler will run on every block subtype. When several handler names
#' match a node, the first listed in `...` wins, so put more specific
#' classes (e.g. `pandoc_header`) before more general ones
#' (`pandoc_block`).
#'
#' Traversal is post-order: a parent's handler sees its children after
#' they have been rewritten. This matches Pandoc Lua filters' default.
#'
#' @param x A [`pandoc`] document or any [`pandoc_node`].
#' @param ... Named functions, where each name is an exported S7 class
#'   (e.g. `pandoc_strong`, `pandoc_header`, `pandoc_block`).
#'
#' @return A rewritten value of the same outer shape as `x`.
#'
#' @examples
#' \dontrun{
#' doc = pampa_parse_pd("# Hello\n\n**bold** and *italic*\n")
#' doc |> ast_filter(
#'   pandoc_strong = \(el) pandoc_small_caps(el@content),
#'   pandoc_header = \(el) {
#'     if (el@level == 1L) {
#'       pandoc_header(level = 2L, content = el@content, attr = el@attr)
#'     } else el
#'   }
#' )
#' }
#'
#' @seealso [`map_nodes()`] for predicate-based rewriting,
#'   [`ast_text()`] for stringifying a subtree.
#' @export
ast_filter = S7::new_generic("ast_filter", "x", function(x, ...) {
  S7::S7_dispatch()
})


# ---- handler resolution -------------------------------------------------

# Resolve a list of named handler functions into a list of
# {class, fn} records. Class names are looked up first in the caller's
# environment, then in the q2r namespace, so users can pass classes from
# downstream packages too.
ast_filter_resolve_handlers = function(handlers, env) {
  if (length(handlers) == 0L) return(list())
  nms = names(handlers)
  if (is.null(nms) || any(!nzchar(nms))) {
    stop("All arguments to ast_filter() must be named with an S7 class name.",
         call. = FALSE)
  }
  if (anyDuplicated(nms)) {
    stop("Duplicate handler name in ast_filter(): ",
         paste(unique(nms[duplicated(nms)]), collapse = ", "),
         call. = FALSE)
  }
  purrr::imap(handlers, function(fn, name) {
    if (!is.function(fn) && !rlang::is_formula(fn)) {
      stop("ast_filter() handler '", name, "' must be a function or formula.",
           call. = FALSE)
    }
    cls_obj = get0(name, envir = env, inherits = TRUE)
    if (is.null(cls_obj)) {
      cls_obj = get0(name, envir = asNamespace("q2r"), inherits = FALSE)
    }
    if (is.null(cls_obj) || !inherits(cls_obj, "S7_class")) {
      stop("ast_filter(): '", name, "' does not resolve to an S7 class.",
           call. = FALSE)
    }
    list(class = cls_obj, fn = ast_as_fn(fn))
  })
}

# First-match-wins dispatch by S7 inheritance.
ast_filter_dispatch = function(node, resolved) {
  if (is.null(node) || length(resolved) == 0L) return(NULL)
  for (h in resolved) {
    if (S7::S7_inherits(node, h$class)) return(h$fn)
  }
  NULL
}


# ---- walker (post-order) ------------------------------------------------

# Mirrors pd_rewrite_node() but dispatches on class instead of a
# predicate set. Returns a value that the parent's
# pandoc_modify_children can splice / replace / delete via
# ast_to_node_list().
pd_filter_walk = function(node, resolved) {
  inner = function(child) pd_filter_walk(child, resolved)
  rebuilt = pandoc_modify_children(node, inner)
  handler = ast_filter_dispatch(rebuilt, resolved)
  if (is.null(handler)) rebuilt else handler(rebuilt)
}


# ---- methods ------------------------------------------------------------

S7::method(ast_filter, pandoc) = function(x, ...) {
  resolved = ast_filter_resolve_handlers(rlang::list2(...), parent.frame())
  out = pd_filter_walk(x, resolved)
  pd_finalize_root(x, out)
}

S7::method(ast_filter, pandoc_node) = function(x, ...) {
  resolved = ast_filter_resolve_handlers(rlang::list2(...), parent.frame())
  pd_filter_walk(x, resolved)
}
