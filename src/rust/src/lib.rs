use extendr_api::prelude::*;
use pampa::readers::qmd;
use pampa::writers::native;

mod diag_to_r;
mod pd_ast_to_r;
mod ts_ast_to_r;

/// Parse QMD text with pampa.
///
/// Returns a list with `tree` (tree-sitter AST text), `ts_ast`
/// (structured tree-sitter AST as a nested tagged list), `diagnostics`
/// (list of structured diagnostic records that can be rendered via
/// `pampa_diag_format_impl`), `native` (Pandoc native-format text), and
/// `pd_ast` (tagged nested list suitable for conversion to S7 `pandoc`
/// objects).
/// @export
#[extendr]
fn pampa_parse_impl(text: &str, filename: &str) -> List {
    let mut tree_buf: Vec<u8> = Vec::new();
    let result = qmd::read(
        text.as_bytes(),
        false,
        filename,
        &mut tree_buf,
        false,
        None,
    );
    let tree_lines: Vec<String> = String::from_utf8_lossy(&tree_buf)
        .lines()
        .map(str::to_string)
        .collect();
    let ts_ast = ts_ast_to_r::parse_ts_ast_to_r(text.as_bytes());

    match result {
        Ok((pandoc, ctx, diags)) => {
            let mut nbuf: Vec<u8> = Vec::new();
            let native_lines: Vec<String> = match native::write(&pandoc, &ctx, &mut nbuf) {
                Ok(()) => String::from_utf8_lossy(&nbuf)
                    .lines()
                    .map(str::to_string)
                    .collect(),
                Err(_) => Vec::new(),
            };
            let diag_list: Vec<Robj> = diags
                .iter()
                .map(|d| diag_to_r::diag_to_r(d, &ctx.source_context))
                .collect();
            let pd_ast = pd_ast_to_r::pandoc_to_r(&pandoc);
            list!(
                tree = tree_lines,
                ts_ast = ts_ast,
                diagnostics = List::from_values(diag_list),
                native = native_lines,
                pd_ast = pd_ast
            )
        }
        Err(diags) => {
            let mut source_context = quarto_source_map::SourceContext::new();
            source_context.add_file(filename.to_string(), Some(text.to_string()));
            let diag_list: Vec<Robj> = diags
                .iter()
                .map(|d| diag_to_r::diag_to_r(d, &source_context))
                .collect();
            let empty: Vec<String> = Vec::new();
            list!(
                tree = tree_lines,
                ts_ast = ts_ast,
                diagnostics = List::from_values(diag_list),
                native = empty,
                pd_ast = NULL
            )
        }
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
    fn pampa_parse_impl;
    fn pampa_diag_format_impl;
}
