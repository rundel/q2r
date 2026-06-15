#' @include select.R ts-ast.R
NULL

# ---- core walkers -------------------------------------------------------

# Depth-first pre-order matches. The `include_root` flag distinguishes
# `select_nodes` (root included) from `select_descendants` (root skipped
# but every descendant tested).
ts_collect_matches = function(root, quos, mask, include_root = TRUE) {
  out = list()
  visit = function(node) {
    if (ast_eval_predicates(quos, node, mask)) {
      out[[length(out) + 1L]] <<- node
    }
    purrr::walk(node@children@content, visit)
  }
  if (include_root) {
    visit(root)
  } else {
    purrr::walk(root@children@content, visit)
  }
  out
}

# Grammar-gap kinds whose verbatim `@text` is the sole carrier of bytes the
# named children do not cover (the `ts_text_or(NULL)` content kinds in
# to-qmd.R). For these, clearing `@text` on rebuild would silently drop the
# content; for every other kind `to_qmd()` correctly re-renders by walking the
# (mutated) children.
ts_gap_text_kinds = c("code_fence_content", "pandoc_math", "pandoc_display_math")

ts_rebuild_node = function(node, new_children) {
  # `text` is a verbatim source-span fallback for grammar gaps. Changing
  # children invalidates it for ordinary nodes (to_qmd() then walks children),
  # but for the gap-content kinds it is the only carrier of the node's bytes,
  # so preserve it to avoid silent data loss.
  keep_text = node@kind %in% ts_gap_text_kinds
  ts_node(
    kind       = node@kind,
    is_named   = node@is_named,
    field_name = node@field_name,
    range      = node@range,
    text       = if (keep_text) node@text else NULL,
    children   = ts_nodes(new_children)
  )
}

# Post-order rewrite. Walks every node, rebuilding parents whose
# children changed. At each node, `.f` is only invoked if `quos` matches.
ts_rewrite_node = function(node, quos, mask, .f) {
  old_children = node@children@content
  new_children = purrr::list_flatten(
    purrr::map(old_children, function(ch) {
      ast_to_node_list(ts_rewrite_node(ch, quos, mask, .f))
    })
  )
  rebuilt = if (identical(new_children, old_children)) {
    node
  } else {
    ts_rebuild_node(node, new_children)
  }
  if (ast_eval_predicates(quos, rebuilt, mask)) {
    return(.f(rebuilt))
  }
  rebuilt
}

# Sentinel-free post-order walker used by `walk_nodes`.
ts_walk_node = function(node, quos, mask, .f) {
  purrr::walk(node@children@content, ts_walk_node,
              quos = quos, mask = mask, .f = .f)
  if (ast_eval_predicates(quos, node, mask)) .f(node)
}

# Final commit of a rewritten root node into a tree, dropping NULL or
# returning a synthetic empty document if .f killed the root.
ts_finalize_root = function(orig_tree, rewritten) {
  if (is.null(rewritten)) {
    rewritten = ts_node(kind = orig_tree@root@kind)
  }
  if (is.list(rewritten) && !S7::S7_inherits(rewritten, ts_node)) {
    stop("map_nodes on a ts_tree root returned a list; the document root ",
         "cannot be spliced. Wrap the result in a single root node.",
         call. = FALSE)
  }
  ts_tree(root = rewritten, language = orig_tree@language,
          diagnostics = orig_tree@diagnostics)
}


# ---- select_nodes -------------------------------------------------------

S7::method(select_nodes, ts_tree) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  ts_collect_matches(x@root, quos, mask, include_root = TRUE)
}

S7::method(select_nodes, ts_node) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  ts_collect_matches(x, quos, mask, include_root = TRUE)
}

S7::method(select_nodes, ts_nodes) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  purrr::list_flatten(
    purrr::map(x@content, ts_collect_matches,
               quos = quos, mask = mask, include_root = TRUE)
  )
}


# ---- select_descendants -------------------------------------------------

S7::method(select_descendants, ts_tree) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  ts_collect_matches(x@root, quos, mask, include_root = FALSE)
}

S7::method(select_descendants, ts_node) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  ts_collect_matches(x, quos, mask, include_root = FALSE)
}

S7::method(select_descendants, ts_nodes) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  purrr::list_flatten(
    purrr::map(x@content, ts_collect_matches,
               quos = quos, mask = mask, include_root = FALSE)
  )
}


# ---- select_children ----------------------------------------------------

S7::method(select_children, ts_tree) = function(x, ...) {
  select_children(x@root, ...)
}

S7::method(select_children, ts_node) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  purrr::keep(x@children@content, function(ch) {
    ast_eval_predicates(quos, ch, mask)
  })
}

S7::method(select_children, ts_nodes) = function(x, ...) {
  quos = ast_quos(...)
  mask = ast_make_mask("ts")
  purrr::keep(x@content, function(ch) {
    ast_eval_predicates(quos, ch, mask)
  })
}


# ---- select_first -------------------------------------------------------

ts_first_match = function(root, quos, mask, include_root = TRUE) {
  found = NULL
  visit = function(node) {
    if (!is.null(found)) return()
    if (ast_eval_predicates(quos, node, mask)) {
      found <<- node
      return()
    }
    for (ch in node@children@content) {
      if (!is.null(found)) break
      visit(ch)
    }
  }
  if (include_root) {
    visit(root)
  } else {
    for (ch in root@children@content) {
      if (!is.null(found)) break
      visit(ch)
    }
  }
  found
}

S7::method(select_first, ts_tree) = function(x, ...) {
  quos = ast_quos(...)
  ts_first_match(x@root, quos, ast_make_mask("ts"), include_root = TRUE)
}

S7::method(select_first, ts_node) = function(x, ...) {
  quos = ast_quos(...)
  ts_first_match(x, quos, ast_make_mask("ts"), include_root = TRUE)
}


# ---- walk_nodes ---------------------------------------------------------

S7::method(walk_nodes, ts_tree) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("walk_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  ts_walk_node(x@root, quos, ast_make_mask("ts"), fn)
  invisible(x)
}

S7::method(walk_nodes, ts_node) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("walk_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  ts_walk_node(x, quos, ast_make_mask("ts"), fn)
  invisible(x)
}


# ---- map_nodes ----------------------------------------------------------

S7::method(map_nodes, ts_tree) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("map_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  out = ts_rewrite_node(x@root, quos, ast_make_mask("ts"), fn)
  ts_finalize_root(x, out)
}

S7::method(map_nodes, ts_node) = function(x, ..., .f) {
  fn = ast_as_fn(.f)
  if (is.null(fn)) stop("map_nodes requires .f", call. = FALSE)
  quos = ast_quos(...)
  ts_rewrite_node(x, quos, ast_make_mask("ts"), fn)
}


# ---- replace_nodes / delete_nodes / splice_nodes ------------------------

S7::method(replace_nodes, ts_tree) = function(x, ..., .with) {
  quos = ast_quos(...)
  fn = function(node) ast_resolve_what(.with, node)
  out = ts_rewrite_node(x@root, quos, ast_make_mask("ts"), fn)
  ts_finalize_root(x, out)
}

S7::method(replace_nodes, ts_node) = function(x, ..., .with) {
  quos = ast_quos(...)
  fn = function(node) ast_resolve_what(.with, node)
  ts_rewrite_node(x, quos, ast_make_mask("ts"), fn)
}

S7::method(delete_nodes, ts_tree) = function(x, ...) {
  quos = ast_quos(...)
  fn = function(node) NULL
  out = ts_rewrite_node(x@root, quos, ast_make_mask("ts"), fn)
  ts_finalize_root(x, out)
}

S7::method(delete_nodes, ts_node) = function(x, ...) {
  quos = ast_quos(...)
  fn = function(node) NULL
  ts_rewrite_node(x, quos, ast_make_mask("ts"), fn)
}

S7::method(splice_nodes, ts_tree) = function(x, ..., .f) {
  user_fn = ast_as_fn(.f)
  if (is.null(user_fn)) stop("splice_nodes requires .f", call. = FALSE)
  fn = function(node) {
    out = user_fn(node)
    if (!is.list(out) || S7::S7_inherits(out, ts_node)) {
      stop("splice_nodes .f must return a list of nodes; ",
           "use map_nodes for single-node replacement", call. = FALSE)
    }
    out
  }
  quos = ast_quos(...)
  out = ts_rewrite_node(x@root, quos, ast_make_mask("ts"), fn)
  ts_finalize_root(x, out)
}

S7::method(splice_nodes, ts_node) = function(x, ..., .f) {
  user_fn = ast_as_fn(.f)
  if (is.null(user_fn)) stop("splice_nodes requires .f", call. = FALSE)
  fn = function(node) {
    out = user_fn(node)
    if (!is.list(out) || S7::S7_inherits(out, ts_node)) {
      stop("splice_nodes .f must return a list of nodes", call. = FALSE)
    }
    out
  }
  quos = ast_quos(...)
  ts_rewrite_node(x, quos, ast_make_mask("ts"), fn)
}


# ---- insert_before / insert_after ---------------------------------------

S7::method(insert_before, ts_tree) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(ast_resolve_what(.what, node), list(node))
  out = ts_rewrite_node(x@root, quos, ast_make_mask("ts"), fn)
  ts_finalize_root(x, out)
}

S7::method(insert_before, ts_node) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(ast_resolve_what(.what, node), list(node))
  ts_rewrite_node(x, quos, ast_make_mask("ts"), fn)
}

S7::method(insert_after, ts_tree) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(list(node), ast_resolve_what(.what, node))
  out = ts_rewrite_node(x@root, quos, ast_make_mask("ts"), fn)
  ts_finalize_root(x, out)
}

S7::method(insert_after, ts_node) = function(x, ..., .what) {
  quos = ast_quos(...)
  fn = function(node) c(list(node), ast_resolve_what(.what, node))
  ts_rewrite_node(x, quos, ast_make_mask("ts"), fn)
}
