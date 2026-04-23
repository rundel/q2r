use extendr_api::prelude::*;
use tree_sitter::{Node, TreeCursor};
use tree_sitter_qmd::{LANGUAGE, MarkdownParser};

fn node_to_r(cursor: &mut TreeCursor, src: &[u8]) -> Robj {
    let node: Node = cursor.node();
    let field_name: Robj = match cursor.field_name() {
        Some(s) => Robj::from(s),
        None => Robj::from(NULL),
    };

    let start = node.start_position();
    let end = node.end_position();

    // NOTE: CST `text` semantics deliberately differ from the AST export.
    // Leaves always carry their source text; additionally, any non-leaf
    // whose children do not cover every byte of its range (a grammar
    // "gap" - e.g. `pandoc_math`, `pandoc_display_math` inner content,
    // or `code_fence_content`'s body) also carries the full source span.
    // This lets `to_qmd()` on the R side reconstruct bytes that
    // tree-sitter-qmd parses via anonymous regexes and therefore never
    // emits as named nodes. Revisit if the upstream grammar is changed
    // to surface those bytes as real CST nodes.
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

pub fn parse_cst_to_r(src: &[u8]) -> Robj {
    let mut parser = MarkdownParser::default();
    parser
        .parser
        .set_language(&LANGUAGE.into())
        .expect("failed to set tree-sitter-qmd language");

    // Match pampa's qmd::read: append a trailing newline if absent,
    // so node ranges agree with the text dump pampa emits.
    let owned: Vec<u8>;
    let bytes: &[u8] = if src.ends_with(b"\n") {
        src
    } else {
        owned = {
            let mut v = Vec::with_capacity(src.len() + 1);
            v.extend_from_slice(src);
            v.push(b'\n');
            v
        };
        &owned
    };

    let tree = match parser.parse(bytes, None) {
        Some(t) => t,
        None => return NULL.into(),
    };
    let mut cursor = tree.walk_cursor();
    node_to_r(&mut cursor, bytes)
}
