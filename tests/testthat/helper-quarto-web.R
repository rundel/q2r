quarto_web_root = function() {
  testthat::test_path("..", "fixtures", "quarto-web")
}

quarto_web_available = function() {
  root = quarto_web_root()
  dir.exists(root) && file.exists(file.path(root, "_quarto.yml"))
}

skip_if_no_quarto_web = function() {
  if (!quarto_web_available()) {
    testthat::skip("quarto-web submodule not checked out (run `git submodule update --init`)")
  }
}

quarto_web_files = function() {
  root = quarto_web_root()
  files = list.files(root, pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE)
  substr(files, nchar(root) + 2L, nchar(files))
}

quarto_web_read = function(rel) {
  paste(readLines(file.path(quarto_web_root(), rel), warn = FALSE), collapse = "\n")
}

quarto_web_skip_file = function() {
  testthat::test_path("quarto-web-skip.tsv")
}

quarto_web_skip_set = function(path) {
  f = quarto_web_skip_file()
  if (!file.exists(f)) return(character())
  tbl = utils::read.table(
    f, sep = "\t", header = FALSE, comment.char = "#",
    stringsAsFactors = FALSE, col.names = c("path", "file"),
    blank.lines.skip = TRUE, fill = TRUE
  )
  tbl = tbl[tbl$path == path | tbl$path == "all", , drop = FALSE]
  unique(tbl$file)
}

has_error_diagnostics = function(x) {
  diags = x@diagnostics
  if (!length(diags)) return(FALSE)
  any(vapply(diags, function(d) identical(d@kind, "error"), logical(1)))
}

ts_kind_tree = function(node) {
  list(
    kind     = node@kind,
    named    = node@is_named,
    field    = node@field_name %||% NA_character_,
    children = lapply(node@children@content, ts_kind_tree)
  )
}

ts_tree_kind_tree = function(tree) ts_kind_tree(tree@root)

compare_ts_kind = function(a, b) identical(ts_tree_kind_tree(a), ts_tree_kind_tree(b))

compare_pd_native = function(a_text, b_text, filename = "<cmp>") {
  identical(pampa_native(a_text), pampa_native(b_text))
}

run_roundtrip = function(files, path_id, fn) {
  skip = quarto_web_skip_set(path_id)
  files = setdiff(files, skip)
  failures = character()
  errors   = character()
  passes   = 0L
  for (f in files) {
    text = tryCatch(quarto_web_read(f), error = function(e) NULL)
    if (is.null(text)) next
    res = tryCatch(fn(text, f), error = function(e) structure(list(), error = conditionMessage(e)))
    if (is.list(res) && !is.null(attr(res, "error"))) {
      errors = c(errors, sprintf("%s: %s", f, attr(res, "error")))
      next
    }
    if (isTRUE(res$skip)) next
    if (!isTRUE(res$ok)) {
      failures = c(failures, sprintf("%s: %s", f, res$reason %||% "mismatch"))
    } else {
      passes = passes + 1L
    }
  }
  list(passes = passes, failures = failures, errors = errors, skipped = length(skip))
}

roundtrip_report_path = function() {
  env = Sys.getenv("Q2R_QUARTO_WEB_REPORT", unset = "")
  if (nzchar(env)) return(env)
  file.path(tempdir(), "q2r-quarto-web-report.txt")
}

roundtrip_report = function(label, res) {
  total = res$passes + length(res$failures) + length(res$errors)
  lines = c(
    sprintf(
      "[%s] %d files | %d pass | %d fail | %d error | %d skipped",
      label, total, res$passes, length(res$failures), length(res$errors), res$skipped
    )
  )
  if (length(res$failures)) {
    lines = c(lines, "  failures:", paste0("    ", res$failures))
  }
  if (length(res$errors)) {
    lines = c(lines, "  errors:", paste0("    ", res$errors))
  }
  lines = c(lines, "")
  out = roundtrip_report_path()
  cat(lines, file = out, sep = "\n", append = TRUE)
  message(lines[1L])
}
