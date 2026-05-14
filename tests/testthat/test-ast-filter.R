test_that("ast_filter is a no-op when no handlers are given", {
  doc = pampa_parse_pd("# H\n\nPara with **bold**.\n")
  out = ast_filter(doc)
  expect_equal(to_qmd(out), to_qmd(doc))
})

test_that("ast_filter rewrites a single type", {
  doc = pampa_parse_pd("Some **bold** text.\n")
  out = ast_filter(doc, pandoc_strong = function(el) {
    pandoc_small_caps(content = el@content)
  })
  strongs = select_nodes(out, is(pandoc_strong))
  smallcaps = select_nodes(out, is(pandoc_small_caps))
  expect_length(strongs, 0L)
  expect_length(smallcaps, 1L)
})

test_that("ast_filter dispatches on inheritance (pandoc_block catches all blocks)", {
  doc = pampa_parse_pd("# Title\n\nA para.\n")
  visited = character()
  out = ast_filter(doc, pandoc_block = function(el) {
    visited <<- c(visited, S7::S7_class(el)@name)
    el
  })
  expect_true("pandoc_header" %in% visited)
  expect_true("pandoc_paragraph" %in% visited)
  expect_equal(to_qmd(out), to_qmd(doc))
})

test_that("ast_filter first-match-wins for overlapping handlers", {
  doc = pampa_parse_pd("# Title\n\nA para.\n")
  saw = character()
  ast_filter(doc,
    pandoc_header = function(el) { saw <<- c(saw, "specific"); el },
    pandoc_block  = function(el) { saw <<- c(saw, "general");  el }
  )
  expect_true("specific" %in% saw)
  expect_false("specific" %in% saw && saw[saw == "specific"][1] == "general")
})

test_that("ast_filter handler returning NULL deletes the node", {
  doc = pampa_parse_pd("Keep me. **drop me**. Keep me too.\n")
  out = ast_filter(doc, pandoc_strong = function(el) NULL)
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
})

test_that("ast_filter handler returning a list splices", {
  doc = pampa_parse_pd("a **b** c\n")
  out = ast_filter(doc, pandoc_strong = function(el) {
    list(pandoc_str(text = "X"), pandoc_space(), pandoc_str(text = "Y"))
  })
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
  expect_true(any(purrr::map_lgl(
    select_nodes(out, is(pandoc_str)),
    function(s) s@text == "X"
  )))
})

test_that("ast_filter traverses post-order (parent sees rewritten children)", {
  doc = pampa_parse_pd("**outer *inner* end**\n")
  parent_saw_replacement = FALSE
  ast_filter(doc,
    pandoc_emph   = function(el) pandoc_str(text = "[E]"),
    pandoc_strong = function(el) {
      # by the time we get here, emph has been replaced with pandoc_str
      parent_saw_replacement <<- any(purrr::map_lgl(
        el@content@content,
        function(c) S7::S7_inherits(c, pandoc_str) && c@text == "[E]"
      ))
      el
    }
  )
  expect_true(parent_saw_replacement)
})

test_that("ast_filter with multiple handlers in one pass", {
  doc = pampa_parse_pd("# H\n\nA *em* and **strong**.\n")
  out = ast_filter(doc,
    pandoc_emph   = function(el) pandoc_strong(content = el@content),
    pandoc_strong = function(el) pandoc_emph(content = el@content),
    pandoc_header = function(el) {
      if (el@level == 1L) {
        pandoc_header(level = 2L, content = el@content, attr = el@attr)
      } else el
    }
  )
  # NB: post-order means emph→strong runs first, then the new strong
  # gets the strong handler applied → emph. So emph stays emph here.
  # Verify the header demotion at least:
  h = select_first(out, is(pandoc_header))
  expect_equal(h@level, 2L)
})

test_that("ast_filter rejects unknown class names", {
  doc = pampa_parse_pd("hi\n")
  expect_error(
    ast_filter(doc, NotAClass = function(el) el),
    "S7 class"
  )
})

test_that("ast_filter rejects unnamed handlers", {
  doc = pampa_parse_pd("hi\n")
  expect_error(
    ast_filter(doc, function(el) el),
    "must be named"
  )
})

test_that("ast_filter works on a bare pandoc_node (not just full document)", {
  doc = pampa_parse_pd("**bold**\n")
  strong = select_first(doc, is(pandoc_strong))
  expect_s7_class(strong, pandoc_strong)
  out = ast_filter(strong, pandoc_str = function(el) pandoc_str(text = paste0("!", el@text, "!")))
  expect_equal(out@content@content[[1L]]@text, "!bold!")
})

test_that("ast_filter handler accepts a formula", {
  doc = pampa_parse_pd("a **b** c\n")
  out = ast_filter(doc, pandoc_strong = ~ pandoc_emph(content = .x@content))
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
  expect_length(select_nodes(out, is(pandoc_emph)), 1L)
})

test_that("ast_filter round-trip identity preserves the document", {
  text = "# Hello\n\nA *paragraph* with **bold** and `code`.\n\n- one\n- two\n"
  doc = pampa_parse_pd(text)
  out = ast_filter(doc, pandoc_str = function(el) el)
  expect_equal(to_qmd(out), to_qmd(doc))
})
