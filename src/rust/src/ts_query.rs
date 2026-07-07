use crate::ts_ast_to_r;
use extendr_api::prelude::*;
use streaming_iterator::StreamingIterator;
use tree_sitter::{Query, QueryCursor};
use tree_sitter_qmd::{LANGUAGE, MarkdownParser};

/// Compile `query_text` against tree-sitter-qmd and run it on `text`.
/// Returns a tagged list with `matches` (a list of named lists, one per
/// match, keyed by capture name) and `error` (NULL on success, a
/// human-readable string on query compile failure).
pub fn run_ts_query(text: &str, query_text: &str) -> List {
    let language: tree_sitter::Language = LANGUAGE.into();

    let query = match Query::new(&language, query_text) {
        Ok(q) => q,
        Err(e) => {
            return list!(matches = NULL, error = format!("{}", e), unsupported = NULL);
        }
    };

    // The cursor only evaluates the text predicates the Rust binding
    // implements (#eq?, #match?, #any-of? and their variants). Anything else
    // compiles as a "general" predicate and is silently ignored by the
    // matcher, so surface the names and let the R side warn.
    let mut unsupported: Vec<String> = Vec::new();
    for i in 0..query.pattern_count() {
        for p in query.general_predicates(i) {
            let name = format!("#{}", p.operator);
            if !unsupported.contains(&name) {
                unsupported.push(name);
            }
        }
    }

    // `MarkdownParser::parse` sets the block grammar itself; `language` above
    // is kept only for `Query::new`.
    let mut parser = MarkdownParser::default();

    let padded = ts_ast_to_r::ensure_trailing_newline(text.as_bytes());
    let bytes: &[u8] = padded.as_ref();

    let tree = match parser.parse(bytes, None) {
        Some(t) => t,
        None => {
            return list!(matches = List::new(0), error = NULL, unsupported = NULL);
        }
    };

    let capture_names: Vec<&str> = query.capture_names().iter().copied().collect();

    let top = tree.walk_cursor();
    let root = top.node();

    let mut cursor = QueryCursor::new();
    let mut matches_iter = cursor.matches(&query, root, bytes);

    let mut out_matches: Vec<Robj> = Vec::new();
    while let Some(m) = matches_iter.next() {
        let mut names: Vec<&str> = Vec::with_capacity(m.captures.len());
        let mut values: Vec<Robj> = Vec::with_capacity(m.captures.len());
        for cap in m.captures.iter() {
            let name = capture_names.get(cap.index as usize).copied().unwrap_or("");
            let mut walker = cap.node.walk();
            let node_value = ts_ast_to_r::node_to_r_at(&mut walker, bytes);
            names.push(name);
            values.push(node_value);
        }
        let mut entry = List::from_values(values);
        let _ = entry.set_names(names);
        out_matches.push(entry.into());
    }

    let unsupported_r: Robj = if unsupported.is_empty() {
        ().into()
    } else {
        unsupported.into()
    };
    list!(
        matches = List::from_values(out_matches),
        error = NULL,
        unsupported = unsupported_r
    )
}
