# Guards against the two rev-pinned quarto-dev/q2 git deps in src/rust/Cargo.toml
# (pampa, tree-sitter-qmd) drifting to different revs, or the `Current pinned
# commit` line in CLAUDE.md falling out of sync with them. The other two q2
# crates (quarto-source-map, quarto-error-reporting) are now consumed from
# crates.io by version, not git rev, so they carry no 40-hex rev to guard here.
# Skips when the source files are not present (e.g. tests run against an
# installed package), so it only fires in dev.

test_that("the q2 Cargo git revs are identical and match CLAUDE.md", {
  cargo = testthat::test_path("..", "..", "src", "rust", "Cargo.toml")
  skip_if_not(file.exists(cargo), "src/rust/Cargo.toml not available")

  cargo_lines = readLines(cargo)
  revs = regmatches(
    cargo_lines,
    regexpr("(?<=rev = ')[0-9a-f]{40}(?=')", cargo_lines, perl = TRUE)
  )
  expect_length(revs, 2L)
  expect_length(unique(revs), 1L)

  claude = testthat::test_path("..", "..", "CLAUDE.md")
  if (file.exists(claude)) {
    claude_lines = readLines(claude)
    doc_rev = regmatches(
      claude_lines,
      regexpr("(?<=Current pinned commit: `)[0-9a-f]{40}(?=`)", claude_lines, perl = TRUE)
    )
    expect_length(doc_rev, 1L)
    expect_identical(doc_rev, unique(revs))
  }
})
