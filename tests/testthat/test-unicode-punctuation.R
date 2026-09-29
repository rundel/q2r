# Every non-ASCII punctuation (`\p{P}`) or symbol (`\p{S}`) code point folds
# into the surrounding str as of q2 10e16e0c (daca65500,
# bd-angle-bracket-u27e8-parse-error-r6l55zmh): tree-sitter-qmd replaced its
# hand-enumerated Po / Pc / Sm / Sk / Sc range tables with the class
# `[[\p{P}\p{S}]&&[^\x00-\x7F]]`. The old tables never covered Ps / Pe, so
# brackets such as `⟨`, `⌈`, `「` and `（` were parse errors, and had drifted
# from the Unicode version they were generated against. The pampa qmd writer
# emits every such character verbatim (`…` and `—`, which it spells in ASCII
# smart-typography form, are covered elsewhere).

chars = c(
  "⟨", "⟩", "⟦", "⟧", "⌈", "⌉", "⌊", "⌋",
  "⦃", "⦄", "⁽", "⁾", "⦅", "⦆",
  "「", "」", "『", "』", "【", "】", "《", "》",
  "（", "）", "［", "］", "｛", "｝", "〝", "〞",
  "⸂", "⸃", "⸠", "⸡", "₰", "§", "¶", "†",
  "•", "±", "→", "€", "©", "¨", "«", "»"
)

para_texts = function(pd) {
  purrr::map_chr(pd@blocks[[1]]@content@content, function(x) {
    if (S7::S7_inherits(x, pandoc_str)) x@text
    else if (S7::S7_inherits(x, pandoc_space)) "<sp>"
    else sub("q2r::", "", class(x)[1])
  })
}

test_that("non-ASCII punctuation and symbols parse as str on the pandoc path", {
  for (ch in chars) {
    src = paste0("a ", ch, "b a", ch, "b a", ch, " b\n")
    pd = parse_qmd(src, quiet = TRUE)
    expect_no_error_diagnostics(pd)
    expect_identical(
      para_texts(pd),
      c("a", "<sp>", paste0(ch, "b"), "<sp>", paste0("a", ch, "b"), "<sp>", paste0("a", ch), "<sp>", "b"),
      info = sprintf("U+%04X", utf8ToInt(ch))
    )
  }

  pd = parse_qmd("Revert ⟨hunk⟩ then RED\n", quiet = TRUE)
  expect_identical(para_texts(pd), c("Revert", "<sp>", "⟨hunk⟩", "<sp>", "then", "<sp>", "RED"))

  pd = parse_qmd("「引用」（注）【見出し】\n", quiet = TRUE)
  expect_identical(para_texts(pd), "「引用」（注）【見出し】")
})

test_that("non-ASCII punctuation is written verbatim and round-trips", {
  for (ch in chars) {
    src = paste0("a ", ch, "b a", ch, "b a", ch, " b\n")
    pd = parse_qmd(src, quiet = TRUE)
    expect_identical(to_qmd(pd), src, info = sprintf("U+%04X", utf8ToInt(ch)))
    expect_pd_ast_equal(parse_qmd(to_qmd(pd), quiet = TRUE), pd)
  }
})

test_that("non-ASCII punctuation parses without ERROR nodes on the tree-sitter path", {
  for (ch in chars) {
    src = paste0("a ", ch, "b a", ch, "b a", ch, " b\n")
    ts = parse_qmd(src, ast = "ts", quiet = TRUE)
    expect_no_error_diagnostics(ts)
    expect_length(as.list(select_nodes(ts, kind == "ERROR")), 0L)
    expect_identical(to_qmd(ts), src, info = sprintf("U+%04X", utf8ToInt(ch)))
    expect_ts_ast_equal(parse_qmd(to_qmd(ts), ast = "ts", quiet = TRUE), ts)
  }
})

test_that("ASCII markup is unaffected", {
  pd = parse_qmd("*x* [y]{.z}\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  inl = pd@blocks[[1]]@content@content
  expect_true(S7::S7_inherits(inl[[1]], pandoc_emph))
  expect_true(S7::S7_inherits(inl[[3]], pandoc_span))
  expect_identical(inl[[3]]@attr@classes, "z")
})
