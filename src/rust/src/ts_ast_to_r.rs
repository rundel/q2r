use extendr_api::prelude::*;
use std::borrow::Cow;
use tree_sitter::{Node, TreeCursor};
use tree_sitter_qmd::MarkdownParser;

/// Append a trailing newline if absent, matching pampa's `qmd::read` so node
/// ranges agree with the text pampa emits. Shared by the ts AST and ts query
/// entry points (which both feed bytes to `MarkdownParser::parse`).
pub fn ensure_trailing_newline(src: &[u8]) -> Cow<'_, [u8]> {
    if src.ends_with(b"\n") {
        Cow::Borrowed(src)
    } else {
        let mut v = Vec::with_capacity(src.len() + 1);
        v.extend_from_slice(src);
        v.push(b'\n');
        Cow::Owned(v)
    }
}

fn node_to_r(cursor: &mut TreeCursor, src: &[u8]) -> Robj {
    let node: Node = cursor.node();
    let field_name: Robj = match cursor.field_name() {
        Some(s) => Robj::from(s),
        None => Robj::from(NULL),
    };

    let start = node.start_position();
    let end = node.end_position();

    // NOTE: ts_ast `text` semantics deliberately differ from the pd_ast export.
    // Leaves always carry their source text; additionally, any non-leaf
    // whose children do not cover every byte of its range (a grammar
    // "gap" - e.g. `pandoc_math`, `pandoc_display_math` inner content,
    // or `code_fence_content`'s body) also carries the full source span.
    // This lets `to_qmd()` on the R side reconstruct bytes that
    // tree-sitter-qmd parses via anonymous regexes and therefore never
    // emits as named nodes. Revisit if the upstream grammar is changed
    // to surface those bytes as real named nodes.
    let text: Robj = {
        let sb = node.start_byte();
        let eb = node.end_byte();
        let needs_text = if node.child_count() == 0 {
            true
        } else {
            has_child_gap(&node, sb, eb)
        };
        if needs_text {
            let slice = src.get(sb..eb).unwrap_or(&[]);
            Robj::from(String::from_utf8_lossy(slice).into_owned())
        } else {
            Robj::from(NULL)
        }
    };

    let children = children_to_r(cursor, src);

    list!(
        kind = node.kind(),
        is_named = node.is_named(),
        field_name = field_name,
        start_byte = node.start_byte() as i32,
        end_byte = node.end_byte() as i32,
        start_row = start.row as i32,
        start_col = start.column as i32,
        end_row = end.row as i32,
        end_col = end.column as i32,
        text = text,
        children = children
    )
    .into()
}

fn has_child_gap(node: &Node, start_byte: usize, end_byte: usize) -> bool {
    let mut walker = node.walk();
    let mut covered_to = start_byte;
    let mut any = false;
    if walker.goto_first_child() {
        loop {
            any = true;
            let ch = walker.node();
            if ch.start_byte() > covered_to {
                return true;
            }
            if ch.end_byte() > covered_to {
                covered_to = ch.end_byte();
            }
            if !walker.goto_next_sibling() {
                break;
            }
        }
    }
    if !any {
        return false;
    }
    covered_to < end_byte
}

fn children_to_r(cursor: &mut TreeCursor, src: &[u8]) -> Robj {
    let mut out: Vec<Robj> = Vec::new();
    if cursor.goto_first_child() {
        loop {
            out.push(node_to_r(cursor, src));
            if !cursor.goto_next_sibling() {
                break;
            }
        }
        cursor.goto_parent();
    }
    List::from_values(out).into()
}

/// Serialize the node a cursor is positioned at into the tagged-list
/// shape consumed by `ts_node_from_list()`. Re-exposes the private
/// `node_to_r` helper for use by `ts_query.rs`.
pub fn node_to_r_at(cursor: &mut TreeCursor, src: &[u8]) -> Robj {
    node_to_r(cursor, src)
}

pub fn parse_ts_ast_to_r(src: &[u8]) -> Robj {
    // `MarkdownParser::parse` sets the block grammar itself, so no manual
    // `set_language` is needed here.
    let mut parser = MarkdownParser::default();
    let bytes = ensure_trailing_newline(src);

    let tree = match parser.parse(&bytes, None) {
        Some(t) => t,
        None => return NULL.into(),
    };
    let mut cursor = tree.walk_cursor();
    node_to_r(&mut cursor, &bytes)
}
