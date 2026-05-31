apos = intToUtf8(0x27)
bslash = intToUtf8(0x5C)

mk_src = function(prefix) paste0(prefix, bslash, apos, "s tail")

inline_close_variants = list(
  strong       = "**bold**",
  emph_star    = "*emph*",
  emph_under   = "_emph_",
  code         = "`code`",
  strikeout    = "~~strike~~",
  link         = "[link](http://x)"
)

ast_kinds = function(pd) {
  collect = function(n) {
    if (is.null(n)) return(character())
    k = S7::S7_class(n)@name
    inner = character()
    if (S7::S7_inherits(n, pandoc)) {
      inner = collect(n@blocks)
    } else if (S7::S7_inherits(n, pandoc_blocks) || S7::S7_inherits(n, pandoc_inlines)) {
      inner = unlist(lapply(n@content, collect))
    } else {
      kids = q2r:::pandoc_children(n)
      inner = unlist(lapply(kids, collect))
    }
    c(k, inner)
  }
  collect(pd)
}

expect_apostrophe_roundtrip = function(prefix) {
  src = mk_src(prefix)
  pd  = parse_qmd(src, quiet = TRUE)
  errs = vapply(pd@diagnostics, function(d) d@kind == "error", logical(1L))
  expect_false(any(errs), info = paste0("initial parse of ", deparse(src)))

  out = to_qmd(pd)
  pd2 = tryCatch(parse_qmd(out, quiet = TRUE), error = function(e) e)
  expect_true(S7::S7_inherits(pd2, pandoc),
              info = paste0("re-parse of writer output ", deparse(out)))
  errs2 = vapply(pd2@diagnostics, function(d) d@kind == "error", logical(1L))
  expect_false(any(errs2), info = paste0("re-parse errors for ", deparse(out)))

  expect_identical(ast_kinds(pd2), ast_kinds(pd),
                   info = paste0("AST drift for ", deparse(prefix)))
}

for (nm in names(inline_close_variants)) {
  local({
    label  = nm
    prefix = inline_close_variants[[label]]
    test_that(paste0("to_qmd round-trips apostrophe after ", label, " close"), {
      expect_apostrophe_roundtrip(prefix)
    })
  })
}

test_that("to_qmd(pandoc) emits backslash-escaped apostrophe after a strong-close", {
  src = mk_src("**bold**")
  out = to_qmd(parse_qmd(src, quiet = TRUE))
  expect_true(grepl(paste0(bslash, apos, "s"), out, fixed = TRUE),
              info = paste0("output: ", deparse(out)))
})
