use extendr_api::prelude::*;
use pampa::pandoc::{
    Attr, Block, Citation, CitationMode, Inline, MathType, Pandoc, QuoteType,
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
        Inline::Attr(attr, _) => list!(tag = "AttrInline", attr = attr_to_r(attr)).into(),
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
        Inline::Shortcode(_) => list!(tag = "Shortcode", name = "").into(),
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
        Block::Table(t) => list!(tag = "Table", attr = attr_to_r(&t.attr)).into(),
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

pub fn pandoc_to_r(p: &Pandoc) -> Robj {
    list!(tag = "Pandoc", blocks = blocks_to_r(&p.blocks)).into()
}
