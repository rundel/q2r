# Reserved `id=` / `class=` key-value attributes are promoted into the id and
# class slots since q2 596ceb57 (last id wins), and the qmd writer emits
# `id="..."` after the classes for ids outside `[._A-Za-z0-9-]` (bd-mxa44voa).
# q2r's attr helpers read the promoted slots, so this pins the shape and the
# round trip.

test_that("id= and class= key-values are promoted into the attr slots", {
  pd = parse_qmd(
    "[x]{id=\"foo/bar\" class=\"a b\"}\n\n::: {id=sec class=note}\ny\n:::\n",
    quiet = TRUE
  )
  expect_no_error_diagnostics(pd)
  sp = select_nodes(pd, is(pandoc_span))[[1]]
  expect_identical(sp@attr@id, "foo/bar")
  expect_identical(sp@attr@classes, c("a", "b"))
  expect_length(sp@attr@attributes, 0L)
  expect_identical(get_id(sp), "foo/bar")
  expect_true(has_class(sp, "b"))
  dv = select_nodes(pd, is(pandoc_div))[[1]]
  expect_identical(dv@attr@id, "sec")
  expect_identical(dv@attr@classes, "note")
})

test_that("a later id= overrides the #id shorthand", {
  pd = parse_qmd("[z]{#one .c id=two}\n", quiet = TRUE)
  expect_no_error_diagnostics(pd)
  sp = select_nodes(pd, is(pandoc_span))[[1]]
  expect_identical(sp@attr@id, "two")
  expect_identical(sp@attr@classes, "c")
})

test_that("the writer quotes ids the #id shorthand cannot express", {
  pd = parse_qmd("[x]{id=\"foo/bar\" class=\"a b\"}\n\n[w]{id=plain}\n", quiet = TRUE)
  out = to_qmd(pd)
  expect_match(out, "[x]{.a .b id=\"foo/bar\"}", fixed = TRUE)
  expect_match(out, "[w]{#plain}", fixed = TRUE)
  expect_pd_ast_equal(parse_qmd(out, quiet = TRUE), pd)
})
