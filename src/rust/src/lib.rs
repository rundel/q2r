use extendr_api::prelude::*;
use pampa::readers::qmd;
use pampa::writers::native;

mod diag_to_r;
mod pd_ast_to_r;
mod ts_ast_to_r;

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
    let v: Vec<Robj> = diags
        .iter()
        .map(|d| diag_to_r::diag_to_r(d, ctx))
        .collect();
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
/// @export
#[extendr]
fn pampa_parse_pd_impl(text: &str, filename: &str) -> List {
    let mut sink = std::io::sink();
    let result = qmd::read(text.as_bytes(), false, filename, &mut sink, false, None);
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
/// @export
#[extendr]
fn pampa_parse_ts_impl(text: &str, filename: &str) -> List {
    let ts_ast = ts_ast_to_r::parse_ts_ast_to_r(text.as_bytes());
    let mut sink = std::io::sink();
    let result = qmd::read(text.as_bytes(), false, filename, &mut sink, false, None);
    let diag_list = match result {
        Ok((_, ctx, diags)) => diags_to_list_ref(&diags, &ctx.source_context),
        Err(diags) => {
            let ctx = fallback_source_context(text, filename);
            diags_to_list(diags, &ctx)
        }
    };
    list!(ts_ast = ts_ast, diagnostics = diag_list)
}

/// Capture pampa's tree-sitter debug dump for QMD text.
///
/// Returns the lines of the `print_whole_tree` output that pampa emits
/// to stderr when run with `-v`. Primarily a testing helper for
/// cross-checking the structured `ts_ast` against pampa's own view.
/// @export
#[extendr]
fn pampa_tree_impl(text: &str, filename: &str) -> Vec<String> {
    let mut tree_buf: Vec<u8> = Vec::new();
    let _ = qmd::read(text.as_bytes(), false, filename, &mut tree_buf, false, None);
    String::from_utf8_lossy(&tree_buf)
        .lines()
        .map(str::to_string)
        .collect()
}

/// Render QMD text to Pandoc's native AST format.
///
/// Returns the lines of `pampa::writers::native::write` applied to the
/// parsed Pandoc document, or an empty vector if parsing failed.
/// Primarily a testing helper.
/// @export
#[extendr]
fn pampa_native_impl(text: &str, filename: &str) -> Vec<String> {
    let mut sink = std::io::sink();
    let result = qmd::read(text.as_bytes(), false, filename, &mut sink, false, None);
    match result {
        Ok((pandoc, ctx, _)) => {
            let mut nbuf: Vec<u8> = Vec::new();
            match native::write(&pandoc, &ctx, &mut nbuf) {
                Ok(()) => String::from_utf8_lossy(&nbuf)
                    .lines()
                    .map(str::to_string)
                    .collect(),
                Err(_) => Vec::new(),
            }
        }
        Err(_) => Vec::new(),
    }
}

/// Pretty-print a diagnostic by reconstructing it from its slot values.
///
/// Accepts the structured fields carried by a `pampa_diagnostic` S7
/// object (`kind`, `code`, `title`, `problem`, `details`, `hints`,
/// `location`) together with the original source text, filename, and
/// a flag controlling OSC 8 terminal hyperlinks. Returns the ariadne
/// rendering (which includes ANSI colour codes); callers that want
/// colourless output should strip ANSI afterward.
/// @export
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
    fn pampa_tree_impl;
    fn pampa_native_impl;
    fn pampa_diag_format_impl;
}
