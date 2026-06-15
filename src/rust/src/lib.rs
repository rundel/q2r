use extendr_api::prelude::*;
use pampa::readers::qmd;
use pampa::writers::qmd as qmd_writer;

mod diag_to_r;
mod pd_ast_to_r;
mod r_to_pd_ast;
mod ts_ast_to_r;
mod ts_query;

fn diags_to_list<I>(diags: I, ctx: &quarto_source_map::SourceContext) -> List
where
    I: IntoIterator<Item = quarto_error_reporting::DiagnosticMessage>,
{
    let v: Vec<Robj> = diags
        .into_iter()
        .map(|d| diag_to_r::diag_to_r(&d, ctx))
        .collect();
    List::from_values(v)
}

fn diags_to_list_ref(
    diags: &[quarto_error_reporting::DiagnosticMessage],
    ctx: &quarto_source_map::SourceContext,
) -> List {
    let v: Vec<Robj> = diags.iter().map(|d| diag_to_r::diag_to_r(d, ctx)).collect();
    List::from_values(v)
}

fn fallback_source_context(text: &str, filename: &str) -> quarto_source_map::SourceContext {
    let mut ctx = quarto_source_map::SourceContext::new();
    ctx.add_file(filename.to_string(), Some(text.to_string()));
    ctx
}

/// Parse QMD text with pampa and return the Pandoc AST.
///
/// Returns a list with `pd_ast` (tagged nested list suitable for
/// conversion to S7 `pandoc` objects, or `NULL` if parsing failed) and
/// `diagnostics` (list of structured diagnostic records that can be
/// rendered via `pampa_diag_format_impl`).
/// @noRd
#[extendr]
fn pampa_parse_pd_impl(text: &str, filename: &str, prune_errors: bool) -> List {
    let mut sink = std::io::sink();
    let result = qmd::read(
        text.as_bytes(),
        false,
        filename,
        &mut sink,
        prune_errors,
        None,
    );
    match result {
        Ok((pandoc, ctx, diags)) => {
            let pd_ast = pd_ast_to_r::pandoc_to_r(&pandoc);
            let diag_list = diags_to_list_ref(&diags, &ctx.source_context);
            list!(pd_ast = pd_ast, diagnostics = diag_list)
        }
        Err(diags) => {
            let ctx = fallback_source_context(text, filename);
            let diag_list = diags_to_list(diags, &ctx);
            list!(pd_ast = NULL, diagnostics = diag_list)
        }
    }
}

/// Parse QMD text with tree-sitter and return the tree-sitter AST.
///
/// Returns a list with `ts_ast` (structured tree-sitter AST as a nested
/// tagged list) and `diagnostics` (list of structured diagnostic records
/// from pampa's QMD reader). The tree-sitter AST itself never fails to
/// produce; `diagnostics` surfaces higher-level pampa parse errors.
/// @noRd
#[extendr]
fn pampa_parse_ts_impl(text: &str, filename: &str, prune_errors: bool) -> List {
    let ts_ast = ts_ast_to_r::parse_ts_ast_to_r(text.as_bytes());
    let mut sink = std::io::sink();
    let result = qmd::read(
        text.as_bytes(),
        false,
        filename,
        &mut sink,
        prune_errors,
        None,
    );
    let diag_list = match result {
        Ok((_, ctx, diags)) => diags_to_list_ref(&diags, &ctx.source_context),
        Err(diags) => {
            let ctx = fallback_source_context(text, filename);
            diags_to_list(diags, &ctx)
        }
    };
    list!(ts_ast = ts_ast, diagnostics = diag_list)
}

/// Render QMD input through pampa's own QMD writer (text/file path).
///
/// Parses `text` with pampa's QMD reader and writes the resulting Pandoc
/// AST back out using `pampa::writers::qmd::write`. Primarily a testing
/// helper for comparing against the R-side `to_qmd()` implementations.
/// Returns a list with `text` (the rendered QMD) and `diagnostics`.
/// @noRd
#[extendr]
fn pampa_write_qmd_text_impl(text: &str, filename: &str) -> List {
    let mut sink = std::io::sink();
    match qmd::read(text.as_bytes(), false, filename, &mut sink, true, None) {
        Ok((pandoc, ctx, parse_diags)) => {
            let mut out: Vec<u8> = Vec::new();
            match qmd_writer::write(&pandoc, &mut out) {
                Ok(()) => {
                    let rendered = String::from_utf8_lossy(&out).into_owned();
                    let diag_list = diags_to_list_ref(&parse_diags, &ctx.source_context);
                    list!(text = rendered, diagnostics = diag_list)
                }
                Err(write_diags) => {
                    let diag_list = diags_to_list(write_diags, &ctx.source_context);
                    list!(text = NULL, diagnostics = diag_list)
                }
            }
        }
        Err(diags) => {
            let ctx = fallback_source_context(text, filename);
            let diag_list = diags_to_list(diags, &ctx);
            list!(text = NULL, diagnostics = diag_list)
        }
    }
}

/// Render an R-constructed Pandoc AST through pampa's QMD writer.
///
/// Takes a tagged-list Pandoc AST (same shape emitted by
/// `pampa_parse_pd_impl`), reconstructs a `pampa::pandoc::Pandoc` value,
/// and writes it out via `pampa::writers::qmd::write`. Returns a list
/// with `text` (rendered QMD, or `NULL` on error) and `diagnostics`
/// (any writer diagnostics; empty on success).
/// @noRd
#[extendr]
fn pampa_write_qmd_ast_impl(r_ast: Robj) -> List {
    let pandoc = match r_to_pd_ast::pandoc_from_r(&r_ast) {
        Ok(p) => p,
        Err(e) => {
            return list!(
                text = NULL,
                diagnostics = List::new(0),
                error = e.to_string()
            );
        }
    };
    let mut out: Vec<u8> = Vec::new();
    match qmd_writer::write(&pandoc, &mut out) {
        Ok(()) => {
            let rendered = String::from_utf8_lossy(&out).into_owned();
            list!(text = rendered, diagnostics = List::new(0), error = NULL)
        }
        Err(write_diags) => {
            let ctx = quarto_source_map::SourceContext::new();
            let diag_list = diags_to_list(write_diags, &ctx);
            list!(text = NULL, diagnostics = diag_list, error = NULL)
        }
    }
}

/// Run a tree-sitter `.scm` query against QMD source.
///
/// Returns `list(matches = list(...), error = NULL)` on success, or
/// `list(matches = NULL, error = "<compile error>")` if the query
/// string fails to compile against the tree-sitter-qmd grammar.
/// @noRd
#[extendr]
fn ts_query_impl(text: &str, query_text: &str) -> List {
    ts_query::run_ts_query(text, query_text)
}

/// Pretty-print a diagnostic by reconstructing it from its slot values.
///
/// Accepts the structured fields carried by a `pampa_diagnostic` S7
/// object (`kind`, `code`, `title`, `problem`, `details`, `hints`,
/// `location`) together with the original source text, filename, and
/// a flag controlling OSC 8 terminal hyperlinks. Returns the ariadne
/// rendering (which includes ANSI colour codes); callers that want
/// colourless output should strip ANSI afterward.
/// @noRd
#[extendr]
fn pampa_diag_format_impl(
    kind: &str,
    code: Robj,
    title: &str,
    problem: Robj,
    details: Robj,
    hints: Robj,
    location: Robj,
    source_text: &str,
    source_filename: &str,
    hyperlinks: bool,
) -> String {
    diag_to_r::format_diag(
        kind,
        code,
        title,
        problem,
        details,
        hints,
        location,
        source_text,
        source_filename,
        hyperlinks,
    )
}

extendr_module! {
    mod q2r;
    fn pampa_parse_pd_impl;
    fn pampa_parse_ts_impl;
    fn pampa_write_qmd_text_impl;
    fn pampa_write_qmd_ast_impl;
    fn pampa_diag_format_impl;
    fn ts_query_impl;
}
