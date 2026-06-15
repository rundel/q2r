use extendr_api::prelude::*;
use pampa::pandoc::{
    Alignment, Attr, Block, Caption, Cell, Citation, CitationMode, ColSpec, ColWidth, ConfigValue,
    ConfigValueKind, Inline, MathType, Pandoc, QuoteType, Row, Shortcode, ShortcodeArg, Table,
    TableBody, TableFoot, TableHead,
};

fn attr_to_r(attr: &Attr) -> Robj {
    let (id, classes, attrs) = attr;
    let class_vec: Vec<&str> = classes.iter().map(|s| s.as_str()).collect();
    let keys: Vec<&str> = attrs.keys().map(|s| s.as_str()).collect();
    let vals: Vec<&str> = attrs.values().map(|s| s.as_str()).collect();
    list!(
        id = id.as_str(),
        classes = class_vec,
        keys = keys,
        values = vals
    )
    .into()
}

fn inlines_to_r(items: &[Inline]) -> Robj {
    let v: Vec<Robj> = items.iter().map(inline_to_r).collect();
    List::from_values(v).into()
}

fn blocks_to_r(items: &[Block]) -> Robj {
    let v: Vec<Robj> = items.iter().map(block_to_r).collect();
    List::from_values(v).into()
}

fn shortcode_arg_to_r(arg: &ShortcodeArg) -> Robj {
    match arg {
        ShortcodeArg::String(s) => list!(kind = "string", value = s.as_str()).into(),
        ShortcodeArg::Number(n) => list!(kind = "number", value = *n).into(),
        ShortcodeArg::Boolean(b) => list!(kind = "boolean", value = *b).into(),
        ShortcodeArg::Shortcode(sc) => list!(kind = "shortcode", value = shortcode_to_r(sc)).into(),
        ShortcodeArg::KeyValue(map) => {
            let kvs: Vec<Robj> = map
                .iter()
                .map(|(k, v)| {
                    list!(kind = "kv", key = k.as_str(), value = shortcode_arg_to_r(v)).into()
                })
                .collect();
            list!(kind = "kv_group", value = List::from_values(kvs)).into()
        }
    }
}

fn shortcode_to_r(sc: &Shortcode) -> Robj {
    let pos: Vec<Robj> = sc.positional_args.iter().map(shortcode_arg_to_r).collect();
    let kw: Vec<Robj> = sc
        .keyword_args
        .iter()
        .map(|(k, v)| list!(kind = "kv", key = k.as_str(), value = shortcode_arg_to_r(v)).into())
        .collect();
    list!(
        tag = "Shortcode",
        is_escaped = sc.is_escaped,
        name = sc.name.as_str(),
        positional_args = List::from_values(pos),
        keyword_args = List::from_values(kw)
    )
    .into()
}

fn alignment_to_str(a: &Alignment) -> &'static str {
    match a {
        Alignment::Left => "Left",
        Alignment::Center => "Center",
        Alignment::Right => "Right",
        Alignment::Default => "Default",
    }
}

fn colspec_to_r(cs: &ColSpec) -> Robj {
    let (alignment, width) = cs;
    let width_obj: Robj = match width {
        ColWidth::Default => Robj::from(NULL),
        ColWidth::Percentage(p) => Robj::from(*p),
    };
    list!(alignment = alignment_to_str(alignment), width = width_obj).into()
}

fn caption_to_r(c: &Caption) -> Robj {
    let short_obj: Robj = match &c.short {
        Some(inlines) => inlines_to_r(inlines),
        None => Robj::from(NULL),
    };
    let long_obj: Robj = match &c.long {
        Some(blocks) => blocks_to_r(blocks),
        None => List::from_values(Vec::<Robj>::new()).into(),
    };
    list!(short = short_obj, long = long_obj).into()
}

fn cell_to_r(c: &Cell) -> Robj {
    list!(
        attr = attr_to_r(&c.attr),
        alignment = alignment_to_str(&c.alignment),
        row_span = c.row_span as i32,
        col_span = c.col_span as i32,
        content = blocks_to_r(&c.content)
    )
    .into()
}

fn row_to_r(r: &Row) -> Robj {
    let cells: Vec<Robj> = r.cells.iter().map(cell_to_r).collect();
    list!(attr = attr_to_r(&r.attr), cells = List::from_values(cells)).into()
}

fn table_head_to_r(h: &TableHead) -> Robj {
    let rows: Vec<Robj> = h.rows.iter().map(row_to_r).collect();
    list!(attr = attr_to_r(&h.attr), rows = List::from_values(rows)).into()
}

fn table_body_to_r(b: &TableBody) -> Robj {
    let head_rows: Vec<Robj> = b.head.iter().map(row_to_r).collect();
    let body_rows: Vec<Robj> = b.body.iter().map(row_to_r).collect();
    list!(
        attr = attr_to_r(&b.attr),
        row_head_columns = b.rowhead_columns as i32,
        head_rows = List::from_values(head_rows),
        body_rows = List::from_values(body_rows)
    )
    .into()
}

fn table_foot_to_r(f: &TableFoot) -> Robj {
    let rows: Vec<Robj> = f.rows.iter().map(row_to_r).collect();
    list!(attr = attr_to_r(&f.attr), rows = List::from_values(rows)).into()
}

fn table_to_r(t: &Table) -> Robj {
    let colspec: Vec<Robj> = t.colspec.iter().map(colspec_to_r).collect();
    let bodies: Vec<Robj> = t.bodies.iter().map(table_body_to_r).collect();
    list!(
        tag = "Table",
        attr = attr_to_r(&t.attr),
        caption = caption_to_r(&t.caption),
        colspec = List::from_values(colspec),
        head = table_head_to_r(&t.head),
        bodies = List::from_values(bodies),
        foot = table_foot_to_r(&t.foot)
    )
    .into()
}

fn citation_to_r(c: &Citation) -> Robj {
    let mode = match c.mode {
        CitationMode::AuthorInText => "AuthorInText",
        CitationMode::SuppressAuthor => "SuppressAuthor",
        CitationMode::NormalCitation => "NormalCitation",
    };
    list!(
        id = c.id.as_str(),
        mode = mode,
        prefix = inlines_to_r(&c.prefix),
        suffix = inlines_to_r(&c.suffix),
        note_num = c.note_num as i32,
        hash = c.hash as i32
    )
    .into()
}

fn inline_to_r(i: &Inline) -> Robj {
    match i {
        Inline::Str(s) => list!(tag = "Str", text = s.text.as_str()).into(),
        Inline::Space(_) => list!(tag = "Space").into(),
        Inline::SoftBreak(_) => list!(tag = "SoftBreak").into(),
        Inline::LineBreak(_) => list!(tag = "LineBreak").into(),
        Inline::Emph(e) => list!(tag = "Emph", content = inlines_to_r(&e.content)).into(),
        Inline::Underline(u) => {
            list!(tag = "Underline", content = inlines_to_r(&u.content)).into()
        }
        Inline::Strong(s) => list!(tag = "Strong", content = inlines_to_r(&s.content)).into(),
        Inline::Strikeout(s) => {
            list!(tag = "Strikeout", content = inlines_to_r(&s.content)).into()
        }
        Inline::Superscript(s) => {
            list!(tag = "Superscript", content = inlines_to_r(&s.content)).into()
        }
        Inline::Subscript(s) => {
            list!(tag = "Subscript", content = inlines_to_r(&s.content)).into()
        }
        Inline::SmallCaps(s) => {
            list!(tag = "SmallCaps", content = inlines_to_r(&s.content)).into()
        }
        Inline::Code(c) => list!(
            tag = "Code",
            attr = attr_to_r(&c.attr),
            text = c.text.as_str()
        )
        .into(),
        Inline::Math(m) => {
            let mt = match m.math_type {
                MathType::InlineMath => "inline",
                MathType::DisplayMath => "display",
            };
            list!(tag = "Math", math_type = mt, text = m.text.as_str()).into()
        }
        Inline::RawInline(r) => list!(
            tag = "RawInline",
            format = r.format.as_str(),
            text = r.text.as_str()
        )
        .into(),
        Inline::Quoted(q) => {
            let qt = match q.quote_type {
                QuoteType::SingleQuote => "single",
                QuoteType::DoubleQuote => "double",
            };
            list!(
                tag = "Quoted",
                quote_type = qt,
                content = inlines_to_r(&q.content)
            )
            .into()
        }
        Inline::Link(l) => list!(
            tag = "Link",
            attr = attr_to_r(&l.attr),
            content = inlines_to_r(&l.content),
            url = l.target.0.as_str(),
            title = l.target.1.as_str()
        )
        .into(),
        Inline::Image(im) => list!(
            tag = "Image",
            attr = attr_to_r(&im.attr),
            content = inlines_to_r(&im.content),
            url = im.target.0.as_str(),
            title = im.target.1.as_str()
        )
        .into(),
        Inline::Note(n) => list!(tag = "Note", content = blocks_to_r(&n.content)).into(),
        Inline::Span(s) => list!(
            tag = "Span",
            attr = attr_to_r(&s.attr),
            content = inlines_to_r(&s.content)
        )
        .into(),
        Inline::Cite(c) => {
            let cs: Vec<Robj> = c.citations.iter().map(citation_to_r).collect();
            list!(
                tag = "Cite",
                citations = List::from_values(cs),
                content = inlines_to_r(&c.content)
            )
            .into()
        }
        Inline::NoteReference(nr) => {
            list!(tag = "NoteReference", id = nr.id.as_str()).into()
        }
        Inline::Attr(ia) => list!(tag = "AttrInline", attr = attr_to_r(&ia.attr)).into(),
        Inline::Insert(x) => list!(
            tag = "Insert",
            attr = attr_to_r(&x.attr),
            content = inlines_to_r(&x.content)
        )
        .into(),
        Inline::Delete(x) => list!(
            tag = "Delete",
            attr = attr_to_r(&x.attr),
            content = inlines_to_r(&x.content)
        )
        .into(),
        Inline::Highlight(x) => list!(
            tag = "Highlight",
            attr = attr_to_r(&x.attr),
            content = inlines_to_r(&x.content)
        )
        .into(),
        Inline::EditComment(x) => list!(
            tag = "EditComment",
            attr = attr_to_r(&x.attr),
            content = inlines_to_r(&x.content)
        )
        .into(),
        Inline::Shortcode(sc) => shortcode_to_r(sc),
        Inline::Custom(_) => list!(tag = "CustomInline", type_name = "").into(),
    }
}

fn block_to_r(b: &Block) -> Robj {
    match b {
        Block::Plain(p) => list!(tag = "Plain", content = inlines_to_r(&p.content)).into(),
        Block::Paragraph(p) => {
            list!(tag = "Paragraph", content = inlines_to_r(&p.content)).into()
        }
        Block::LineBlock(lb) => {
            let lines: Vec<Robj> = lb
                .content
                .iter()
                .map(|line| inlines_to_r(line))
                .collect();
            list!(tag = "LineBlock", content = List::from_values(lines)).into()
        }
        Block::CodeBlock(c) => list!(
            tag = "CodeBlock",
            attr = attr_to_r(&c.attr),
            text = c.text.as_str()
        )
        .into(),
        Block::RawBlock(r) => list!(
            tag = "RawBlock",
            format = r.format.as_str(),
            text = r.text.as_str()
        )
        .into(),
        Block::BlockQuote(bq) => {
            list!(tag = "BlockQuote", content = blocks_to_r(&bq.content)).into()
        }
        Block::OrderedList(ol) => {
            let items: Vec<Robj> = ol.content.iter().map(|item| blocks_to_r(item)).collect();
            list!(
                tag = "OrderedList",
                start = ol.attr.0 as i32,
                style = format!("{:?}", ol.attr.1).as_str(),
                delim = format!("{:?}", ol.attr.2).as_str(),
                items = List::from_values(items)
            )
            .into()
        }
        Block::BulletList(bl) => {
            let items: Vec<Robj> = bl.content.iter().map(|item| blocks_to_r(item)).collect();
            list!(tag = "BulletList", items = List::from_values(items)).into()
        }
        Block::DefinitionList(dl) => {
            let items: Vec<Robj> = dl
                .content
                .iter()
                .map(|(term, defs)| {
                    let def_list: Vec<Robj> =
                        defs.iter().map(|d| blocks_to_r(d)).collect();
                    list!(
                        term = inlines_to_r(term),
                        defs = List::from_values(def_list)
                    )
                    .into()
                })
                .collect();
            list!(tag = "DefinitionList", items = List::from_values(items)).into()
        }
        Block::Header(h) => list!(
            tag = "Header",
            level = h.level as i32,
            attr = attr_to_r(&h.attr),
            content = inlines_to_r(&h.content)
        )
        .into(),
        Block::HorizontalRule(_) => list!(tag = "HorizontalRule").into(),
        Block::Figure(f) => {
            let cap = f.caption.long.as_deref().unwrap_or(&[]);
            list!(
                tag = "Figure",
                attr = attr_to_r(&f.attr),
                caption = blocks_to_r(cap),
                content = blocks_to_r(&f.content)
            )
            .into()
        }
        Block::Div(d) => list!(
            tag = "Div",
            attr = attr_to_r(&d.attr),
            content = blocks_to_r(&d.content)
        )
        .into(),
        Block::Table(t) => table_to_r(t),
        Block::BlockMetadata(_) => list!(tag = "BlockMetadata").into(),
        Block::NoteDefinitionPara(n) => list!(
            tag = "NoteDefinitionPara",
            id = n.id.as_str(),
            content = inlines_to_r(&n.content)
        )
        .into(),
        Block::NoteDefinitionFencedBlock(n) => list!(
            tag = "NoteDefinitionFencedBlock",
            id = n.id.as_str(),
            content = blocks_to_r(&n.content)
        )
        .into(),
        Block::CaptionBlock(c) => {
            list!(tag = "CaptionBlock", content = inlines_to_r(&c.content)).into()
        }
        Block::Custom(_) => list!(tag = "CustomBlock", type_name = "").into(),
    }
}

// Document metadata (Pandoc.meta) is exported as a value-only tagged list
// mirroring ConfigValueKind; source_info and merge_op are intentionally
// dropped (the QMD writer ignores them, and dropping them keeps the
// round-trip AST comparison stable).
fn config_value_to_r(cv: &ConfigValue) -> Robj {
    match &cv.value {
        ConfigValueKind::Map(entries) => {
            let keys: Vec<&str> = entries.iter().map(|e| e.key.as_str()).collect();
            let vals: Vec<Robj> = entries.iter().map(|e| config_value_to_r(&e.value)).collect();
            list!(kind = "map", keys = keys, values = List::from_values(vals)).into()
        }
        ConfigValueKind::Array(items) => {
            let vals: Vec<Robj> = items.iter().map(config_value_to_r).collect();
            list!(kind = "list", value = List::from_values(vals)).into()
        }
        ConfigValueKind::PandocInlines(inlines) => {
            list!(kind = "inlines", value = inlines_to_r(inlines)).into()
        }
        ConfigValueKind::PandocBlocks(blocks) => {
            list!(kind = "blocks", value = blocks_to_r(blocks)).into()
        }
        ConfigValueKind::Path(s) => list!(kind = "path", value = s.as_str()).into(),
        ConfigValueKind::Glob(s) => list!(kind = "glob", value = s.as_str()).into(),
        ConfigValueKind::Expr(s) => list!(kind = "expr", value = s.as_str()).into(),
        ConfigValueKind::Scalar(_) => {
            let inner = serde_json::to_value(&cv.value)
                .ok()
                .and_then(|v| v.get("Scalar").cloned())
                .unwrap_or(serde_json::Value::Null);
            scalar_json_to_r(&inner)
        }
    }
}

fn scalar_json_to_r(v: &serde_json::Value) -> Robj {
    match v {
        serde_json::Value::Null => list!(kind = "null").into(),
        serde_json::Value::Bool(b) => list!(kind = "bool", value = *b).into(),
        serde_json::Value::Number(n) => {
            if let Some(i) = n.as_i64() {
                list!(kind = "int", value = i as f64).into()
            } else {
                list!(kind = "real", value = n.as_f64().unwrap_or(f64::NAN)).into()
            }
        }
        serde_json::Value::String(s) => list!(kind = "string", value = s.as_str()).into(),
        serde_json::Value::Array(arr) => {
            let vals: Vec<Robj> = arr.iter().map(scalar_json_to_r).collect();
            list!(kind = "list", value = List::from_values(vals)).into()
        }
        serde_json::Value::Object(obj) => {
            let keys: Vec<&str> = obj.keys().map(|s| s.as_str()).collect();
            let vals: Vec<Robj> = obj.values().map(scalar_json_to_r).collect();
            list!(kind = "map", keys = keys, values = List::from_values(vals)).into()
        }
    }
}

pub fn pandoc_to_r(p: &Pandoc) -> Robj {
    list!(
        tag = "Pandoc",
        meta = config_value_to_r(&p.meta),
        blocks = blocks_to_r(&p.blocks)
    )
    .into()
}
