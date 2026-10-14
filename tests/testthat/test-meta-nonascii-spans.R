# quarto-yaml 0.5.0 (pulled in by q2 da14a347, pinned upstream by 690be36e,
# bd-e0e9kd4a) swapped the yaml-rust2 scanner for saphyr. The old scanner
# advanced its marker by bytes over a block scalar's multi-byte content, so
# every later metadata span drifted forward: diagnostics on later keys pointed
# at the wrong bytes and a spurious "YAML string scalar has no content
# provenance" warning appeared.

nonascii_meta = paste0(
  "---\n",
  "status: >\n  v2 — x — y\n",
  "notes: |\n  ", strrep("é", 21), " — ü\n",
  "after: a <b>bold</b> word\n",
  "---\n\nBody\n"
)

byte_offset = function(text, pattern) {
  as.integer(regexpr(pattern, text, fixed = TRUE, useBytes = TRUE)) - 1L
}

test_that("raw HTML after non-ASCII block scalars is located exactly", {
  pd = parse_qmd(nonascii_meta, quiet = TRUE)
  expect_identical(purrr::map_chr(pd@diagnostics, function(d) d@code), c("Q-2-9", "Q-2-9"))
  expect_false(any(purrr::map_lgl(pd@diagnostics, function(d) {
    grepl("provenance", d@title, fixed = TRUE)
  })))

  open = pd@diagnostics[[1]]@location
  close = pd@diagnostics[[2]]@location
  expect_identical(open$start_offset, byte_offset(nonascii_meta, "<b>"))
  expect_identical(open$end_offset, byte_offset(nonascii_meta, "<b>") + 3L)
  expect_identical(close$start_offset, byte_offset(nonascii_meta, "</b>"))
  expect_identical(close$end_offset, byte_offset(nonascii_meta, "</b>") + 4L)
  expect_identical(c(open$start_row, open$start_column), c(6L, 10L))
  expect_identical(c(close$start_row, close$start_column), c(6L, 17L))
})

test_that("the block scalar values survive and the document round-trips", {
  pd = parse_qmd(nonascii_meta, quiet = TRUE)
  expect_identical(
    ast_text(pd@meta@value$notes@value),
    paste0(strrep("é", 21), " — ü")
  )
  expect_identical(ast_text(pd@meta@value$status@value), "v2 — x — y")
  expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
})

test_that("ASCII-only block scalars still locate later raw HTML", {
  text = "---\nnotes: |\n  plain text\nafter: a <b>bold</b> word\n---\n"
  pd = parse_qmd(text, quiet = TRUE)
  expect_identical(pd@diagnostics[[1]]@location$start_offset, byte_offset(text, "<b>"))
})
