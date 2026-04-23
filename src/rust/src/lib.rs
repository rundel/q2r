use extendr_api::prelude::*;
use pampa::readers::qmd;
use pampa::writers::native;

mod ast_to_r;
mod cst_to_r;

/// Parse QMD text with pampa.
///
/// Returns a list with `tree` (tree-sitter CST text), `cst` (structured
/// tree-sitter CST as a nested tagged list), `diagnostics`, `native`
/// (Pandoc native-format text), and `ast` (tagged nested list suitable
/// for conversion to S7 `pandoc` objects).
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
    let cst = cst_to_r::parse_cst_to_r(text.as_bytes());

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
            let diag_lines: Vec<String> = diags.iter().map(|d| d.to_text(None)).collect();
            let ast = ast_to_r::pandoc_to_r(&pandoc);
            list!(
                tree = tree_lines,
                cst = cst,
                diagnostics = diag_lines,
                native = native_lines,
                ast = ast
            )
        }
        Err(diags) => {
            let diag_lines: Vec<String> = diags.iter().map(|d| d.to_text(None)).collect();
            let empty: Vec<String> = Vec::new();
            list!(
                tree = tree_lines,
                cst = cst,
                diagnostics = diag_lines,
                native = empty,
                ast = NULL
            )
        }
    }
}

extendr_module! {
    mod q2r;
    fn pampa_parse_impl;
}
