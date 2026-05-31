# Guards against the four quarto-dev/q2 git deps in src/rust/Cargo.toml
# drifting to different revs, or the `Current pinned commit` line in CLAUDE.md
# falling out of sync with them. Skips when the source files are not present
# (e.g. tests run against an installed package), so it only fires in dev.

test_that("the four q2 Cargo revs are identical and match CLAUDE.md", {
  cargo = testthat::test_path("..", "..", "src", "rust", "Cargo.toml")
  skip_if_not(file.exists(cargo), "src/rust/Cargo.toml not available")

  cargo_lines = readLines(cargo)
  revs = regmatches(
    cargo_lines,
    regexpr("(?<=rev = ')[0-9a-f]{40}(?=')", cargo_lines, perl = TRUE)
  )
  expect_length(revs, 4L)
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
