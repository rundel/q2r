QUARTO_WEB_SKIP = list(
  ts_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd"      = "q2#TBD-pre-html-block (`<pre>...</pre>` not recognized as HTML block, so its contents parse as markdown - since 1ba0f2ec surfacing as Q-2-41 on `&#96;&#96;&#96;{python}`; see notes/GH#TBD-pre-html-block.md)",
    "docs/advanced/environment-vars.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/_brand-example.qmd"                                 = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/authoring/_cross-references-listings.qmd"                     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/authoring/article-layout.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/brand.qmd"                                          = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/citations.qmd"                                      = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/create-citeable-articles.qmd"                       = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/front-matter.qmd"                                   = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/markdown-basics.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/tables.qmd"                                         = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/blog/_archive/posts/2023-12-05-asa-traveling-courses/index.qmd"        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/blog/_archive/posts/2024-10-15-conf-workshops-materials/index.qmd"     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/blog/_archive/posts/2025-07-24-parameterized-reports-python/index.qmd" = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/blog/_archive/posts/2025-11-24-conf-talk-videos/index.qmd"             = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/books/book-basics.qmd"                                        = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/books/book-structure.qmd"                                     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/computations/caching.qmd"                                     = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/computations/execution-options.qmd"                           = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/computations/julia.qmd"                                       = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/download/index.qmd"                                           = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/download/prerelease.qmd"                                      = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/extensions/distributing.qmd"                                  = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/extensions/lua-api.qmd"                                       = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/faq/rmarkdown.qmd"                                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/authoring/jupyter.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/authoring/rstudio.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/computations/jupyter.qmd"                         = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/computations/positron.qmd"                        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/computations/vscode.qmd"                          = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/jupyter.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/neovim.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/positron.qmd"                               = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/get-started/hello/text-editor.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/vscode.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/manuscripts/next-steps.qmd"                                   = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/output-formats/html-basics.qmd"                               = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/output-formats/html-themes.qmd"                               = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/output-formats/typst.qmd"                                     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/presentations/revealjs/presenting.qmd"                        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/presentations/revealjs/themes.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/projects/quarto-projects.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/projects/virtual-environments.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/publishing/github-pages.qmd"                                  = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/tools/_jupyter-lab-extension-install.qmd"                     = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/tools/jupyter-lab-extension.qmd"                              = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/tools/jupyter-lab.qmd"                                        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/visual-editor/options.qmd"                                    = "q2#TBD-kbd-shortcode-backslash (kbd shortcode rejects `\\\\` in param values; misleading Q-2-34 diagnostic)",
    "docs/websites/website-basics.qmd"                                  = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/websites/website-drafts.qmd"                                  = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/websites/website-listings.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/websites/website-navigation.qmd"                              = "q2#TBD-quoted-underscore (Q-2-11 fires on `\"_blank\"` inside pipe-table cell; see notes/GH#TBD-quoted-underscore-word.md)",
    "docs/websites/website-search.qmd"                                  = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/websites/website-tools.qmd"                                   = "q2#156 (Q-2-39: grid tables are not supported)"
  ),
  pd_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd"      = "q2#TBD-pre-html-block (`<pre>...</pre>` not recognized as HTML block, so its contents parse as markdown - since 1ba0f2ec surfacing as Q-2-41 on `&#96;&#96;&#96;{python}`; see notes/GH#TBD-pre-html-block.md)",
    "docs/advanced/environment-vars.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/_brand-example.qmd"                                 = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/authoring/_cross-references-listings.qmd"                     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/authoring/article-layout.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/brand.qmd"                                          = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/citations.qmd"                                      = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/create-citeable-articles.qmd"                       = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/front-matter.qmd"                                   = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/markdown-basics.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/authoring/tables.qmd"                                         = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/blog/_archive/posts/2023-12-05-asa-traveling-courses/index.qmd"        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/blog/_archive/posts/2024-04-01-manuscripts-rmedicine/index.qmd"        = "q2#174 (loose list tightened on round-trip)",
    "docs/blog/_archive/posts/2024-10-15-conf-workshops-materials/index.qmd"     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/blog/_archive/posts/2025-07-24-parameterized-reports-python/index.qmd" = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/blog/_archive/posts/2025-10-20-quarto-wizard-1-0-0/index.qmd"          = "q2#174 (loose list tightened on round-trip)",
    "docs/blog/_archive/posts/2025-11-24-conf-talk-videos/index.qmd"             = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/blog/_archive/posts/2026-04-14-chrome-headless-shell/index.qmd"        = "q2#TBD-emdash-multiline-frontmatter (#290 dash canonicalization writes an em dash as `---` inside a double-quoted multi-line YAML frontmatter scalar, which then fails to re-parse; see notes/GH#TBD-emdash-multiline-frontmatter.md)",
    "docs/books/book-basics.qmd"                                        = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/books/book-structure.qmd"                                     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/computations/caching.qmd"                                     = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/computations/execution-options.qmd"                           = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/computations/julia.qmd"                                       = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/download/index.qmd"                                           = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/download/prerelease.qmd"                                      = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/extensions/_shortcode-escaping.qmd"                           = "q2#174 (loose list tightened on round-trip)",
    "docs/extensions/distributing.qmd"                                  = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/extensions/lua-api.qmd"                                       = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/faq/rmarkdown.qmd"                                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/authoring/jupyter.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/authoring/rstudio.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/computations/jupyter.qmd"                         = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/computations/positron.qmd"                        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/computations/vscode.qmd"                          = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/jupyter.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/neovim.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/positron.qmd"                               = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/get-started/hello/rstudio.qmd"                                = "q2#174 (loose list tightened on round-trip)",
    "docs/get-started/hello/text-editor.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/get-started/hello/vscode.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/interactive/shiny/index.qmd"                                  = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/authors.qmd"                                         = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/formats.qmd"                                         = "q2#174 (loose list tightened on round-trip)",
    "docs/manuscripts/authoring/_setup.qmd"                             = "q2#174 (loose list tightened on round-trip)",
    "docs/manuscripts/next-steps.qmd"                                   = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/output-formats/html-basics.qmd"                               = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/output-formats/html-themes.qmd"                               = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/output-formats/typst.qmd"                                     = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/prerelease/1.10/_highlights.qmd"                              = "q2#174 (loose list tightened on round-trip)",
    "docs/presentations/revealjs/index.qmd"                             = "q2#174 (loose list tightened on round-trip)",
    "docs/presentations/revealjs/presenting.qmd"                        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/presentations/revealjs/themes.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/projects/code-execution.qmd"                                  = "q2#174 (loose list tightened on round-trip)",
    "docs/projects/quarto-projects.qmd"                                 = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/projects/virtual-environments.qmd"                            = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/publishing/github-pages.qmd"                                  = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/tools/_jupyter-lab-extension-install.qmd"                     = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/tools/jupyter-lab-extension.qmd"                              = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/tools/jupyter-lab.qmd"                                        = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/visual-editor/options.qmd"                                    = "q2#TBD-kbd-shortcode-backslash (kbd shortcode rejects `\\\\` in param values; misleading Q-2-34 diagnostic)",
    "docs/websites/website-basics.qmd"                                  = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/websites/website-blog.qmd"                                    = "q2#174 (loose list tightened on round-trip)",
    "docs/websites/website-drafts.qmd"                                  = "q2#TBD-fenced-div-close-after-block (q2#206 fix introduced regression: closing `:::` of a fenced div containing a child block fails to parse; see notes/GH#TBD-fenced-div-close-after-inner-block.md)",
    "docs/websites/website-listings.qmd"                                = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/websites/website-navigation.qmd"                              = "q2#TBD-quoted-underscore (Q-2-11 fires on `\"_blank\"` inside pipe-table cell; see notes/GH#TBD-quoted-underscore-word.md)",
    "docs/websites/website-search.qmd"                                  = "q2#156 (Q-2-39: grid tables are not supported)",
    "docs/websites/website-tools.qmd"                                   = "q2#156 (Q-2-39: grid tables are not supported)",
    "index.qmd"                                                         = "q2#TBD-entity-zwsp-roundtrip (writer emits decoded `&ZeroWidthSpace;` as raw U+200B, which the reader rejects; see notes/GH#TBD-entity-zwsp-roundtrip.md)"
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
    "  ts = parse_qmd(text, ast = \"ts\", quiet = TRUE)",
    "  expect_no_error_diagnostics(ts)",
    "  if (has_error_diagnostics(ts)) return(invisible())",
    "  rendered = to_qmd(ts)",
    "  ts2 = parse_qmd(rendered, ast = \"ts\", quiet = TRUE)",
    "  expect_no_error_diagnostics(ts2)",
    "  expect_ts_ast_equal(ts2, ts)"
  ))
}

gen_pd_rt_test = function(rel, skip_map = list()) {
  gen_test_block(rel, skip_map, c(
    "  skip_if_no_quarto_web()",
    paste0("  text = quarto_web_read(", deparse(rel, width.cutoff = 500L), ")"),
    "  pd = parse_qmd(text, quiet = TRUE)",
    "  expect_no_error_diagnostics(pd)",
    "  if (has_error_diagnostics(pd)) return(invisible())",
    "  rendered = to_qmd(pd)",
    "  pd2 = parse_qmd(rendered, quiet = TRUE)",
    "  expect_no_error_diagnostics(pd2)",
    "  expect_pd_ast_equal(pd2, pd)"
  ))
}

