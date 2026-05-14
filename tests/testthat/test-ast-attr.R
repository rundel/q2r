make_header = function() {
  doc = pampa_parse_pd("# Hello {#intro .foo .bar lang=en}\n")
  select_first(doc, is(pandoc_header))
}

test_that("has_class detects present and absent classes", {
  h = make_header()
  expect_true(has_class(h, "foo"))
  expect_true(has_class(h, "bar"))
  expect_false(has_class(h, "missing"))
  expect_true(has_class(h, c("missing", "foo")))
})

test_that("has_class is FALSE on a node without @attr", {
  doc = pampa_parse_pd("just text\n")
  s = select_first(doc, is(pandoc_str))
  expect_false(has_class(s, "anything"))
})

test_that("add_class is idempotent and returns a new node", {
  h = make_header()
  h2 = add_class(h, "foo")
  expect_equal(h2@attr@classes, c("foo", "bar"))
  h3 = add_class(h, "new")
  expect_equal(h3@attr@classes, c("foo", "bar", "new"))
  expect_equal(h@attr@classes, c("foo", "bar"))  # unchanged
})

test_that("add_class accepts a vector of classes", {
  h = make_header()
  h2 = add_class(h, c("x", "y"))
  expect_equal(h2@attr@classes, c("foo", "bar", "x", "y"))
})

test_that("remove_class drops the named class", {
  h = make_header()
  h2 = remove_class(h, "foo")
  expect_equal(h2@attr@classes, "bar")
})

test_that("remove_class of an absent class is a no-op", {
  h = make_header()
  h2 = remove_class(h, "absent")
  expect_equal(h2@attr@classes, c("foo", "bar"))
})

test_that("get_id returns the id, set_id overwrites", {
  h = make_header()
  expect_equal(get_id(h), "intro")
  h2 = set_id(h, "outro")
  expect_equal(get_id(h2), "outro")
  expect_equal(get_id(h), "intro")  # unchanged
})

test_that("get_id returns \"\" for nodes without @attr", {
  doc = pampa_parse_pd("text\n")
  s = select_first(doc, is(pandoc_str))
  expect_equal(get_id(s), "")
})

test_that("set_id rejects non-scalar / non-character ids", {
  h = make_header()
  expect_error(set_id(h, c("a", "b")), "single string")
  expect_error(set_id(h, 1L), "single string")
})

test_that("get_attr returns the value or NA_character_", {
  h = make_header()
  expect_equal(get_attr(h, "lang"), "en")
  expect_equal(get_attr(h, "absent"), NA_character_)
})

test_that("set_attr adds and updates key/value pairs", {
  h = make_header()
  h2 = set_attr(h, "dir", "ltr")
  expect_equal(get_attr(h2, "dir"), "ltr")
  expect_equal(get_attr(h2, "lang"), "en")
  h3 = set_attr(h2, "lang", "fr")
  expect_equal(get_attr(h3, "lang"), "fr")
})

test_that("remove_attr drops the named attribute", {
  h = make_header()
  h2 = remove_attr(h, "lang")
  expect_equal(get_attr(h2, "lang"), NA_character_)
  expect_equal(h2@attr@id, "intro")
  expect_equal(h2@attr@classes, c("foo", "bar"))
})

test_that("add_class on a node without @attr errors clearly", {
  doc = pampa_parse_pd("text\n")
  s = select_first(doc, is(pandoc_str))
  expect_error(add_class(s, "x"), "no @attr slot")
})

test_that("attribute helpers compose inside map_nodes", {
  doc = pampa_parse_pd("# H {.note}\n")
  out = map_nodes(doc, is(pandoc_header), .f = function(h) {
    h |> add_class("highlight") |> set_id("section-1")
  })
  h2 = select_first(out, is(pandoc_header))
  expect_true(has_class(h2, "highlight"))
  expect_true(has_class(h2, "note"))
  expect_equal(get_id(h2), "section-1")
})

test_that("ast_filter dispatch + attribute helpers", {
  doc = pampa_parse_pd("# H\n\nA *para* with **bold**.\n")
  out = ast_filter(doc,
    pandoc_header = function(el) add_class(el, "filtered-header"),
    pandoc_strong = function(el) {
      # pandoc_strong has no @attr slot; predicates degrade gracefully
      expect_false(has_class(el, "any"))
      el
    }
  )
  h = select_first(out, is(pandoc_header))
  expect_true(has_class(h, "filtered-header"))
})

test_that("has_class inside select_nodes predicate still uses the mask", {
  # The data-mask helper `has_class("note")` is single-arg and reads the
  # current node from state; this test ensures the exported two-arg
  # version does not shadow it inside a predicate.
  doc = pampa_parse_pd("# Plain\n\n::: {.note}\nContent.\n:::\n")
  matches = select_nodes(doc, is(pandoc_div), has_class("note"))
  expect_length(matches, 1L)
})
