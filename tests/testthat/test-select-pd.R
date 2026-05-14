test_that("select_nodes on a pandoc doc finds all headers", {
  doc = pampa_parse_pd("# H1\n\nfoo\n\n## H2\n\nbar\n")
  hs = select_nodes(doc, is(pandoc_header))
  expect_length(hs, 2L)
  expect_equal(purrr::map_int(hs, function(h) h@level), c(1L, 2L))
})

test_that("is() respects S7 inheritance", {
  doc = pampa_parse_pd("# H1\n\nfoo\n")
  blocks = select_nodes(doc, is(pandoc_block))
  expect_gt(length(blocks), 0L)
  expect_true(all(purrr::map_lgl(blocks, ~ S7::S7_inherits(.x, pandoc_block))))
})

test_that("has_class matches @attr@classes", {
  doc = pampa_parse_pd("::: callout\nhello\n:::\n")
  divs = select_nodes(doc, is(pandoc_div) & has_class("callout"))
  expect_length(divs, 1L)
})

test_that("has_class returns FALSE on nodes without @attr", {
  doc = pampa_parse_pd("plain\n")
  m = select_nodes(doc, has_class("callout"))
  expect_length(m, 0L)
})

test_that("has_id matches @attr@id", {
  doc = pampa_parse_pd("# Header {#intro}\n\nbody\n")
  m = select_nodes(doc, has_id("intro"))
  expect_length(m, 1L)
})

test_that("bare slot access: level works on headers", {
  doc = pampa_parse_pd("# H1\n\n## H2\n\n### H3\n")
  h2 = select_nodes(doc, is(pandoc_header) & level == 2L)
  expect_length(h2, 1L)
})

test_that("select_first returns the first match in pre-order", {
  doc = pampa_parse_pd("# H1\n\n## H2\n")
  first = select_first(doc, is(pandoc_header))
  expect_s7_class(first, pandoc_header)
  expect_equal(first@level, 1L)
})

test_that("empty predicate list matches every node", {
  doc = pampa_parse_pd("# H\n")
  all = select_nodes(doc)
  expect_gt(length(all), 1L)
})

test_that("select_children inspects only direct kids", {
  doc = pampa_parse_pd("# H1\n\nfoo\n\n# H2\n\nbar\n")
  direct = select_children(doc, is(pandoc_header))
  expect_length(direct, 2L)
})

test_that("list-of-nodes chained selection works on pandoc", {
  doc = pampa_parse_pd("::: callout\n## H2 inside\n:::\n")
  divs = select_nodes(doc, is(pandoc_div) & has_class("callout"))
  expect_length(divs, 1L)
  inner = select_descendants(divs, is(pandoc_header) & level == 2L)
  expect_length(inner, 1L)
})

test_that("class slot accessor returns the S7 class name", {
  doc = pampa_parse_pd("# H\n")
  hs = select_nodes(doc, class == "pandoc_header")
  expect_length(hs, 1L)
})
