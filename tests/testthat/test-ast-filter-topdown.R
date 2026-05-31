test_that("pre-order visits parent before children", {
  doc = pampa_parse("# H\n\n*emph*\n")
  order = character()
  ast_filter(doc, .order = "pre",
    pandoc_header    = function(el) { order <<- c(order, "header"); el },
    pandoc_paragraph = function(el) { order <<- c(order, "para");   el },
    pandoc_emph      = function(el) { order <<- c(order, "emph");   el },
    pandoc_str       = function(el) { order <<- c(order, "str");    el }
  )
  para_idx = which(order == "para")[1]
  emph_idx = which(order == "emph")[1]
  expect_lt(para_idx, emph_idx)
})

test_that("post-order visits children before parent", {
  doc = pampa_parse("# H\n\n*emph*\n")
  order = character()
  ast_filter(doc, .order = "post",
    pandoc_paragraph = function(el) { order <<- c(order, "para"); el },
    pandoc_emph      = function(el) { order <<- c(order, "emph"); el }
  )
  para_idx = which(order == "para")[1]
  emph_idx = which(order == "emph")[1]
  expect_lt(emph_idx, para_idx)
})

test_that("ast_skip prevents descent in pre-order", {
  doc = pampa_parse("Outer text and **bold inner**.\n\nSibling.\n")
  inner_visited = FALSE
  ast_filter(doc, .order = "pre",
    pandoc_strong = function(el) ast_skip(el),
    pandoc_str = function(el) {
      if (el@text == "bold") inner_visited <<- TRUE
      el
    }
  )
  expect_false(inner_visited)
})

test_that("ast_skip without descent still installs the (possibly modified) node", {
  doc = pampa_parse("**bold**\n")
  out = ast_filter(doc, .order = "pre",
    pandoc_strong = function(el) ast_skip(pandoc_emph(content = el@content))
  )
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
  expect_length(select_nodes(out, is(pandoc_emph)), 1L)
})

test_that("pre-order handler returning NULL deletes", {
  doc = pampa_parse("Keep. **drop**. Keep too.\n")
  out = ast_filter(doc, .order = "pre", pandoc_strong = function(el) NULL)
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
})

test_that("pre-order handler returning a list splices and does not re-descend", {
  doc = pampa_parse("**bold**\n")
  visits = 0L
  out = ast_filter(doc, .order = "pre",
    pandoc_strong = function(el) {
      list(pandoc_str(text = "X"), pandoc_space(), pandoc_str(text = "Y"))
    },
    pandoc_str = function(el) {
      visits <<- visits + 1L
      el
    }
  )
  expect_length(select_nodes(out, is(pandoc_strong)), 0L)
  expect_equal(visits, 0L)  # neither the original strong's children
                            # nor the spliced siblings are re-visited
})

test_that("pre-order handler returning the same node descends into its children", {
  doc = pampa_parse("# H\n\n**bold** text\n")
  saw_inner_str = FALSE
  ast_filter(doc, .order = "pre",
    pandoc_strong = function(el) el,
    pandoc_str    = function(el) {
      if (el@text == "bold") saw_inner_str <<- TRUE
      el
    }
  )
  expect_true(saw_inner_str)
})

test_that("pre-order: a replacement's children are descended into, but the replacement itself is not re-dispatched", {
  # Lua-style semantics: returning a different node installs it and
  # descent continues into ITS children, but the new node's own
  # handler does not fire at the same position (no re-dispatch).
  doc = pampa_parse("**bold**\n")
  emph_visits = 0L
  str_visits = 0L
  ast_filter(doc, .order = "pre",
    pandoc_strong = function(el) pandoc_emph(content = el@content),
    pandoc_emph   = function(el) { emph_visits <<- emph_visits + 1L; el },
    pandoc_str    = function(el) { str_visits  <<- str_visits + 1L;  el }
  )
  expect_equal(emph_visits, 0L)  # not re-dispatched at strong's slot
  expect_equal(str_visits, 1L)   # but its child str ("bold") IS walked
})

test_that(".order defaults to post and is checked", {
  doc = pampa_parse("x\n")
  expect_silent(ast_filter(doc))
  expect_error(ast_filter(doc, .order = "bogus"), "should be one of")
})
