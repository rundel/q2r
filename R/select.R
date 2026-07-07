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
#' @section Scope:
#' The verbs walk the document's block tree only. Document metadata
#' (`@meta`, including fields like `title` that parse as inline trees)
#' and the args of nested shortcodes are not visited - a predicate can
#' never match inside them, and [`ast_text()`] does not include them.
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
#' - [`walk_nodes()`] applies a side-effect function to every match in
#'   pre-order (document order, parent before children) on both ASTs;
#'   returns its input invisibly.
#' - [`map_nodes()`] rewrites every match via `.f`. The function may
#'   return a single node (in-place replacement), a list of nodes
#'   (spliced in at the match site), `NULL` (delete), or the original
#'   node (no-op). Applied to a document / tree / wrapper the result is
#'   the same class as the input; applied to a bare node the result
#'   follows the mutation contract directly (it may be a node, a list, or
#'   `NULL`).
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
#' The singular support slots (a figure or table caption, a table's head
#' and foot) are reachable by the mutation verbs but under a restricted
#' contract: `.f` must return a node of the same class or `NULL`, which
#' resets the slot to an empty instance (the slot itself cannot be
#' removed or spliced).
#'
#' On a `ts_tree`, the three grammar-gap *content* kinds (`pandoc_math`,
#' `pandoc_display_math`, `code_fence_content`) round-trip through their
#' verbatim source bytes, so mutating *their* children is a no-op on
#' [`to_qmd()`] output.
#'
#' A mutation verb applied to a whole `ts_tree` renders and reparses the
#' result before returning it, so the returned tree always carries
#' internally consistent byte ranges and chained mutations are safe.
#' Applied to a bare [`ts_node`] there is no document to reparse: the
#' result is reliable for a single mutation pass, but should be
#' re-rendered (or the chain restructured at the tree level) before
#' further mutation.
#'
#' @section Predicate helpers (available inside `...`):
#' These are installed into the predicate's data mask, so inside a
#' predicate they take the zero-node forms shown below (testing the
#' current node). Most also exist as exported node-first functions -
#' see [`has_id()`][node_predicates] and friends - for use on a node you
#' already hold.
#'
#' - `is(<S7 class>)` honours S7 inheritance, so `is(pandoc_block)`
#'   matches any block.
#' The attribute- and text-based helpers (`has_class`, `has_id`,
#' `has_attr`, `has_text`, `has_label`) resolve `@attr` / [`ast_text()`],
#' which exist only on the pandoc AST, so on a `ts_tree` they are a silent
#' no-match. Use [`ts_query()`] or bare-slot predicates (`kind`, `text`)
#' for tree-sitter queries.
#'
#' - `has_class("foo")` / `has_class(c("foo", "bar"))` test
#'   `@attr@classes` membership (pandoc only).
#' - `has_id("intro")` tests `@attr@id` (pandoc only).
#' - `has_attr("key")` / `has_attr("key", "val")` test
#'   `@attr@attributes` (pandoc only).
#' - `has_text("Exercise")` tests the node's flattened text
#'   ([`ast_text()`]) against one or more regex patterns (`fixed = TRUE`
#'   for literal matching); the analog of parsermd's `has_heading()`
#'   (pandoc only).
#' - `has_label("fig-*")` glob-matches the node's `@attr@id`, where
#'   Quarto labels surface as `#id`; for code cells without an attr id it
#'   falls back to the cell's `label` option. The analog of parsermd's
#'   `has_label()` (pandoc only).
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

# The mutation verbs take their payload as a named argument after the
# predicate dots; a payload passed positionally is silently swallowed as a
# predicate, so a missing named argument gets an explicit hint.
ast_check_verb_arg = function(value, name, verb) {
  if (is.null(value)) {
    cli::cli_abort(c(
      "{.arg {name}} is missing.",
      "i" = paste0("Pass it by name, e.g. {.code ", verb,
                   "(x, <predicates>, ", name,
                   " = ...)}; a positional argument is treated as a predicate.")
    ), call = NULL)
  }
  invisible(value)
}

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
walk_nodes = S7::new_generic("walk_nodes", "x", function(x, ..., .f = NULL) {
  ast_check_verb_arg(.f, ".f", "walk_nodes")
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
map_nodes = S7::new_generic("map_nodes", "x", function(x, ..., .f = NULL) {
  ast_check_verb_arg(.f, ".f", "map_nodes")
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
replace_nodes = S7::new_generic("replace_nodes", "x", function(x, ..., .with = NULL) {
  ast_check_verb_arg(.with, ".with", "replace_nodes")
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
delete_nodes = S7::new_generic("delete_nodes", "x", function(x, ...) {
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
splice_nodes = S7::new_generic("splice_nodes", "x", function(x, ..., .f = NULL) {
  ast_check_verb_arg(.f, ".f", "splice_nodes")
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
insert_before = S7::new_generic("insert_before", "x", function(x, ..., .what = NULL) {
  ast_check_verb_arg(.what, ".what", "insert_before")
  S7::S7_dispatch()
})

#' @rdname select_nodes
#' @export
insert_after = S7::new_generic("insert_after", "x", function(x, ..., .what = NULL) {
  ast_check_verb_arg(.what, ".what", "insert_after")
  S7::S7_dispatch()
})


# ---- predicate-helper state ---------------------------------------------

# The helpers below resolve via the current node held in a per-mask
# state environment. They error if called outside an active selection
# context (i.e. outside `ast_eval_predicates`).
select_state = local({
  st = new.env(parent = emptyenv())
  st$node = NULL
  st$warned = character(0)
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

mask_has_id = function(id) has_id(ast_current_node(), id)

mask_has_attr = function(key, value) {
  if (missing(value)) return(has_attr(ast_current_node(), key))
  has_attr(ast_current_node(), key, value)
}

mask_has_text = function(pattern, fixed = FALSE) {
  has_text(ast_current_node(), pattern, fixed = fixed)
}

mask_has_label = function(pattern) has_label(ast_current_node(), pattern)

mask_has_option = function(key, value) {
  if (missing(value)) return(has_option(ast_current_node(), key))
  has_option(ast_current_node(), key, value)
}

# Value equality for cell options: yaml parses whole numbers as integer while
# R literals are double, so numerics compare numerically; everything else is
# identical().
cell_option_value_equal = function(a, b) {
  if (is.numeric(a) && is.numeric(b)) {
    length(a) == length(b) && isTRUE(all(a == b))
  } else {
    identical(a, b)
  }
}

mask_has_engine = function(...) has_engine(ast_current_node(), ...)


# ---- exported node-first predicate helpers -------------------------------

#' Node-level predicate helpers
#'
#' `r lifecycle::badge("experimental")`
#'
#' Node-first versions of the predicate-mask helpers from
#' [`select_nodes()`], usable as ordinary functions on a node you already
#' hold (the zero-node forms of the same names remain available inside
#' predicates). All return a single `TRUE`/`FALSE`, and are silently
#' `FALSE` on nodes without the relevant slot (including the whole
#' tree-sitter AST). `has_option()` / `has_engine()` are documented with
#' the other cell helpers in [`is_code_cell()`].
#'
#' @param x A pandoc AST node.
#' @param id The expected `@attr@id` string.
#' @param key The attribute key to look up.
#' @param value The expected attribute value; when missing, tests for
#'   presence of the key only.
#' @param pattern For `has_text()`, regular expression(s) matched against
#'   the node's [`ast_text()`]; for `has_label()`, glob pattern(s) matched
#'   against the node's label (`@attr@id`, or a code cell's `label`
#'   option).
#' @param fixed Treat `pattern` as a literal string.
#' @return A single logical.
#' @name node_predicates
NULL

#' @rdname node_predicates
#' @export
has_id = function(x, id) {
  a = ast_attr(x)
  S7::S7_inherits(a, pandoc_attr) && identical(a@id, id)
}

#' @rdname node_predicates
#' @export
has_attr = function(x, key, value) {
  if (!is.character(key) || length(key) != 1L) {
    cli::cli_abort("{.arg key} in {.fn has_attr} must be a single string.")
  }
  v = attr_get(ast_attr(x), key)
  if (is.na(v)) return(FALSE)
  if (missing(value)) return(TRUE)
  identical(v, value)
}

#' @rdname node_predicates
#' @export
has_text = function(x, pattern, fixed = FALSE) {
  txt = tryCatch(ast_text(x), error = function(e) NA_character_)
  if (length(txt) != 1L || is.na(txt)) return(FALSE)
  any(purrr::map_lgl(pattern, function(p) grepl(p, txt, fixed = fixed)))
}

#' @rdname node_predicates
#' @export
has_label = function(x, pattern) {
  id = attr_get_id(ast_attr(x))
  # A code cell's label lives in its `#|` options, not its attr id (it only
  # becomes an id in rendered output), so fall back to it for parsermd parity.
  if ((length(id) != 1L || !nzchar(id)) && S7::S7_inherits(x, pandoc_code_block)) {
    label = cell_options(x)$label
    if (!is.null(label)) id = as.character(label)
  }
  if (length(id) != 1L || !nzchar(id)) return(FALSE)
  any(purrr::map_lgl(utils::glob2rx(pattern), function(p) grepl(p, id)))
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
  "blocks",
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
  # Mask construction marks the start of a query: reset the per-query
  # warning dedup set so a later query with the same mistake still warns.
  select_state$warned = character(0)
  env = ast_helper_env()
  slot_names = if (kind == "pandoc") pd_slot_names else ts_slot_names
  ast_install_slot_bindings(env, slot_names)
  ast_install_class_binding(env)
  rlang::new_data_mask(env)
}

# Warn once per query (not once per session): the dedup set is reset by
# ast_make_mask at the start of every verb call, so genuine mistakes do not
# go dark after their first occurrence in a session.
ast_predicate_warn = function(msg) {
  if (msg %in% select_state$warned) return(invisible())
  select_state$warned = c(select_state$warned, msg)
  rlang::warn(msg, class = "q2r_predicate_error")
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
      # surfaced so genuine mistakes - a mistyped helper, an unknown slot, a
      # bad regex - do not fail silently.
      error = function(e) {
        ast_predicate_warn(
          paste0("select predicate errored and was treated as no-match: ",
                 conditionMessage(e))
        )
        FALSE
      }
    )
    # A length-0 logical is the documented missing-slot idiom (a bare-slot
    # comparison like `text == "x"` on a node whose slot binds NULL): a
    # silent no-match, not a mistake.
    if (is.logical(res) && length(res) == 0L) return(FALSE)
    # A longer or non-logical result silently dropping nodes is the
    # subtlest way to get a wrong selection (e.g. `attr@classes == "x"` on a
    # two-class node yields length-2 logical); surface it and treat as
    # no-match.
    if (!is.logical(res) || length(res) != 1L) {
      what = if (is.logical(res)) {
        paste0("a length-", length(res), " logical")
      } else {
        paste0("a ", class(res)[[1L]], " value")
      }
      ast_predicate_warn(
        paste0("select predicate returned ", what, " and was treated as ",
               "no-match; predicates must return a single TRUE/FALSE ",
               "(use %in% or any() to collapse vectors)")
      )
      return(FALSE)
    }
    if (is.na(res)) {
      ast_predicate_warn(
        "select predicate returned NA and was treated as no-match"
      )
      return(FALSE)
    }
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
  stop(".f must be a function or a formula (e.g. `~ pandoc_str(text = .x@text)`)",
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
