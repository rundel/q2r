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
#' Traversal is post-order by default: a parent's handler sees its
#' children after they have been rewritten. This matches Pandoc Lua
#' filters' default. Pass `.order = "pre"` for a top-down walk in which
#' a parent's handler runs first; from a pre-order handler, return
#' [`ast_skip()`] to use the (possibly modified) node as-is without
#' descending into its children. This mirrors Lua filters'
#' `traverse = 'topdown'` plus `return el, false`.
#'
#' Two special handler names trigger list-level dispatch on entire
#' inline/block sequences (Lua's `Inlines` / `Blocks` filters):
#' - `pandoc_inlines = \(xs) ...` is called once per [`pandoc_inlines`]
#'   wrapper after its contents have been rewritten. Return a
#'   `pandoc_inlines` (or a `list` of inlines, or `NULL` for empty).
#' - `pandoc_blocks = \(xs) ...` is the equivalent for [`pandoc_blocks`].
#' These are useful for sliding-window / context-aware transforms that
#' cannot be expressed at single-element level (e.g. merging adjacent
#' runs, dropping siblings based on neighbours).
#'
#' @param x A [`pandoc`] document or any [`pandoc_node`].
#' @param ... Named functions, where each name is an exported S7 class
#'   (e.g. `pandoc_strong`, `pandoc_header`, `pandoc_block`).
#' @param .order Traversal direction: `"post"` (default, children
#'   rewritten before parent's handler runs) or `"pre"` (parent's
#'   handler runs first; wrap the return value with [`ast_skip()`] to
#'   skip descent).
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

# Resolve a list of named handler functions into a structured record:
#   { node = list_of_{class,fn},
#     blocks_hook = NULL or fn,
#     inlines_hook = NULL or fn }
# pandoc_blocks / pandoc_inlines are NOT visited as nodes by the
# walker (they are content wrappers), so handlers for them are split
# out as wrapper hooks that fire on rebuilt wrapper slots.
ast_filter_resolve_handlers = function(handlers, env) {
  empty = list(node = list(), blocks_hook = NULL, inlines_hook = NULL)
  if (length(handlers) == 0L) return(empty)
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
  out = empty
  for (i in seq_along(handlers)) {
    fn = handlers[[i]]
    name = nms[[i]]
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
    fn_val = ast_as_fn(fn)
    if (identical(name, "pandoc_inlines")) {
      out$inlines_hook = fn_val
    } else if (identical(name, "pandoc_blocks")) {
      out$blocks_hook = fn_val
    } else {
      out$node[[length(out$node) + 1L]] = list(class = cls_obj, fn = fn_val)
    }
  }
  out
}

# First-match-wins dispatch by S7 inheritance against the node handlers.
ast_filter_dispatch = function(node, resolved) {
  if (is.null(node) || length(resolved$node) == 0L) return(NULL)
  for (h in resolved$node) {
    if (S7::S7_inherits(node, h$class)) return(h$fn)
  }
  NULL
}


# ---- list-level wrapper hooks -------------------------------------------

# Walk a rebuilt node's properties and replace any pandoc_inlines /
# pandoc_blocks slot (or list of same) with the result of the
# corresponding wrapper hook. Uses property-name reflection so no
# per-class methods are required.
pd_apply_wrapper_hooks = function(node, resolved) {
  blocks_hook  = resolved$blocks_hook
  inlines_hook = resolved$inlines_hook
  if (is.null(blocks_hook) && is.null(inlines_hook)) return(node)
  if (is.null(node) || !S7::S7_inherits(node, S7::S7_object)) return(node)
  pnames = tryCatch(S7::prop_names(node), error = function(e) character())
  for (nm in pnames) {
    val = tryCatch(S7::prop(node, nm), error = function(e) NULL)
    new_val = pd_wrapper_hook_apply(val, blocks_hook, inlines_hook)
    if (!identical(new_val, val)) {
      S7::prop(node, nm) = new_val
    }
  }
  node
}

pd_wrapper_hook_apply = function(val, blocks_hook, inlines_hook) {
  if (!is.null(inlines_hook) && S7::S7_inherits(val, pandoc_inlines)) {
    return(pd_call_wrapper_hook(inlines_hook, val, pandoc_inlines, "pandoc_inlines"))
  }
  if (!is.null(blocks_hook) && S7::S7_inherits(val, pandoc_blocks)) {
    return(pd_call_wrapper_hook(blocks_hook, val, pandoc_blocks, "pandoc_blocks"))
  }
  if (is.list(val) && length(val) > 0L &&
      !S7::S7_inherits(val, pandoc_node) &&
      !S7::S7_inherits(val, pandoc_inlines) &&
      !S7::S7_inherits(val, pandoc_blocks)) {
    if (!is.null(inlines_hook) &&
        all(purrr::map_lgl(val, S7::S7_inherits, pandoc_inlines))) {
      return(purrr::map(val, function(w) {
        pd_call_wrapper_hook(inlines_hook, w, pandoc_inlines, "pandoc_inlines")
      }))
    }
    if (!is.null(blocks_hook) &&
        all(purrr::map_lgl(val, S7::S7_inherits, pandoc_blocks))) {
      return(purrr::map(val, function(w) {
        pd_call_wrapper_hook(blocks_hook, w, pandoc_blocks, "pandoc_blocks")
      }))
    }
  }
  val
}

pd_call_wrapper_hook = function(hook, wrapper, expected_class, expected_name) {
  out = hook(wrapper)
  if (is.null(out)) return(expected_class(list()))
  if (is.list(out) && !S7::S7_inherits(out, expected_class)) {
    return(expected_class(out))
  }
  if (!S7::S7_inherits(out, expected_class)) {
    stop("ast_filter() handler '", expected_name,
         "' must return a ", expected_name,
         " wrapper (or NULL / list of nodes); got <",
         paste(class(out), collapse = "/"), ">.", call. = FALSE)
  }
  out
}


# ---- walker (post-order) ------------------------------------------------

# Mirrors pd_rewrite_node() but dispatches on class instead of a
# predicate set. Returns a value that the parent's
# pandoc_modify_children can splice / replace / delete via
# ast_to_node_list(). After children are rebuilt, list-level wrapper
# hooks are applied to any pandoc_inlines / pandoc_blocks slots before
# the node's own handler runs.
pd_filter_walk = function(node, resolved) {
  inner = function(child) pd_filter_walk(child, resolved)
  rebuilt = pandoc_modify_children(node, inner)
  rebuilt = pd_apply_wrapper_hooks(rebuilt, resolved)
  handler = ast_filter_dispatch(rebuilt, resolved)
  if (is.null(handler)) rebuilt else handler(rebuilt)
}


# ---- walker (pre-order) -------------------------------------------------

# Top-down: handler runs on `node` before children are visited. A
# handler may return:
#   - ast_skip(x):     replace with x, do not descend (no wrapper hooks)
#   - NULL:            delete (no descent)
#   - list(...):       splice (no descent into the original)
#   - a single node:   replace and continue descending into the result
#   - the input node:  no-op; descend into the original's children
# After descent, wrapper hooks run on the rebuilt wrapper slots.
pd_filter_walk_pre = function(node, resolved) {
  handler = ast_filter_dispatch(node, resolved)
  if (!is.null(handler)) {
    result = handler(node)
    if (is_ast_skip(result)) return(ast_skip_unwrap(result))
    if (is.null(result)) return(NULL)
    if (is.list(result) &&
        !S7::S7_inherits(result, pandoc_node) &&
        !S7::S7_inherits(result, pandoc)) {
      return(result)
    }
    node = result
  }
  inner = function(child) pd_filter_walk_pre(child, resolved)
  rebuilt = pandoc_modify_children(node, inner)
  pd_apply_wrapper_hooks(rebuilt, resolved)
}


# ---- ast_skip sentinel --------------------------------------------------

#' Mark a value as "use as-is, do not descend" inside ast_filter()
#'
#' `r lifecycle::badge("experimental")`
#'
#' Sentinel for use inside an [`ast_filter()`] pre-order handler. When
#' a handler returns `ast_skip(x)`, the walker installs `x` at that
#' position and stops descending into its children. Equivalent to
#' Pandoc Lua filters' `return el, false` under `traverse = 'topdown'`.
#'
#' Has no effect under the default post-order traversal (where descent
#' has already happened by the time a handler runs).
#'
#' @param x A pandoc node, or `NULL`.
#' @return A small marker object recognised by [`ast_filter()`].
#' @seealso [`ast_filter()`]
#' @export
ast_skip = function(x) {
  structure(list(node = x), class = "q2r_ast_skip")
}

is_ast_skip = function(x) inherits(x, "q2r_ast_skip")

ast_skip_unwrap = function(x) x$node


# ---- methods ------------------------------------------------------------

ast_filter_pick_walker = function(order) {
  order = match.arg(order, c("post", "pre"))
  if (order == "post") pd_filter_walk else pd_filter_walk_pre
}

S7::method(ast_filter, pandoc) = function(x, ..., .order = c("post", "pre")) {
  walker = ast_filter_pick_walker(.order)
  resolved = ast_filter_resolve_handlers(rlang::list2(...), parent.frame())
  out = walker(x, resolved)
  pd_finalize_root(x, out)
}

S7::method(ast_filter, pandoc_node) = function(x, ..., .order = c("post", "pre")) {
  walker = ast_filter_pick_walker(.order)
  resolved = ast_filter_resolve_handlers(rlang::list2(...), parent.frame())
  walker(x, resolved)
}
