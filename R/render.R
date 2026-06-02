#' @include pd-ast-pandoc.R to-qmd.R io.R
NULL

#' Render an AST to an output document with Quarto
#'
#' `r lifecycle::badge("experimental")`
#'
#' Writes an in-memory AST back to QMD with [`to_qmd()`] and renders it
#' with [quarto::quarto_render()], the q2r analog of parsermd's
#' `render()`. The document is rendered inside a temporary directory and
#' the resulting artifacts (the rendered file plus any `*_files/`
#' resource directory) are copied to the destination, so it never
#' clobbers your working directory mid-render.
#'
#' Because rendering happens in a temporary directory, relative resource
#' references in the document (local images, includes, `{{< include >}}`
#' shortcodes) will not resolve. This wrapper is intended for
#' self-contained documents.
#'
#' Requires the `quarto` package (in `Suggests`) and a Quarto
#' installation.
#'
#' @param x A [`pandoc`] or [`ts_tree`] AST.
#' @param output_file Destination path for the rendered output. Its
#'   directory and base name are used; the extension follows from the
#'   rendered format. If `NULL`, the output is written to the working
#'   directory as `document.<ext>`.
#' @param output_format Quarto output format (e.g. `"html"`, `"pdf"`),
#'   passed to [quarto::quarto_render()]. `NULL` uses the document /
#'   Quarto default.
#' @param ... Further arguments passed to [quarto::quarto_render()].
#' @param quiet Suppress Quarto's rendering output.
#' @return The path to the rendered output file, invisibly.
#'
#' @examples
#' \dontrun{
#' doc = parse_qmd("# Title\n\nHello world.\n")
#' render_qmd(doc, "hello.html")
#' }
#'
#' @export
render_qmd = function(x, output_file = NULL, output_format = NULL, ..., quiet = FALSE) {
  rlang::check_installed("quarto", reason = "to render a document with `render_qmd()`.")

  stem = if (is.null(output_file)) {
    "document"
  } else {
    tools::file_path_sans_ext(basename(output_file))
  }
  dest_dir = if (is.null(output_file)) "." else dirname(output_file)
  if (!nzchar(dest_dir)) dest_dir = "."

  workdir = withr::local_tempdir()
  input = file.path(workdir, paste0(stem, ".qmd"))
  write_qmd(x, input)

  quarto::quarto_render(
    input = input,
    output_format = output_format,
    ...,
    quiet = quiet
  )
  file.remove(input)

  produced = list.files(workdir, full.names = TRUE)
  if (length(produced) == 0L) {
    stop("`render_qmd()`: Quarto produced no output.", call. = FALSE)
  }
  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  file.copy(produced, dest_dir, recursive = TRUE, overwrite = TRUE)

  main = produced[!utils::file_test("-d", produced)]
  if (length(main) == 0L) main = produced
  invisible(file.path(dest_dir, basename(main[[1L]])))
}
