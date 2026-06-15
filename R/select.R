#' @include pd-ast-pandoc.R ts-ast.R
NULL

#' Select, filter, and rewrite nodes in a Pandoc or tree-sitter AST
#'
#' `r lifecycle::badge("experimental")`
#'
#' A tidyselect-style API for querying and rewriting either of q2r's
#' two AST representations: the [`pandoc`] S7 hierarchy and the
#' [`ts_tree`] tree-sitter AST. Each verb is an S7 generic with methods
#' on the relevant node types; the same verb name works on both ASTs.
#'
#' Predicates are unquoted R expressions evaluated against each candidate
#' node with a per-AST data mask. The mask exposes the node's S7 slots
#' as bare names (`level`, `url`, `text`, `kind`, `is_named`, ...) plus a
#' set of helper functions (`is()`, `has_class()`, `has_id()`,
#' `has_attr()`, `has_text()`, `has_label()`, `is_leaf()`). Multiple
#' predicates are combined with `&` (logical AND).
#'
#' @section Selection verbs:
#' - [`select_nodes()`] descends the whole tree (including the root)
#'   and returns a flat list of matching nodes.
#' - [`select_descendants()`] is the same but excludes the root. Accepts
#'   a list of nodes (so pipe chains work).
#' - [`select_children()`] only checks the direct children.
#' - [`select_first()`] returns the first match or `NULL`.
#'
#' @section Iteration and mutation verbs:
#' - [`walk_nodes()`] applies a side-effect function to every match;
#'   returns its input invisibly.
#' - [`map_nodes()`] rewrites every match via `.f`. The function may
#'   return a single node (in-place replacement), a list of nodes
#'   (spliced in at the match site), `NULL` (delete), or the original
#'   node (no-op). The new tree has the same class as the input.
#' - [`replace_nodes()`] is `map_nodes()` with a constant replacement.
#' - [`delete_nodes()`] is `map_nodes()` with `\(x) NULL`.
#' - [`splice_nodes()`] is `map_nodes()` whose `.f` must return a list.
#' - [`insert_before()`] / [`insert_after()`] inject siblings around
#'   each match.
#'
#' @section Mutation contract:
#' `.f` is called with each matching node as its argument. Its return
#' value is interpreted by the walker:
#'
#' - A single node of the appropriate kind replaces the original.
#' - A list of nodes is spliced into the parent's child list at the
#'   match's position.
#' - `NULL` removes the match from the parent.
#' - Returning the original node (or an `==` equivalent) is a no-op.
#'
#' The mutation walker traverses bottom-up (post-order), so when a
#' parent is checked its children have already been rewritten. This
#' matches Pandoc Lua filters' default.
#'
#' @section Predicate helpers (only available inside `...`):
#' These shadow nothing in the global R namespace because they are
#' installed into the predicate's data mask, not the package
#' namespace. Outside a `select_*`/`map_nodes`/etc. predicate they
#' are unavailable.
#'
#' - `is(<S7 class>)` honours S7 inheritance, so `is(pandoc_block)`
#'   matches any block.
#' - `has_class("foo")` / `has_class(c("foo", "bar"))` test
#'   `@attr@classes` membership (pandoc only).
#' - `has_id("intro")` tests `@attr@id`.
#' - `has_attr("key")` / `has_attr("key", "val")` test
#'   `@attr@attributes`.
#' - `has_text("Exercise")` tests the node's flattened text
#'   ([`ast_text()`]) against one or more regex patterns (`fixed = TRUE`
#'   for literal matching); the analog of parsermd's `has_heading()`.
#' - `has_label("fig-*")` glob-matches the node's `@attr@id`, where
#'   Quarto labels surface as `#id`; for code cells without an attr id it
#'   falls back to the cell's `label` option. The analog of parsermd's
#'   `has_label()`.
#' - `is_code_cell()` matches an executable Quarto cell (see
#'   [`code_cell`]).
#' - `has_option("eval")` / `has_option("eval", FALSE)` test a cell's
#'   `#|` options.
#' - `has_engine("r")` / `has_engine(c("r", "python"))` test a cell's
#'   engine ([`cell_engine()`]).
#' - `is_leaf()` matches nodes with no children.
#' - `is_named` (a bare slot, tree-sitter only, not a function call)
#'   is the `ts_node` named/anonymous flag.
#' - `starts_with()`, `ends_with()`, `matches()`, `contains()` - string
#'   tests usable as e.g. `starts_with("http", url)`.
#' - `any_of(x)` and `all_of(x)` - splice a character vector for use
#'   with `%in%`.
#' - Bare slot access: `level`, `url`, `title`, `text`, `format`,
#'   `kind`, `class`, `quote_type`, `math_type`, etc. Missing slots
#'   resolve to `NULL` (so `NULL == 2` is `FALSE`, not an error).
#'
#' @param x A [`pandoc`], [`pandoc_node`], [`pandoc_blocks`],
#'   [`pandoc_inlines`], [`ts_tree`], [`ts_node`], [`ts_nodes`], or a
#'   plain `list` of nodes from a previous selection. For a plain list,
#'   each mutation verb is applied to every element in turn (insert and
#'   splice flatten their multi-node results back into one list).
#' @param ... Predicate expressions, combined with `&`. May be empty
#'   to match every node (use with care).
#' @param .f A function (or rlang formula like `~ ...`) called with each
#'   matching node. Return value follows the mutation contract above.
#' @param .with A constant replacement node or list of nodes.
#' @param .what The siblings to insert. May be a single node, a list of
#'   nodes, or a function called as `.what(node)`.
#'
#' @name select_nodes
NULL


# ---- generic declarations -----------------------------------------------

#' @rdname select_nodes
#' @export
select_nodes = S7::new_generic("select_nodes", "x", function(x, ...) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
select_descendants = S7::new_generic("select_descendants", "x", function(x, ...) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
select_children = S7::new_generic("select_children", "x", function(x, ...) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
select_first = S7::new_generic("select_first", "x", function(x, ...) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
walk_nodes = S7::new_generic("walk_nodes", "x", function(x, ..., .f) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
map_nodes = S7::new_generic("map_nodes", "x", function(x, ..., .f) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
replace_nodes = S7::new_generic("replace_nodes", "x", function(x, ..., .with) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
delete_nodes = S7::new_generic("delete_nodes", "x", function(x, ...) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
splice_nodes = S7::new_generic("splice_nodes", "x", function(x, ..., .f) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
insert_before = S7::new_generic("insert_before", "x", function(x, ..., .what) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
insert_after = S7::new_generic("insert_after", "x", function(x, ..., .what) {
  S7::S7_dispatch()
})


# ---- predicate-helper state ---------------------------------------------

# The helpers below resolve via the current node held in a per-mask
# state environment. They error if called outside an active selection
# context (i.e. outside `ast_eval_predicates`).
select_state = local({
  st = new.env(parent = emptyenv())
  st$node = NULL
  st
})

ast_current_node = function() {
  n = select_state$node
  if (is.null(n)) {
    stop("predicate helper called outside a selection context", call. = FALSE)
  }
  n
}

ast_attr = function(node) attr(node, "attr", exact = TRUE)


# ---- predicate-helper implementations -----------------------------------
# Not exported. Installed only into the predicate data mask so they
# never shadow base R names in the global namespace.

mask_is = function(cls) {
  S7::S7_inherits(ast_current_node(), cls)
}

# Attr-based helpers test only standard `pandoc_attr` attributes; nodes
# carrying other attribute shapes (e.g. `pandoc_list_attributes` on lists)
# are a plain no-match rather than a predicate error.

mask_has_class = function(...) {
  attr_has_class(ast_attr(ast_current_node()), unlist(c(...), use.names = FALSE))
}

mask_has_id = function(id) {
  a = ast_attr(ast_current_node())
  S7::S7_inherits(a, pandoc_attr) && identical(a@id, id)
}

mask_has_attr = function(key, value) {
  v = attr_get(ast_attr(ast_current_node()), key)
  if (is.na(v)) return(FALSE)
  if (missing(value)) return(TRUE)
  identical(v, value)
}

mask_has_text = function(pattern, fixed = FALSE) {
  txt = tryCatch(ast_text(ast_current_node()), error = function(e) NA_character_)
  if (length(txt) != 1L || is.na(txt)) return(FALSE)
  any(purrr::map_lgl(pattern, function(p) grepl(p, txt, fixed = fixed)))
}

mask_has_label = function(pattern) {
  node = ast_current_node()
  id = attr_get_id(ast_attr(node))
  # A code cell's label lives in its `#|` options, not its attr id (it only
  # becomes an id in rendered output), so fall back to it for parsermd parity.
  if ((length(id) != 1L || !nzchar(id)) && S7::S7_inherits(node, pandoc_code_block)) {
    label = cell_options(node)$label
    if (!is.null(label)) id = as.character(label)
  }
  if (length(id) != 1L || !nzchar(id)) return(FALSE)
  any(purrr::map_lgl(utils::glob2rx(pattern), function(p) grepl(p, id)))
}

mask_has_option = function(key, value) {
  node = ast_current_node()
  if (!S7::S7_inherits(node, pandoc_code_block)) return(FALSE)
  opts = cell_options(node)
  if (!(key %in% names(opts))) return(FALSE)
  if (missing(value)) return(TRUE)
  identical(opts[[key]], value)
}

mask_has_engine = function(...) {
  engines = unlist(c(...), use.names = FALSE)
  if (length(engines) == 0L) return(FALSE)
  node = ast_current_node()
  if (!S7::S7_inherits(node, pandoc_code_block)) return(FALSE)
  eng = cell_engine(node)
  if (length(eng) != 1L || is.na(eng)) return(FALSE)
  eng %in% engines
}

mask_is_code_cell = function() {
  node = ast_current_node()
  S7::S7_inherits(node, pandoc_code_block) && is_code_cell(node)
}

mask_is_leaf = function() {
  node = ast_current_node()
  if (S7::S7_inherits(node, pandoc)) {
    return(length(node@blocks@content) == 0L)
  }
  if (S7::S7_inherits(node, ts_node)) {
    return(length(node@children@content) == 0L)
  }
  if (S7::S7_inherits(node, pandoc_node)) {
    kids = pandoc_children(node)
    return(length(kids) == 0L ||
           all(purrr::map_lgl(kids, function(k) {
             if (is.null(k)) return(TRUE)
             if (S7::S7_inherits(k, pandoc_blocks) ||
                 S7::S7_inherits(k, pandoc_inlines)) {
               return(length(k@content) == 0L)
             }
             if (is.list(k)) return(length(k) == 0L)
             FALSE
           })))
  }
  FALSE
}

# `is_named` is a slot on ts_node (a bare logical accessible via the
# slot binding); we deliberately do not install a helper of the same
# name to avoid an `is_named` slot-vs-helper collision.

mask_starts_with = function(pattern, x) {
  if (missing(x)) {
    function(s) startsWith(as.character(s), pattern)
  } else {
    startsWith(as.character(x), pattern)
  }
}

mask_ends_with = function(pattern, x) {
  if (missing(x)) {
    function(s) endsWith(as.character(s), pattern)
  } else {
    endsWith(as.character(x), pattern)
  }
}

mask_matches = function(pattern, x) {
  if (missing(x)) {
    function(s) grepl(pattern, as.character(s), perl = TRUE)
  } else {
    grepl(pattern, as.character(x), perl = TRUE)
  }
}

mask_contains = function(pattern, x) {
  if (missing(x)) {
    function(s) grepl(pattern, as.character(s), fixed = TRUE)
  } else {
    grepl(pattern, as.character(x), fixed = TRUE)
  }
}


# ---- the data mask ------------------------------------------------------

ast_helper_env = function() {
  e = new.env(parent = baseenv())
  e$is          = mask_is
  e$has_class   = mask_has_class
  e$has_id      = mask_has_id
  e$has_attr    = mask_has_attr
  e$has_text    = mask_has_text
  e$has_label   = mask_has_label
  e$has_option  = mask_has_option
  e$has_engine  = mask_has_engine
  e$is_code_cell = mask_is_code_cell
  e$is_leaf     = mask_is_leaf
  e$starts_with = mask_starts_with
  e$ends_with   = mask_ends_with
  e$matches     = mask_matches
  e$contains    = mask_contains
  e$any_of      = function(x) unlist(x, use.names = FALSE)
  e$all_of      = function(x) unlist(x, use.names = FALSE)
  e
}

pd_slot_names = c(
  "level", "url", "title", "text", "format", "id", "math_type",
  "quote_type", "name", "is_escaped", "type_name", "alignment",
  "row_span", "col_span", "attr", "content", "citations",
  "caption", "head", "bodies", "foot", "colspec", "meta",
  "positional_args", "keyword_args", "slots", "short", "long",
  "term", "defs", "rows", "head_rows", "body_rows", "cells",
  "row_head_columns", "width", "mode", "prefix", "suffix",
  "note_num", "hash", "start", "style", "delim"
)

ts_slot_names = c("kind", "is_named", "field_name", "text", "range", "children")

ast_install_slot_bindings = function(env, slot_names) {
  purrr::walk(slot_names, function(s) {
    makeActiveBinding(s, function() {
      n = select_state$node
      if (is.null(n)) NULL else attr(n, s, exact = TRUE)
    }, env)
  })
  invisible(env)
}

ast_install_class_binding = function(env) {
  makeActiveBinding("class", function() {
    n = select_state$node
    if (is.null(n)) return(NA_character_)
    cls = S7::S7_class(n)
    if (is.null(cls)) NA_character_ else cls@name
  }, env)
  invisible(env)
}

# Build a mask reusable across many candidate nodes. The mask reads the
# candidate from the shared `select_state$node` slot; the caller is
# responsible for setting it before each `eval_tidy` call.
ast_make_mask = function(kind = c("pandoc", "ts")) {
  kind = match.arg(kind)
  env = ast_helper_env()
  slot_names = if (kind == "pandoc") pd_slot_names else ts_slot_names
  ast_install_slot_bindings(env, slot_names)
  ast_install_class_binding(env)
  rlang::new_data_mask(env)
}

ast_eval_predicates = function(quos, node, mask) {
  if (length(quos) == 0L) return(TRUE)
  prev_node = select_state$node
  select_state$node = node
  on.exit({ select_state$node = prev_node }, add = TRUE)
  for (q in quos) {
    res = tryCatch(
      rlang::eval_tidy(q, mask),
      # A predicate that errors is treated as no-match (so a slot only some
      # node types carry does not abort the whole query), but the error is
      # surfaced once per unique message so genuine mistakes - a mistyped
      # helper, an unknown slot, a bad regex - do not fail silently.
      error = function(e) {
        rlang::warn(
          paste0("select predicate errored and was treated as no-match: ",
                 conditionMessage(e)),
          class = "q2r_predicate_error",
          .frequency = "once",
          .frequency_id = paste0("q2r-pred-", conditionMessage(e))
        )
        FALSE
      }
    )
    if (!isTRUE(res)) return(FALSE)
  }
  TRUE
}

ast_quos = function(...) {
  rlang::enquos(..., .named = FALSE, .ignore_empty = "all")
}


# ---- shared mutation utilities ------------------------------------------

# Coerce the user's `.f` argument into a function. Accepts a function,
# a one-sided rlang formula (`~ .x@content`), or NULL.
ast_as_fn = function(f) {
  if (is.null(f)) return(NULL)
  if (is.function(f)) return(f)
  if (rlang::is_formula(f)) return(rlang::as_function(f))
  stop(".f must be a function or a formula (e.g. `~ pandoc_str(.x@text)`)",
       call. = FALSE)
}

# Resolve `.what` (for insert_before / insert_after / replace_nodes).
# A function is called as `.what(node)`; otherwise it is used verbatim.
# The result is always normalised to a list of nodes.
ast_resolve_what = function(what, node) {
  out = if (is.function(what) || rlang::is_formula(what)) {
    fn = ast_as_fn(what)
    fn(node)
  } else {
    what
  }
  ast_to_node_list(out)
}

# Normalise the polymorphic return value of `.f` / `.what` into a flat
# list of nodes: NULL -> list(), a single node -> list(node), a wrapper
# (pandoc_blocks/inlines, ts_nodes) -> its contents, a list -> itself.
ast_to_node_list = function(x) {
  if (is.null(x)) return(list())
  if (S7::S7_inherits(x, pandoc_blocks) ||
      S7::S7_inherits(x, pandoc_inlines) ||
      S7::S7_inherits(x, ts_nodes)) {
    return(x@content)
  }
  if (is.list(x) && !S7::S7_inherits(x, pandoc_node) &&
      !S7::S7_inherits(x, ts_node)) {
    return(x)
  }
  list(x)
}
