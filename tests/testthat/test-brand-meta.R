# The `brand.**` front-matter subtree is annotated PlainString upstream since
# q2 eda49bc4 (GH #581): values under `brand:` arrive as `string` scalars
# instead of markdown `inlines` / `blocks`, so `brand: _brand.yml` no longer
# trips the Q-1-20 underscore-emphasis warning that any other string field
# still gets.

test_that("brand values are plain strings and raise no Q-1-20", {
  pd = parse_qmd("---\nbrand: _brand.yml\n---\n\nx\n", quiet = TRUE)
  expect_length(pd@diagnostics, 0L)
  expect_identical(pd@meta@value$brand@kind, "string")
  expect_identical(pd@meta@value$brand@value, "_brand.yml")
})

test_that("nested brand maps stay strings while other fields parse as markdown", {
  src = paste(
    "---", "brand:", "  color:", "    primary: \"#ff0000\"",
    "  typography: _brand.yml", "title: _t", "---", "", "x", "",
    sep = "\n"
  )
  pd = parse_qmd(src, quiet = TRUE)
  brand = pd@meta@value$brand
  expect_identical(brand@kind, "map")
  expect_identical(brand@value$color@value$primary@kind, "string")
  expect_identical(brand@value$color@value$primary@value, "#ff0000")
  expect_identical(brand@value$typography@kind, "string")
  expect_identical(brand@value$typography@value, "_brand.yml")
  expect_identical(pd@meta@value$title@kind, "inlines")
  expect_identical(purrr::map_chr(pd@diagnostics, function(d) d@code), "Q-1-20")
  expect_identical(parse_qmd(to_qmd(pd), quiet = TRUE)@meta, pd@meta)
})
