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

# Grammar-gap *content* kinds whose verbatim `@text` is the sole carrier of
# bytes the named children do not cover (the `ts_text_or(NULL)` content kinds in
# to-qmd.R). These have no useful child structure to re-render from, so the
# verbatim span is kept as-is on rebuild - which means edits to their children
# are a no-op on output (a known limitation of ts mutation).
ts_gap_text_kinds = c("code_fence_content", "pandoc_math", "pandoc_display_math")

# Re-derive a container node's `@text` after its children changed. A non-leaf
# only carries `@text` when its children do not cover its full byte span - a
# grammar gap holding inter-child whitespace (blank lines between blocks, the
# `>` of a block quote, list indentation). Clearing it drops that whitespace;
# re-emitting it verbatim drops the mutation. Instead, slice the original gap
# bytes (the spans between the *original* children) out of the original `@text`
# and splice them around the rewritten children's rendered text. `groups[[i]]`
# is the list of new nodes the original child `i` produced - empty for a
# deletion, several for a splice - so gaps stay anchored to surviving children.
# Returns NULL (clear `@text`; let to_qmd() walk children) when the node has no
# gap, or as a safe fallback when the byte span and `@text` disagree.
ts_recompute_gap_text = function(node, old_children, groups) {
  txt = node@text
  if (is.null(txt) || is.null(groups) || length(old_children) == 0L) return(NULL)
  s = node@range@start_byte
  e = node@range@end_byte
  if (is.na(s) || is.na(e)) return(NULL)
  bytes = charToRaw(enc2utf8(txt))
  if (length(bytes) != e - s) return(NULL)
  starts = purrr::map_int(old_children, function(ch) ch@range@start_byte)
  ends   = purrr::map_int(old_children, function(ch) ch@range@end_byte)
  if (anyNA(starts) || anyNA(ends)) return(NULL)
  gap = function(from, to) {
    if (to <= from) return("")
    out = rawToChar(bytes[(from - s + 1L):(to - s)])
    Encoding(out) = "UTF-8"
    out
  }
  # Siblings created inside one group (insert_before/insert_after/splice) have
  # no original gap between them; without a separator, inserted blocks are
  # glued flush against their anchor and merge on reparse. Reuse the node's own
  # observed inter-child spacing as the junction separator (so block children
  # get their blank-line boundary and inline children stay flush), falling back
  # to a newline for the known block containers when no gap is observable.
  inner_gaps = if (length(old_children) > 1L) {
    purrr::map_chr(seq_len(length(old_children) - 1L),
                   function(i) gap(ends[i], starts[i + 1L]))
  } else {
    character(0)
  }
  sep = c(
    inner_gaps[nzchar(inner_gaps)],
    switch(node@kind, document = , section = , pandoc_block_quote = "\n", "")
  )[[1L]]
  parts = character(0)
  prev = s
  for (i in seq_along(old_children)) {
    parts = c(parts, gap(prev, starts[i]),
              ts_join_group(purrr::map_chr(groups[[i]], to_qmd_ts_node), sep))
    prev = ends[i]
  }
  paste0(c(parts, gap(prev, e)), collapse = "")
}

# Join the rendered members of one rewrite group. A newline-only separator is
# applied as "ensure a blank-line boundary" (block siblings must not lazily
# continue each other); any other non-empty separator (e.g. a block quote's
# "\n> ") is inserted literally.
ts_join_group = function(parts, sep) {
  if (length(parts) <= 1L) return(paste0(parts, collapse = ""))
  out = parts[[1L]]
  for (p in parts[-1L]) {
    pad = if (!nzchar(sep)) {
      ""
    } else if (grepl("^\n+$", sep)) {
      if (grepl("\n\n$", out)) "" else if (grepl("\n$", out)) "\n" else "\n\n"
    } else {
      sep
    }
    out = paste0(out, pad, p)
  }
  out
}

ts_rebuild_node = function(node, new_children, old_children = NULL, groups = NULL) {
  # `text` is a verbatim source-span fallback for grammar gaps. Changing
  # children invalidates it for ordinary nodes (to_qmd() then walks children);
  # for the gap-content kinds it is the only carrier of the node's bytes, so
  # keep it verbatim; for gap *containers* it holds the inter-child whitespace
  # that walking the (now mutated) children would drop, so recompute it.
  new_text = if (node@kind %in% ts_gap_text_kinds) {
    node@text
  } else {
    ts_recompute_gap_text(node, old_children, groups)
  }
  ts_node(
    kind       = node@kind,
    is_named   = node@is_named,
    field_name = node@field_name,
    range      = node@range,
    text       = new_text,
    children   = ts_nodes(new_children)
  )
}

# Post-order rewrite. Walks every node, rebuilding parents whose
# children changed. At each node, `.f` is only invoked if `quos` matches.
# `groups` keeps each original child's rewritten output grouped so a rebuilt
# parent can re-anchor its inter-child gap whitespace (see ts_recompute_gap_text).
ts_rewrite_node = function(node, quos, mask, .f) {
  old_children = node@children@content
  groups = purrr::map(old_children, function(ch) {
    ast_to_node_list(ts_rewrite_node(ch, quos, mask, .f))
  })
  new_children = purrr::list_flatten(groups)
  rebuilt = if (identical(new_children, old_children)) {
    node
  } else {
    ts_rebuild_node(node, new_children, old_children, groups)
  }
  if (ast_eval_predicates(quos, rebuilt, mask)) {
    return(.f(rebuilt))
  }
  rebuilt
}

# Pre-order (document-order) walker used by `walk_nodes`, matching the pd
# walker. The recursion must go through an anonymous function: passing the
# user's callback as a named `.f` to purrr::walk() would bind it to walk's
# own `.f` parameter and never recurse.
ts_walk_node = function(node, quos, mask, .f) {
  if (ast_eval_predicates(quos, node, mask)) .f(node)
  purrr::walk(node@children@content, function(ch) ts_walk_node(ch, quos, mask, .f))
}

# Final commit of a rewritten root node into a tree, dropping NULL or
# returning a synthetic empty document if .f killed the root. The mutated
# tree is rendered and reparsed before returning: a rebuilt node carries
# recomputed `@text` but stale byte ranges, so handing it back as-is would
# corrupt gap recomputation on the next mutation pass. Reparsing keeps every
# returned ts_tree internally consistent (chained verbs are safe); the
# ts_node-level verb methods have no document to reparse and keep the
# single-pass guarantee.
ts_finalize_root = function(orig_tree, rewritten) {
  if (is.null(rewritten)) {
    rewritten = ts_node(kind = orig_tree@root@kind)
  }
  if (is.list(rewritten) && !S7::S7_inherits(rewritten, ts_node)) {
    stop("a mutation verb returned a list of nodes for the ts_tree root; ",
         "the document root cannot be spliced. Wrap the result in a single ",
         "root node.", call. = FALSE)
  }
  staged = ts_tree(root = rewritten, language = orig_tree@language)
  out = parse_qmd_text(to_qmd(staged), "<text>", ast = "ts", quiet = TRUE)
  out@diagnostics = orig_tree@diagnostics
  out
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

S7::method(select_first, ts_nodes) = function(x, ...) select_first(x@content, ...)


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

# ---- ts_nodes wrapper: round out the verb set (delegate to @content) ----
# The three selection verbs already dispatch on ts_nodes; mirror the pandoc
# wrappers for the rest, re-wrapping mutator results back in ts_nodes.
S7::method(walk_nodes, ts_nodes) = function(x, ..., .f) {
  walk_nodes(x@content, ..., .f = .f)
  invisible(x)
}
S7::method(map_nodes, ts_nodes)     = function(x, ..., .f) ts_nodes(map_nodes(x@content, ..., .f = .f))
S7::method(replace_nodes, ts_nodes) = function(x, ..., .with) ts_nodes(replace_nodes(x@content, ..., .with = .with))
S7::method(delete_nodes, ts_nodes)  = function(x, ...) ts_nodes(delete_nodes(x@content, ...))
S7::method(splice_nodes, ts_nodes)  = function(x, ..., .f) ts_nodes(splice_nodes(x@content, ..., .f = .f))
S7::method(insert_before, ts_nodes) = function(x, ..., .what) ts_nodes(insert_before(x@content, ..., .what = .what))
S7::method(insert_after, ts_nodes)  = function(x, ..., .what) ts_nodes(insert_after(x@content, ..., .what = .what))


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
    if (S7::S7_inherits(out, ts_node)) {
      stop("splice_nodes .f must return a list of nodes; ",
           "use map_nodes for single-node replacement", call. = FALSE)
    }
    ast_to_node_list(out)
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
    if (S7::S7_inherits(out, ts_node)) {
      stop("splice_nodes .f must return a list of nodes; ",
           "use map_nodes for single-node replacement", call. = FALSE)
    }
    ast_to_node_list(out)
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
