QUARTO_WEB_SKIP = list(
  ts_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd" = "q2#TBD-pre-html-block (`<pre>...</pre>` not recognized as HTML block; see notes/pre_html_block_issue.md)",
    "docs/advanced/environment-vars.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/authoring/markdown-basics.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/authoring/tables.qmd"                                    = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/blog/posts/2025-10-20-quarto-wizard-1-0-0/index.qmd"     = "q2#TBD-multiline-image-attr-list (multi-line image attribute lists rejected; see notes/multiline_image_attr_list_issue.md)",
    "docs/blog/posts/2025-11-24-conf-talk-videos/index.qmd"        = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/computations/caching.qmd"                                = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/computations/julia.qmd"                                  = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/extensions/lua.qmd"                                      = "q2r#TBD-to_qmd-brace-escape (R-side to_qmd writer drops `\\{`/`\\}` escapes in line blocks; pampa writer is fine)",
    "docs/get-started/authoring/jupyter.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/authoring/rstudio.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/jupyter.qmd"                    = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/positron.qmd"                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/vscode.qmd"                     = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/jupyter.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/neovim.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/text-editor.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/vscode.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/presentations/revealjs/presenting.qmd"                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/projects/quarto-projects.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/projects/virtual-environments.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/publishing/github-pages.qmd"                             = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/_jupyter-lab-extension-install.qmd"                = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/jupyter-lab-extension.qmd"                         = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/jupyter-lab.qmd"                                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/visual-editor/options.qmd"                               = "q2#TBD-kbd-shortcode-backslash (kbd shortcode rejects `\\\\` in param values; misleading Q-2-34 diagnostic)",
    "docs/websites/website-listings.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/websites/website-navigation.qmd"                         = "q2#TBD-div-close-after-pipe-table + q2#TBD-quoted-underscore (two distinct parser bugs; see notes/div_close_after_pipe_table_issue.md and notes/quoted_underscore_word_issue.md)"
  ),
  pd_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd" = "q2#TBD-pre-html-block (`<pre>...</pre>` not recognized as HTML block; see notes/pre_html_block_issue.md)",
    "docs/advanced/environment-vars.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/authoring/markdown-basics.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/authoring/tables.qmd"                                    = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/blog/posts/2025-10-20-quarto-wizard-1-0-0/index.qmd"     = "q2#TBD-multiline-image-attr-list (multi-line image attribute lists rejected; see notes/multiline_image_attr_list_issue.md)",
    "docs/blog/posts/2025-11-24-conf-talk-videos/index.qmd"        = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/computations/caching.qmd"                                = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/computations/julia.qmd"                                  = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/extensions/lua.qmd"                                      = "q2r#TBD-to_qmd-brace-escape (R-side to_qmd writer drops `\\{`/`\\}` escapes in line blocks; pampa writer is fine)",
    "docs/get-started/authoring/jupyter.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/authoring/rstudio.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/jupyter.qmd"                    = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/positron.qmd"                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/vscode.qmd"                     = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/jupyter.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/neovim.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/text-editor.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/vscode.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/presentations/revealjs/presenting.qmd"                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/projects/quarto-projects.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/projects/virtual-environments.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/publishing/github-pages.qmd"                             = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/_jupyter-lab-extension-install.qmd"                = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/jupyter-lab-extension.qmd"                         = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/jupyter-lab.qmd"                                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/visual-editor/options.qmd"                               = "q2#TBD-kbd-shortcode-backslash (kbd shortcode rejects `\\\\` in param values; misleading Q-2-34 diagnostic)",
    "docs/websites/website-listings.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/websites/website-navigation.qmd"                         = "q2#TBD-div-close-after-pipe-table + q2#TBD-quoted-underscore (two distinct parser bugs; see notes/div_close_after_pipe_table_issue.md and notes/quoted_underscore_word_issue.md)"
  ),
  pampa_pd_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd" = "q2#TBD-pre-html-block (`<pre>...</pre>` not recognized as HTML block; see notes/pre_html_block_issue.md)",
    "docs/advanced/environment-vars.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/authoring/markdown-basics.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/authoring/tables.qmd"                                    = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/blog/posts/2024-04-01-manuscripts-rmedicine/index.qmd"   = "q2#174 (loose list tightened on round-trip)",
    "docs/blog/posts/2024-12-04-websites-workshop/index.qmd"       = "q2#201-related (pampa qmd writer downconverts curly `’` apostrophe to straight `'` without escape, triggering Q-2-10 on re-parse)",
    "docs/blog/posts/2025-10-20-quarto-wizard-1-0-0/index.qmd"     = "q2#TBD-multiline-image-attr-list (multi-line image attribute lists rejected; see notes/multiline_image_attr_list_issue.md)",
    "docs/blog/posts/2025-11-24-conf-talk-videos/index.qmd"        = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/computations/caching.qmd"                                = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/computations/julia.qmd"                                  = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/extensions/_shortcode-escaping.qmd"                      = "q2#174 (loose list tightened on round-trip)",
    "docs/get-started/authoring/jupyter.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/authoring/rstudio.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/jupyter.qmd"                    = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/positron.qmd"                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/computations/vscode.qmd"                     = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/jupyter.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/neovim.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/rstudio.qmd"                           = "q2#174 (loose list tightened on round-trip)",
    "docs/get-started/hello/text-editor.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/get-started/hello/vscode.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/interactive/shiny/index.qmd"                             = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/authors.qmd"                                    = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/formats.qmd"                                    = "q2#174 (loose list tightened on round-trip)",
    "docs/manuscripts/authoring/_setup.qmd"                        = "q2#174 (loose list tightened on round-trip)",
    "docs/presentations/revealjs/index.qmd"                        = "q2#174 (loose list tightened on round-trip)",
    "docs/presentations/revealjs/presenting.qmd"                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/projects/code-execution.qmd"                             = "q2#201 (pampa qmd writer emits raw `'` for escaped `\\'`, breaking re-parse)",
    "docs/projects/quarto-projects.qmd"                            = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/projects/virtual-environments.qmd"                       = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/publishing/github-pages.qmd"                             = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/_jupyter-lab-extension-install.qmd"                = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/jupyter-lab-extension.qmd"                         = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/tools/jupyter-lab.qmd"                                   = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/visual-editor/options.qmd"                               = "q2#TBD-kbd-shortcode-backslash (kbd shortcode rejects `\\\\` in param values; misleading Q-2-34 diagnostic)",
    "docs/websites/website-blog.qmd"                               = "q2#174 (loose list tightened on round-trip)",
    "docs/websites/website-drafts.qmd"                             = "q2#201 (pampa qmd writer emits raw `'` for escaped `\\'`, breaking re-parse)",
    "docs/websites/website-listings.qmd"                           = "q2#156 (grid-table cells with ``` code fence trigger parse error)",
    "docs/websites/website-navigation.qmd"                         = "q2#TBD-div-close-after-pipe-table + q2#TBD-quoted-underscore (two distinct parser bugs; see notes/div_close_after_pipe_table_issue.md and notes/quoted_underscore_word_issue.md)",
    "docs/websites/website-tools.qmd"                              = "q2#201 (pampa qmd writer emits raw `'` for escaped `\\'`, breaking re-parse)"
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
    "  expect_no_error_diagnostics(ts)",
    "  if (has_error_diagnostics(ts)) return(invisible())",
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
    "  expect_no_error_diagnostics(pd)",
    "  if (has_error_diagnostics(pd)) return(invisible())",
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
    "  expect_no_error_diagnostics(pd)",
    "  if (has_error_diagnostics(pd)) return(invisible())",
    "  rendered = pampa_to_qmd(pd)",
    "  pd2 = pampa_parse_pd(rendered, quiet = TRUE)",
    "  expect_no_error_diagnostics(pd2)",
    "  expect_pd_ast_equal(pd2, pd)"
  ))
}
