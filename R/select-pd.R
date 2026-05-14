#' @include select.R pandoc-modify-children.R pd-ast-pandoc.R pd-ast-print.R
NULL

# ---- read-side walker ---------------------------------------------------

# Depth-first pre-order walk that calls `visit` on each "selectable"
# node. `pandoc_blocks` / `pandoc_inlines` wrappers and plain R lists are
# transparent: their elements are visited, not the wrapper itself.
pd_walk_node = function(node, visit) {
  visit(node)
  pd_walk_children(node, visit)
}

pd_walk_children = function(node, visit) {
  if (S7::S7_inherits(node, pandoc)) {
    pd_walk_children_of_list(node@blocks@content, visit)
    return(invisible())
  }
  kids = tryCatch(pandoc_children(node), error = function(e) list())
  if (length(kids) == 0L) return(invisible())
  purrr::walk(kids, function(child) {
    if (is.null(child)) return()
    if (S7::S7_inherits(child, pandoc_blocks) ||
        S7::S7_inherits(child, pandoc_inlines)) {
      pd_walk_children_of_list(child@content, visit)
      return()
    }
    if (is.list(child) && !S7::S7_inherits(child, pandoc_node)) {
      purrr::walk(child, function(sub) {
        if (is.null(sub)) return()
        if (S7::S7_inherits(sub, pandoc_blocks) ||
            S7::S7_inherits(sub, pandoc_inlines)) {
          pd_walk_children_of_list(sub@content, visit)
        } else {
          pd_walk_node(sub, visit)
        }
      })
      return()
    }
    pd_walk_node(child, visit)
  })
}

pd_walk_children_of_list = function(items, visit) {
  purrr::walk(items, function(it) {
    if (is.null(it)) return()
    pd_walk_node(it, visit)
  })
}

pd_collect_matches = function(root, quos, mask, include_root) {
  out = list()
  visitor = function(node) {
    if (ast_eval_predicates(quos, node, mask, "pandoc")) {
      out[[length(out) + 1L]] <<- node
    }
  }
  if (include_root) {
    pd_walk_node(root, visitor)
  } else {
    pd_walk_children(root, visitor)
  }
  out
}

pd_first_match = function(root, quos, mask, include_root) {
  found = NULL
  visitor = function(node) {
    if (!is.null(found)) return()
    if (ast_eval_predicates(quos, node, mask, "pandoc")) {
      found <<- node
    }
  }
  if (include_root) {
    pd_walk_node(root, visitor)
  } else {
    pd_walk_children(root, visitor)
  }
  found
}


# ---- write-side walker --------------------------------------------------

# Post-order rewrite: descend via `pandoc_modify_children`, then check
# the predicate on the (possibly rebuilt) node and apply `.f` to a match.
# Returns the rewritten node, a list of nodes (when `.f` splices), or
# NULL (when `.f` deletes).
pd_rewrite_node = function(node, quos, mask, .f) {
  inner = function(child) pd_rewrite_node(child, quos, mask, .f)
  rebuilt = pandoc_modify_children(node, inner)
  if (ast_eval_predicates(quos, rebuilt, mask, "pandoc")) {
    return(.f(rebuilt))
  }
  rebuilt
}

# Variant for the document root: a result that's a list or NULL is
# illegal at the very top (the document must remain a `pandoc`).
pd_finalize_root = function(orig, result) {
  if (is.null(result)) {
    return(pandoc(meta = orig@meta,
                  blocks = pandoc_blocks(list()),
                  diagnostics = orig@diagnostics))
  }
  if (is.list(result) && !S7::S7_inherits(result, pandoc_node)) {
    stop("map_nodes on a pandoc document root returned a list; the document ",
         "root cannot be spliced. Wrap the result in a single pandoc().",
         call. = FALSE)
  }
  if (!S7::S7_inherits(result, pandoc)) {
    stop("map_nodes on a pandoc document root must return a `pandoc` object.",
         call. = FALSE)
  }
  result
}


# ---- select_nodes -------------------------------------------------------

S7::method(select_nodes, pandoc) = function(x, ...) {
  quos = ast_quos(...)
  pd_collect_matches(x, quos, ast_make_mask("pandoc"), include_root = TRUE)
}

S7::method(select_nodes, pandoc_node) = function(x, ...) {
  quos = ast_quos(...)
  pd_collect_matches(x, quos, ast_make_mask("pandoc"), include_root = TRUE)
}

S7::method(select_nodes, pandoc_blocks) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  out = list()
  visitor = function(node) {
    if (ast_eval_predicates(quos, node, mask, "pandoc")) {
      out[[length(out) + 1L]] <<- node
    }
  }
  pd_walk_children_of_list(x@content, visitor)
  out
}

S7::method(select_nodes, pandoc_inlines) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  out = list()
  visitor = function(node) {
    if (ast_eval_predicates(quos, node, mask, "pandoc")) {
      out[[length(out) + 1L]] <<- node
    }
  }
  pd_walk_children_of_list(x@content, visitor)
  out
}


# ---- select_descendants -------------------------------------------------

S7::method(select_descendants, pandoc) = function(x, ...) {
  quos = ast_quos(...)
  pd_collect_matches(x, quos, ast_make_mask("pandoc"), include_root = FALSE)
}

S7::method(select_descendants, pandoc_node) = function(x, ...) {
  quos = ast_quos(...)
  pd_collect_matches(x, quos, ast_make_mask("pandoc"), include_root = FALSE)
}

S7::method(select_descendants, pandoc_blocks) = function(x, ...) {
  select_nodes(x, ...)
}

S7::method(select_descendants, pandoc_inlines) = function(x, ...) {
  select_nodes(x, ...)
}


# ---- select_children ----------------------------------------------------
# Direct children only. For pandoc nodes, the children come from
# `pandoc_children()`, transparently flattened across wrapper objects.

pd_collect_direct_children = function(node) {
  if (S7::S7_inherits(node, pandoc)) {
    return(node@blocks@content)
  }
  kids = tryCatch(pandoc_children(node), error = function(e) list())
  out = list()
  purrr::walk(kids, function(child) {
    if (is.null(child)) return()
    if (S7::S7_inherits(child, pandoc_blocks) ||
        S7::S7_inherits(child, pandoc_inlines)) {
      out <<- c(out, child@content)
      return()
    }
    if (is.list(child) && !S7::S7_inherits(child, pandoc_node)) {
      purrr::walk(child, function(sub) {
        if (is.null(sub)) return()
        if (S7::S7_inherits(sub, pandoc_blocks) ||
            S7::S7_inherits(sub, pandoc_inlines)) {
          out <<- c(out, sub@content)
        } else {
          out[[length(out) + 1L]] <<- sub
        }
      })
      return()
    }
    out[[length(out) + 1L]] <<- child
  })
  out
}

S7::method(select_children, pandoc) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  purrr::keep(pd_collect_direct_children(x), function(c) {
    ast_eval_predicates(quos, c, mask, "pandoc")
  })
}

S7::method(select_children, pandoc_node) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  purrr::keep(pd_collect_direct_children(x), function(c) {
    ast_eval_predicates(quos, c, mask, "pandoc")
  })
}

S7::method(select_children, pandoc_blocks) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  purrr::keep(x@content, function(c) {
    ast_eval_predicates(quos, c, mask, "pandoc")
  })
}

S7::method(select_children, pandoc_inlines) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  purrr::keep(x@content, function(c) {
    ast_eval_predicates(quos, c, mask, "pandoc")
  })
}


# ---- select_first -------------------------------------------------------

S7::method(select_first, pandoc) = function(x, ...) {
  quos = ast_quos(...)
  pd_first_match(x, quos, ast_make_mask("pandoc"), include_root = TRUE)
}

S7::method(select_first, pandoc_node) = function(x, ...) {
  quos = ast_quos(...)
  pd_first_match(x, quos, ast_make_mask("pandoc"), include_root = TRUE)
}


# ---- walk_nodes ---------------------------------------------------------

S7::method(walk_nodes, pandoc) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("walk_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  pd_walk_node(x, function(node) {
    if (ast_eval_predicates(quos, node, mask, "pandoc")) fn(node)
  })
  invisible(x)
}

S7::method(walk_nodes, pandoc_node) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("walk_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  mask = ast_make_mask("pandoc")
  pd_walk_node(x, function(node) {
    if (ast_eval_predicates(quos, node, mask, "pandoc")) fn(node)
  })
  invisible(x)
}


# ---- map_nodes ----------------------------------------------------------

S7::method(map_nodes, pandoc) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("map_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  out = pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
  pd_finalize_root(x, out)
}

S7::method(map_nodes, pandoc_node) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("map_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
}


# ---- replace_nodes / delete_nodes / splice_nodes ------------------------

S7::method(replace_nodes, pandoc) = function(x, ..., .with) {
  quos = ast_quos(...)
  fn = function(node) ast_resolve_what(.with, node)
  out = pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
  pd_finalize_root(x, out)
}

S7::method(replace_nodes, pandoc_node) = function(x, ..., .with) {
  quos = ast_quos(...)
  fn = function(node) ast_resolve_what(.with, node)
  pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
}

S7::method(delete_nodes, pandoc) = function(x, ...) {
  quos = ast_quos(...)
  fn = function(node) NULL
  out = pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
  pd_finalize_root(x, out)
}

S7::method(delete_nodes, pandoc_node) = function(x, ...) {
  quos = ast_quos(...)
  fn = function(node) NULL
  pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
}

S7::method(splice_nodes, pandoc) = function(x, ..., .f) {
  user_fn = ast_as_fn(.f)
  if (is.null(user_fn)) stop("splice_nodes requires .f", call. = FALSE)
  fn = function(node) {
    out = user_fn(node)
    if (!is.list(out) || S7::S7_inherits(out, pandoc_node)) {
      stop("splice_nodes .f must return a list of nodes; ",
           "use map_nodes for single-node replacement", call. = FALSE)
    }
    out
  }
  quos = ast_quos(...)
  out = pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
  pd_finalize_root(x, out)
}

S7::method(splice_nodes, pandoc_node) = function(x, ..., .f) {
  user_fn = ast_as_fn(.f)
  if (is.null(user_fn)) stop("splice_nodes requires .f", call. = FALSE)
  fn = function(node) {
    out = user_fn(node)
    if (!is.list(out) || S7::S7_inherits(out, pandoc_node)) {
      stop("splice_nodes .f must return a list of nodes", call. = FALSE)
    }
    out
  }
  quos = ast_quos(...)
  pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
}


# ---- insert_before / insert_after ---------------------------------------

S7::method(insert_before, pandoc) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(ast_resolve_what(.what, node), list(node))
  out = pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
  pd_finalize_root(x, out)
}

S7::method(insert_before, pandoc_node) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(ast_resolve_what(.what, node), list(node))
  pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
}

S7::method(insert_after, pandoc) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(list(node), ast_resolve_what(.what, node))
  out = pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
  pd_finalize_root(x, out)
}

S7::method(insert_after, pandoc_node) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(list(node), ast_resolve_what(.what, node))
  pd_rewrite_node(x, quos, ast_make_mask("pandoc"), fn)
}


# ---- list-of-nodes dispatch (chained selection) -------------------------
# After a prior select_*, the user often pipes a list of nodes into
# another `select_descendants()`. Provide a generic shape that handles
# both kinds of lists by inspecting the first element.

select_nodes_on_list = function(nodes, quos, mask, kind, include_root) {
  out = list()
  visitor = function(node) {
    if (ast_eval_predicates(quos, node, mask, kind)) {
      out[[length(out) + 1L]] <<- node
    }
  }
  purrr::walk(nodes, function(n) {
    if (is.null(n)) return()
    if (kind == "ts") {
      if (include_root) {
        ts_walk_iter(n, visitor)
      } else {
        purrr::walk(n@children@content, ts_walk_iter, visit = visitor)
      }
    } else {
      if (include_root) pd_walk_node(n, visitor) else pd_walk_children(n, visitor)
    }
  })
  out
}

# Small helper used above; defined here so both ts and pd list-dispatch
# can call it. Mirrors `ts_walk_node` but takes a `visit` callback
# instead of predicate/.f.
ts_walk_iter = function(node, visit) {
  visit(node)
  purrr::walk(node@children@content, ts_walk_iter, visit = visit)
}

pd_list_kind = function(nodes) {
  for (n in nodes) {
    if (S7::S7_inherits(n, ts_node)) return("ts")
    if (S7::S7_inherits(n, pandoc_node) ||
        S7::S7_inherits(n, pandoc)) return("pandoc")
  }
  "pandoc"
}

S7::method(select_nodes, S7::class_list) = function(x, ...) {
  if (length(x) == 0L) return(list())
  kind = pd_list_kind(x)
  quos = ast_quos(...)
  mask = ast_make_mask(kind)
  select_nodes_on_list(x, quos, mask, kind, include_root = TRUE)
}

S7::method(select_descendants, S7::class_list) = function(x, ...) {
  if (length(x) == 0L) return(list())
  kind = pd_list_kind(x)
  quos = ast_quos(...)
  mask = ast_make_mask(kind)
  select_nodes_on_list(x, quos, mask, kind, include_root = FALSE)
}

S7::method(select_children, S7::class_list) = function(x, ...) {
  if (length(x) == 0L) return(list())
  kind = pd_list_kind(x)
  quos = ast_quos(...)
  mask = ast_make_mask(kind)
  out = list()
  purrr::walk(x, function(n) {
    if (is.null(n)) return()
    direct = if (kind == "ts") n@children@content else pd_collect_direct_children(n)
    out <<- c(out, purrr::keep(direct, function(c) {
      ast_eval_predicates(quos, c, mask, kind)
    }))
  })
  out
}

S7::method(select_first, S7::class_list) = function(x, ...) {
  if (length(x) == 0L) return(NULL)
  matches = select_nodes(x, ...)
  if (length(matches) == 0L) NULL else matches[[1L]]
}
