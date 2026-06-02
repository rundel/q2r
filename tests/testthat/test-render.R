skip_if_no_quarto = function() {
  testthat::skip_if_not_installed("quarto")
  if (is.null(quarto::quarto_path())) {
    testthat::skip("Quarto CLI not found")
  }
}

test_that("render_qmd renders a pandoc AST to a file and returns its path", {
  skip_if_no_quarto()
  doc = parse_qmd("---\ntitle: Demo\n---\n\n# Title\n\nHello *world*.\n")
  dest = withr::local_tempdir()
  out = file.path(dest, "demo.html")
  res = render_qmd(doc, out, quiet = TRUE)
  expect_equal(res, out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 0)
})

test_that("render_qmd defaults the output into the working directory", {
  skip_if_no_quarto()
  dest = withr::local_tempdir()
  withr::local_dir(dest)
  doc = parse_qmd("# Hi\n\ntext\n")
  res = render_qmd(doc, quiet = TRUE)
  expect_true(file.exists(res))
  expect_match(basename(res), "^document\\.")
})

test_that("render_qmd errors clearly when quarto is unavailable", {
  skip_if(requireNamespace("quarto", quietly = TRUE) &&
            !is.null(quarto::quarto_path()),
          "quarto is available; cannot test the missing-quarto path")
  doc = parse_qmd("# Hi\n\ntext\n")
  expect_error(render_qmd(doc), "quarto")
})
