QUARTO_WEB_SKIP = list(
  ts_rt        = list(),
  pd_rt        = list(),
  pampa_pd_rt  = list(
    "docs/authoring/diagrams.qmd"                                = "q2#196 (reader rejects 4-space-indented list-item continuations as parse errors)",
    "docs/blog/posts/2024-04-01-manuscripts-rmedicine/index.qmd" = "q2#174 (loose list tightened on round-trip)",
    "docs/extensions/_shortcode-escaping.qmd"                    = "q2#174 (loose list tightened on round-trip)",
    "docs/extensions/engine.qmd"                                 = "q2#196 (reader rejects 4-space-indented list-item continuations as parse errors)",
    "docs/extensions/lua-api.qmd"                                = "q2#195 (empty bullet-list items not round-tripped; writer's `- []` for an empty cell re-parses to [Plain []])",
    "docs/get-started/hello/rstudio.qmd"                         = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/authors.qmd"                                  = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/formats.qmd"                                  = "q2#174 (loose list tightened on round-trip)",
    "docs/manuscripts/authoring/_setup.qmd"                      = "q2#174 (loose list tightened on round-trip)",
    "docs/output-formats/html-code.qmd"                          = "q2#152 (executable code block class emitted as {.{r}})",
    "docs/output-formats/pdf-basics.qmd"                         = "q2#196 (reader rejects 4-space-indented list-item continuations as parse errors)",
    "docs/presentations/revealjs/index.qmd"                      = "q2#174 (loose list tightened on round-trip)",
    "docs/publishing/netlify.qmd"                                = "q2#196 (reader rejects 4-space-indented list-item continuations as parse errors)",
    "docs/publishing/quarto-pub.qmd"                             = "q2#196 (reader rejects 4-space-indented list-item continuations as parse errors)",
    "docs/publishing/rstudio-connect.qmd"                        = "q2#196 (reader rejects 4-space-indented list-item continuations as parse errors)",
    "docs/websites/website-blog.qmd"                             = "q2#174 (loose list tightened on round-trip)"
  )
)


gen_test_block = function(rel, skip_map, body_lines) {
  reason = skip_map[[rel]]
  quoted = deparse(rel, width.cutoff = 500L)

  if (!is.null(reason)) {
    return(c(
      paste0("test_that(", quoted, ", {"),
      paste0("  skip(", deparse(paste0("Known failure: ", reason), width.cutoff = 500L), ")"),
      "})"
    ))
  }

  c(
    paste0("test_that(", quoted, ", {"),
    body_lines,
    "})"
  )
}

gen_ts_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  ts = pampa_parse_ts(text, quiet = TRUE)",
    "  if (has_error_diagnostics(ts)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = to_qmd(ts)",
    "  ts2 = pampa_parse_ts(rendered, quiet = TRUE)",
    "  expect_no_error_diagnostics(ts2)",
    "  expect_ts_ast_equal(ts2, ts)"
  ))
}

gen_pd_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  pd = pampa_parse_pd(text, quiet = TRUE)",
    "  if (has_error_diagnostics(pd)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = to_qmd(pd)",
    "  pd2 = pampa_parse_pd(rendered, quiet = TRUE)",
    "  expect_no_error_diagnostics(pd2)",
    "  expect_pd_ast_equal(pd2, pd)"
  ))
}


gen_pampa_pd_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  pd = pampa_parse_pd(text, quiet = TRUE)",
    "  if (has_error_diagnostics(pd)) skip(\"initial parse produced error diagnostics\")",
    "  rendered = pampa_to_qmd(pd)",
    "  pd2 = pampa_parse_pd(rendered, quiet = TRUE)",
    "  expect_no_error_diagnostics(pd2)",
    "  expect_pd_ast_equal(pd2, pd)"
  ))
}
