QUARTO_WEB_SKIP = list(
  ts_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd" = "q2#674 (bare `<pre>` contents are tokenized as markdown before the verbatim lift, so `{python}` after entity backticks fails with Q-2-41)",
    "docs/websites/website-navigation.qmd"                         = "q2#TBD-quoted-underscore (Q-2-11 fires on `\"_blank\"` inside pipe-table cell; see notes/GH#TBD-quoted-underscore-word.md)"
  ),
  pd_rt = list(
    "_tools/screenshots/examples/quarto-demo/crossref-jupyter.qmd"        = "q2#674 (bare `<pre>` contents are tokenized as markdown before the verbatim lift, so `{python}` after entity backticks fails with Q-2-41)",
    "docs/advanced/environment-vars.qmd"                                  = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/authoring/article-layout.qmd"                                   = "q2#TBD-list-table-hard-break (the writer emits the line after a hard line break inside a list-table cell at column 0, so the div re-reads as Q-2-35 Invalid List-Table Structure; see notes/GH#TBD-list-table-hard-break.md)",
    "docs/authoring/brand.qmd"                                            = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/authoring/citations.qmd"                                        = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/authoring/create-citeable-articles.qmd"                         = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/authoring/front-matter.qmd"                                     = "q2#TBD-list-table-hard-break (the writer emits the line after a hard line break inside a list-table cell at column 0, so the div re-reads as Q-2-35 Invalid List-Table Structure; see notes/GH#TBD-list-table-hard-break.md)",
    "docs/authoring/includes.qmd"                                         = "q2#674 (writer strips the `{=html}` fence from a `<style>` RawBlock and the bare CSS braces fail to re-read)",
    "docs/authoring/markdown-basics.qmd"                                  = "q2#TBD-list-table-hard-break (the writer emits the line after a hard line break inside a list-table cell at column 0, so the div re-reads as Q-2-35 Invalid List-Table Structure; see notes/GH#TBD-list-table-hard-break.md)",
    "docs/authoring/tables.qmd"                                           = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/blog/_archive/posts/2023-12-05-asa-traveling-courses/index.qmd" = "q2#TBD-list-table-hard-break (the writer emits the line after a hard line break inside a list-table cell at column 0, so the div re-reads as Q-2-35 Invalid List-Table Structure; see notes/GH#TBD-list-table-hard-break.md)",
    "docs/blog/_archive/posts/2024-04-01-manuscripts-rmedicine/index.qmd" = "q2#174 (loose list tightened on round-trip)",
    "docs/blog/_archive/posts/2025-10-20-quarto-wizard-1-0-0/index.qmd"   = "q2#174 (loose list tightened on round-trip)",
    "docs/computations/execution-options.qmd"                             = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/dashboards/deployment.qmd"                                      = "q2#674 (writer strips the `{=html}` fence from a `<style>` RawBlock and the bare CSS braces fail to re-read)",
    "docs/dashboards/index.qmd"                                           = "q2#674 (writer strips the `{=html}` fence from a `<style>` RawBlock and the bare CSS braces fail to re-read)",
    "docs/extensions/_shortcode-escaping.qmd"                             = "q2#174 (loose list tightened on round-trip)",
    "docs/get-started/hello/neovim.qmd"                                   = "q2#174 (loose list tightened on round-trip; a list table nested in a list item)",
    "docs/get-started/hello/rstudio.qmd"                                  = "q2#174 (loose list tightened on round-trip)",
    "docs/get-started/hello/text-editor.qmd"                              = "q2#174 (loose list tightened on round-trip; a list table nested in a list item)",
    "docs/get-started/hello/vscode.qmd"                                   = "q2#174 (loose list tightened on round-trip; a list table nested in a list item)",
    "docs/interactive/shiny/index.qmd"                                    = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/authors.qmd"                                           = "q2#174 (loose list tightened on round-trip)",
    "docs/journals/formats.qmd"                                           = "q2#174 (loose list tightened on round-trip)",
    "docs/manuscripts/authoring/_setup.qmd"                               = "q2#174 (loose list tightened on round-trip)",
    "docs/manuscripts/index.qmd"                                          = "q2#674 (writer strips the `{=html}` fence from a `<style>` RawBlock and the bare CSS braces fail to re-read)",
    "docs/output-formats/html-themes.qmd"                                 = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/prerelease/1.10/_highlights.qmd"                                = "q2#174 (loose list tightened on round-trip)",
    "docs/presentations/revealjs/index.qmd"                               = "q2#174 (loose list tightened on round-trip)",
    "docs/presentations/revealjs/presenting.qmd"                          = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/projects/code-execution.qmd"                                    = "q2#174 (loose list tightened on round-trip)",
    "docs/projects/quarto-projects.qmd"                                   = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/projects/virtual-environments.qmd"                              = "q2#TBD-list-table-hard-break (the writer emits the line after a hard line break inside a list-table cell at column 0, so the div re-reads as Q-2-35 Invalid List-Table Structure; see notes/GH#TBD-list-table-hard-break.md)",
    "docs/tools/jupyter-lab-extension.qmd"                                = "q2#174 (loose list tightened on round-trip; a list table nested in a list item)",
    "docs/visual-editor/options.qmd"                                      = "q2#TBD-kbd-shortcode-backslash (naked kbd value with an escaped backslash now parses since eda49bc4, but the writer re-emits it quoted with a doubled backslash that the quoted-string reader rejects; upstream bd-5te3iryt quoted/naked decode asymmetry; since 914f2069 the unterminated value surfaces as Q-2-52 at the `>}}`)",
    "docs/websites/website-blog.qmd"                                      = "q2#174 (loose list tightened on round-trip)",
    "docs/websites/website-listings.qmd"                                  = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "docs/websites/website-navigation.qmd"                                = "q2#TBD-quoted-underscore (Q-2-11 fires on `\"_blank\"` inside pipe-table cell; see notes/GH#TBD-quoted-underscore-word.md)",
    "docs/websites/website-tools.qmd"                                     = "q2#TBD-list-table-widths (list-table `widths` do not round-trip: the writer drops them when it emits a pipe table and the reader rounds them non-idempotently otherwise; see notes/GH#TBD-list-table-widths.md)",
    "index.qmd"                                                           = "q2#TBD-html-split-plain-paragraph (the html-block lift parses the `<button>` labels in the nav-pills `<ul>` as Plain between raw tag runs; the writer blank-line separates blocks so they re-read as Paragraph, a `<p>` inside a phrasing element on render; upstream bd-8md6k9dv; fixed point after one write; see notes/GH#TBD-html-split-plain-paragraph.md)"
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

