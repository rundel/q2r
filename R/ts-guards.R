#' @include ts-ast.R ast-text.R ast-summary.R ast-sections.R select-section.R toc.R ast-filter.R table.R
NULL

# Friendly dead-ends for the pandoc-only document verbs on the tree-sitter
# AST: without these a ts user hits a bare S7 "Can't find method" error with
# no hint that re-parsing as pandoc is the way forward.
ts_pd_only_abort = function(verb) {
  cli::cli_abort(c(
    "{.fn {verb}} works on the pandoc AST, not the tree-sitter AST.",
    "i" = "Re-parse with {.code parse_qmd(input)} (the default {.code ast = \"pd\"}) to use it."
  ), call = NULL)
}

S7::method(ast_text, ts_tree) = function(x, ...) ts_pd_only_abort("ast_text")
S7::method(ast_text, ts_node) = function(x, ...) ts_pd_only_abort("ast_text")
S7::method(ast_summary, ts_tree) = function(x, max_text = 40L) {
  ts_pd_only_abort("ast_summary")
}
S7::method(ast_sections, ts_tree) = function(x, ...) {
  ts_pd_only_abort("ast_sections")
}
S7::method(select_section, ts_tree) = function(x, path, levels = 1:6,
                                               include_heading = TRUE) {
  ts_pd_only_abort("select_section")
}
S7::method(split_sections, ts_tree) = function(x, level = 1L, ...) {
  ts_pd_only_abort("split_sections")
}
S7::method(ast_toc, ts_tree) = function(x, max_level = 3L, ...) {
  ts_pd_only_abort("ast_toc")
}
S7::method(ast_filter, ts_tree) = function(x, ...) ts_pd_only_abort("ast_filter")
S7::method(as_df, ts_tree) = function(x, ...) ts_pd_only_abort("as_df")
