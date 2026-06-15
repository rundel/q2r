use extendr_api::prelude::*;
use extendr_api::Result as ERResult;
use hashlink::LinkedHashMap;
use pampa::pandoc::attr::{AttrSourceInfo, TargetSourceInfo, empty_attr};
use pampa::pandoc::block::{
    BlockQuote, BulletList, CaptionBlock, CodeBlock, DefinitionList, Div, Figure, Header,
    HorizontalRule, LineBlock, NoteDefinitionFencedBlock, NoteDefinitionPara, OrderedList,
    Paragraph, Plain, RawBlock,
};
use pampa::pandoc::caption::Caption;
use pampa::pandoc::inline::{
    Cite, Citation, CitationMode, Code, Delete, EditComment, Emph, Highlight, Image, InlineAttr,
    Insert, LineBreak, Link, Math, MathType, Note, NoteReference, Quoted, QuoteType, RawInline,
    SmallCaps, SoftBreak, Space, Str, Strikeout, Strong, Subscript, Superscript, Underline, Span,
};
use pampa::pandoc::list::{ListAttributes, ListNumberDelim, ListNumberStyle};
use std::collections::HashMap;
use pampa::pandoc::table::{
    Alignment, Cell, ColSpec, ColWidth, Row, Table, TableBody, TableFoot, TableHead,
};
use pampa::pandoc::{
    Attr, Block, ConfigMapEntry, ConfigValue, ConfigValueKind, Inline, MergeOp, Pandoc, Shortcode,
    ShortcodeArg,
};
use quarto_source_map::{FileId, SourceInfo};

fn default_si() -> SourceInfo {
    SourceInfo::original(FileId(0), 0, 0)
}

fn field(list: &List, name: &str) -> Option<Robj> {
    for (nm, val) in list.iter() {
        if nm == name {
            return Some(val);
        }
    }
    None
}

fn as_list(r: &Robj) -> ERResult<List> {
    List::try_from(r.clone()).map_err(|_| Error::Other("expected a list".into()))
}

fn opt_str(r: &Robj) -> Option<String> {
    if r.is_null() {
        return None;
    }
    if let Ok(s) = <&str>::try_from(r) {
        return Some(s.to_string());
    }
    if let Ok(sv) = <Vec<String>>::try_from(r) {
        if sv.len() == 1 {
            return Some(sv.into_iter().next().unwrap());
        }
    }
    None
}

fn need_str(list: &List, name: &str) -> ERResult<String> {
    field(list, name)
        .and_then(|r| opt_str(&r))
        .ok_or_else(|| Error::Other(format!("missing string field '{}'", name)))
}

fn str_or_empty(list: &List, name: &str) -> String {
    field(list, name)
        .and_then(|r| opt_str(&r))
        .unwrap_or_default()
}

fn opt_i32(r: &Robj) -> Option<i32> {
    if r.is_null() {
        return None;
    }
    if let Ok(v) = i32::try_from(r) {
        return Some(v);
    }
    if let Ok(v) = <Vec<i32>>::try_from(r) {
        if v.len() == 1 {
            return Some(v[0]);
        }
    }
    if let Ok(v) = f64::try_from(r) {
        return Some(v as i32);
    }
    None
}

fn need_i32(list: &List, name: &str) -> ERResult<i32> {
    field(list, name)
        .and_then(|r| opt_i32(&r))
        .ok_or_else(|| Error::Other(format!("missing integer field '{}'", name)))
}

fn need_f64(list: &List, name: &str) -> ERResult<f64> {
    field(list, name)
        .and_then(|r| opt_f64(&r))
        .ok_or_else(|| Error::Other(format!("missing numeric field '{}'", name)))
}

fn need_bool(list: &List, name: &str) -> ERResult<bool> {
    field(list, name)
        .and_then(|r| opt_bool(&r))
        .ok_or_else(|| Error::Other(format!("missing logical field '{}'", name)))
}

fn need_tag(list: &List) -> ERResult<String> {
    need_str(list, "tag")
}

fn str_vec(r: &Robj) -> Vec<String> {
    if r.is_null() {
        return Vec::new();
    }
    if let Ok(v) = <Vec<String>>::try_from(r) {
        return v;
    }
    if let Ok(s) = <&str>::try_from(r) {
        return vec![s.to_string()];
    }
    Vec::new()
}

fn attr_from_r(r: &Robj) -> ERResult<Attr> {
    if r.is_null() {
        return Ok(empty_attr());
    }
    let lst = as_list(r)?;
    let id = field(&lst, "id")
        .and_then(|x| opt_str(&x))
        .unwrap_or_default();
    let classes = field(&lst, "classes")
        .map(|x| str_vec(&x))
        .unwrap_or_default();
    let keys = field(&lst, "keys")
        .map(|x| str_vec(&x))
        .unwrap_or_default();
    let values = field(&lst, "values")
        .map(|x| str_vec(&x))
        .unwrap_or_default();
    let mut map: LinkedHashMap<String, String> = LinkedHashMap::new();
    for (k, v) in keys.into_iter().zip(values.into_iter()) {
        map.insert(k, v);
    }
    Ok((id, classes, map))
}

fn items_from_r(r: &Robj) -> ERResult<Vec<List>> {
    if r.is_null() {
        return Ok(Vec::new());
    }
    let lst = as_list(r)?;
    let mut out = Vec::with_capacity(lst.len());
    for (_, v) in lst.iter() {
        out.push(as_list(&v)?);
    }
    Ok(out)
}

fn inlines_from_r(r: &Robj) -> ERResult<Vec<Inline>> {
    let items = items_from_r(r)?;
    items.into_iter().map(inline_from_list).collect()
}

fn blocks_from_r(r: &Robj) -> ERResult<Vec<Block>> {
    let items = items_from_r(r)?;
    items.into_iter().map(block_from_list).collect()
}

fn blocks_from_content_field(list: &List, name: &str) -> ERResult<Vec<Block>> {
    match field(list, name) {
        Some(r) => blocks_from_r(&r),
        None => Ok(Vec::new()),
    }
}

fn inlines_from_content_field(list: &List, name: &str) -> ERResult<Vec<Inline>> {
    match field(list, name) {
        Some(r) => inlines_from_r(&r),
        None => Ok(Vec::new()),
    }
}

fn attr_field(list: &List) -> ERResult<Attr> {
    match field(list, "attr") {
        Some(r) => attr_from_r(&r),
        None => Ok(empty_attr()),
    }
}

fn alignment_from_str(s: &str) -> Alignment {
    match s {
        "Left" => Alignment::Left,
        "Right" => Alignment::Right,
        "Center" => Alignment::Center,
        _ => Alignment::Default,
    }
}

fn opt_bool(r: &Robj) -> Option<bool> {
    if r.is_null() {
        return None;
    }
    if let Ok(v) = bool::try_from(r) {
        return Some(v);
    }
    if let Some(slice) = r.as_logical_slice() {
        if slice.len() == 1 {
            return Some(slice[0].to_bool());
        }
    }
    None
}

fn opt_f64(r: &Robj) -> Option<f64> {
    if r.is_null() {
        return None;
    }
    if let Ok(v) = f64::try_from(r) {
        return Some(v);
    }
    if let Ok(v) = <Vec<f64>>::try_from(r) {
        if v.len() == 1 {
            return Some(v[0]);
        }
    }
    None
}

fn colspec_from_r(r: &Robj) -> ERResult<ColSpec> {
    let lst = as_list(r)?;
    let alignment = alignment_from_str(&str_or_empty(&lst, "alignment"));
    let width = match field(&lst, "width") {
        Some(w) => match opt_f64(&w) {
            Some(v) => ColWidth::Percentage(v),
            None => ColWidth::Default,
        },
        None => ColWidth::Default,
    };
    Ok((alignment, width))
}

fn caption_from_r(r: &Robj) -> ERResult<Caption> {
    if r.is_null() {
        return Ok(Caption {
            short: None,
            long: None,
            source_info: default_si(),
        });
    }
    let lst = as_list(r)?;
    let short = match field(&lst, "short") {
        Some(s) if !s.is_null() => Some(inlines_from_r(&s)?),
        _ => None,
    };
    let long_blocks = match field(&lst, "long") {
        Some(l) => blocks_from_r(&l)?,
        None => Vec::new(),
    };
    let long = if long_blocks.is_empty() {
        None
    } else {
        Some(long_blocks)
    };
    Ok(Caption {
        short,
        long,
        source_info: default_si(),
    })
}

fn cell_from_list(list: List) -> ERResult<Cell> {
    let attr = attr_field(&list)?;
    let alignment = alignment_from_str(&str_or_empty(&list, "alignment"));
    let row_span = field(&list, "row_span")
        .and_then(|r| opt_i32(&r))
        .unwrap_or(1) as usize;
    let col_span = field(&list, "col_span")
        .and_then(|r| opt_i32(&r))
        .unwrap_or(1) as usize;
    let content = blocks_from_content_field(&list, "content")?;
    Ok(Cell {
        attr,
        alignment,
        row_span,
        col_span,
        content,
        source_info: default_si(),
        attr_source: AttrSourceInfo::empty(),
    })
}

fn cells_from_field(list: &List, name: &str) -> ERResult<Vec<Cell>> {
    match field(list, name) {
        Some(r) => items_from_r(&r)?
            .into_iter()
            .map(cell_from_list)
            .collect(),
        None => Ok(Vec::new()),
    }
}

fn row_from_list(list: List) -> ERResult<Row> {
    let attr = attr_field(&list)?;
    let cells = cells_from_field(&list, "cells")?;
    Ok(Row {
        attr,
        cells,
        source_info: default_si(),
        attr_source: AttrSourceInfo::empty(),
    })
}

fn rows_from_field(list: &List, name: &str) -> ERResult<Vec<Row>> {
    match field(list, name) {
        Some(r) => items_from_r(&r)?
            .into_iter()
            .map(row_from_list)
            .collect(),
        None => Ok(Vec::new()),
    }
}

fn table_head_from_r(r: &Robj) -> ERResult<TableHead> {
    if r.is_null() {
        return Ok(TableHead {
            attr: empty_attr(),
            rows: Vec::new(),
            source_info: default_si(),
            attr_source: AttrSourceInfo::empty(),
        });
    }
    let lst = as_list(r)?;
    Ok(TableHead {
        attr: attr_field(&lst)?,
        rows: rows_from_field(&lst, "rows")?,
        source_info: default_si(),
        attr_source: AttrSourceInfo::empty(),
    })
}

fn table_body_from_list(list: List) -> ERResult<TableBody> {
    let attr = attr_field(&list)?;
    let rowhead_columns = field(&list, "row_head_columns")
        .and_then(|r| opt_i32(&r))
        .unwrap_or(0) as usize;
    let head = rows_from_field(&list, "head_rows")?;
    let body = rows_from_field(&list, "body_rows")?;
    Ok(TableBody {
        attr,
        rowhead_columns,
        head,
        body,
        source_info: default_si(),
        attr_source: AttrSourceInfo::empty(),
    })
}

fn table_foot_from_r(r: &Robj) -> ERResult<TableFoot> {
    if r.is_null() {
        return Ok(TableFoot {
            attr: empty_attr(),
            rows: Vec::new(),
            source_info: default_si(),
            attr_source: AttrSourceInfo::empty(),
        });
    }
    let lst = as_list(r)?;
    Ok(TableFoot {
        attr: attr_field(&lst)?,
        rows: rows_from_field(&lst, "rows")?,
        source_info: default_si(),
        attr_source: AttrSourceInfo::empty(),
    })
}

fn table_from_list(list: List) -> ERResult<Table> {
    let attr = attr_field(&list)?;
    let caption = match field(&list, "caption") {
        Some(c) => caption_from_r(&c)?,
        None => Caption {
            short: None,
            long: None,
            source_info: default_si(),
        },
    };
    let colspec = match field(&list, "colspec") {
        Some(cs) => items_from_r(&cs)?
            .into_iter()
            .map(|item| colspec_from_r(&item.into()))
            .collect::<ERResult<Vec<_>>>()?,
        None => Vec::new(),
    };
    let head = match field(&list, "head") {
        Some(h) => table_head_from_r(&h)?,
        None => table_head_from_r(&Robj::from(NULL))?,
    };
    let bodies = match field(&list, "bodies") {
        Some(b) => items_from_r(&b)?
            .into_iter()
            .map(table_body_from_list)
            .collect::<ERResult<Vec<_>>>()?,
        None => Vec::new(),
    };
    let foot = match field(&list, "foot") {
        Some(f) => table_foot_from_r(&f)?,
        None => table_foot_from_r(&Robj::from(NULL))?,
    };
    Ok(Table {
        attr,
        caption,
        colspec,
        head,
        bodies,
        foot,
        source_info: default_si(),
        attr_source: AttrSourceInfo::empty(),
    })
}

fn citation_from_list(list: List) -> ERResult<Citation> {
    let id = str_or_empty(&list, "id");
    let mode = match str_or_empty(&list, "mode").as_str() {
        "AuthorInText" => CitationMode::AuthorInText,
        "SuppressAuthor" => CitationMode::SuppressAuthor,
        _ => CitationMode::NormalCitation,
    };
    let prefix = inlines_from_content_field(&list, "prefix")?;
    let suffix = inlines_from_content_field(&list, "suffix")?;
    let note_num = field(&list, "note_num")
        .and_then(|r| opt_i32(&r))
        .unwrap_or(0) as usize;
    let hash = field(&list, "hash")
        .and_then(|r| opt_i32(&r))
        .unwrap_or(0) as usize;
    Ok(Citation {
        id,
        prefix,
        suffix,
        mode,
        note_num,
        hash,
        id_source: None,
    })
}

fn shortcode_arg_from_r(r: &Robj) -> ERResult<ShortcodeArg> {
    let lst = as_list(r)?;
    let kind = need_str(&lst, "kind")?;
    let value = field(&lst, "value")
        .ok_or_else(|| Error::Other(format!("shortcode arg '{}' missing 'value'", kind)))?;
    Ok(match kind.as_str() {
        "string" => ShortcodeArg::String(opt_str(&value).ok_or_else(|| {
            Error::Other("shortcode arg 'string' value not a string".into())
        })?),
        "number" => ShortcodeArg::Number(opt_f64(&value).ok_or_else(|| {
            Error::Other("shortcode arg 'number' value not numeric".into())
        })?),
        "boolean" => ShortcodeArg::Boolean(opt_bool(&value).ok_or_else(|| {
            Error::Other("shortcode arg 'boolean' value not boolean".into())
        })?),
        "shortcode" => {
            let inner = as_list(&value)?;
            ShortcodeArg::Shortcode(shortcode_from_list(inner)?)
        }
        "kv_group" => {
            let items = items_from_r(&value)?;
            let mut map: HashMap<String, ShortcodeArg> = HashMap::new();
            for item in items {
                let k = need_str(&item, "key")?;
                let v_r = field(&item, "value").ok_or_else(|| {
                    Error::Other("shortcode kv missing 'value'".into())
                })?;
                map.insert(k, shortcode_arg_from_r(&v_r)?);
            }
            ShortcodeArg::KeyValue(map)
        }
        other => {
            return Err(Error::Other(format!(
                "unknown shortcode arg kind '{}'",
                other
            )));
        }
    })
}

fn shortcode_from_list(list: List) -> ERResult<Shortcode> {
    let is_escaped = field(&list, "is_escaped")
        .and_then(|r| opt_bool(&r))
        .unwrap_or(false);
    let name = need_str(&list, "name")?;
    let positional_args = match field(&list, "positional_args") {
        Some(r) => {
            let items = items_from_r(&r)?;
            let mut out: Vec<ShortcodeArg> = Vec::with_capacity(items.len());
            for item in items {
                let as_robj: Robj = item.into();
                out.push(shortcode_arg_from_r(&as_robj)?);
            }
            out
        }
        None => Vec::new(),
    };
    let mut keyword_args: LinkedHashMap<String, ShortcodeArg> = LinkedHashMap::new();
    if let Some(r) = field(&list, "keyword_args") {
        let items = items_from_r(&r)?;
        for item in items {
            let k = need_str(&item, "key")?;
            let v_r = field(&item, "value").ok_or_else(|| {
                Error::Other("shortcode keyword_arg missing 'value'".into())
            })?;
            keyword_args.insert(k, shortcode_arg_from_r(&v_r)?);
        }
    }
    Ok(Shortcode {
        is_escaped,
        name,
        positional_args,
        keyword_args,
        source_info: default_si(),
    })
}

fn inline_from_list(list: List) -> ERResult<Inline> {
    let tag = need_tag(&list)?;
    let si = default_si();
    let asi = || AttrSourceInfo::empty();
    let tsi = || TargetSourceInfo::empty();
    Ok(match tag.as_str() {
        "Str" => Inline::Str(Str {
            text: need_str(&list, "text")?,
            source_info: si,
        }),
        "Space" => Inline::Space(Space { source_info: si }),
        "SoftBreak" => Inline::SoftBreak(SoftBreak { source_info: si }),
        "LineBreak" => Inline::LineBreak(LineBreak { source_info: si }),
        "Emph" => Inline::Emph(Emph {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Underline" => Inline::Underline(Underline {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Strong" => Inline::Strong(Strong {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Strikeout" => Inline::Strikeout(Strikeout {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Superscript" => Inline::Superscript(Superscript {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Subscript" => Inline::Subscript(Subscript {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "SmallCaps" => Inline::SmallCaps(SmallCaps {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Code" => Inline::Code(Code {
            attr: attr_field(&list)?,
            text: need_str(&list, "text")?,
            source_info: si,
            attr_source: asi(),
        }),
        "Math" => {
            let math_type = match str_or_empty(&list, "math_type").as_str() {
                "display" => MathType::DisplayMath,
                _ => MathType::InlineMath,
            };
            Inline::Math(Math {
                math_type,
                text: need_str(&list, "text")?,
                source_info: si,
            })
        }
        "RawInline" => Inline::RawInline(RawInline {
            format: need_str(&list, "format")?,
            text: need_str(&list, "text")?,
            source_info: si,
        }),
        "Quoted" => {
            let quote_type = match str_or_empty(&list, "quote_type").as_str() {
                "single" => QuoteType::SingleQuote,
                _ => QuoteType::DoubleQuote,
            };
            Inline::Quoted(Quoted {
                quote_type,
                content: inlines_from_content_field(&list, "content")?,
                source_info: si,
            })
        }
        "Link" => Inline::Link(Link {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            target: (str_or_empty(&list, "url"), str_or_empty(&list, "title")),
            source_info: si,
            attr_source: asi(),
            target_source: tsi(),
        }),
        "Image" => Inline::Image(Image {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            target: (str_or_empty(&list, "url"), str_or_empty(&list, "title")),
            source_info: si,
            attr_source: asi(),
            target_source: tsi(),
        }),
        "Note" => Inline::Note(Note {
            content: blocks_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Span" => Inline::Span(Span {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "Cite" => {
            let citations_r = field(&list, "citations").unwrap_or(NULL.into_robj());
            let citation_lists = items_from_r(&citations_r)?;
            let citations: ERResult<Vec<Citation>> =
                citation_lists.into_iter().map(citation_from_list).collect();
            Inline::Cite(Cite {
                citations: citations?,
                content: inlines_from_content_field(&list, "content")?,
                source_info: si,
            })
        }
        "NoteReference" => Inline::NoteReference(NoteReference {
            id: need_str(&list, "id")?,
            source_info: si,
        }),
        "AttrInline" => Inline::Attr(InlineAttr::new(attr_field(&list)?, asi(), si)),
        "Insert" => Inline::Insert(Insert {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "Delete" => Inline::Delete(Delete {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "Highlight" => Inline::Highlight(Highlight {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "EditComment" => Inline::EditComment(EditComment {
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "Shortcode" => Inline::Shortcode(shortcode_from_list(list)?),
        "CustomInline" => {
            return Err(Error::Other(format!(
                "inline tag '{}' is not yet supported by the R -> Rust converter",
                tag
            )));
        }
        other => {
            return Err(Error::Other(format!("unknown inline tag '{}'", other)));
        }
    })
}

fn list_number_style(s: &str) -> ListNumberStyle {
    match s {
        "Example" => ListNumberStyle::Example,
        "Decimal" => ListNumberStyle::Decimal,
        "LowerRoman" => ListNumberStyle::LowerRoman,
        "UpperRoman" => ListNumberStyle::UpperRoman,
        "LowerAlpha" => ListNumberStyle::LowerAlpha,
        "UpperAlpha" => ListNumberStyle::UpperAlpha,
        _ => ListNumberStyle::Default,
    }
}

fn list_number_delim(s: &str) -> ListNumberDelim {
    match s {
        "Period" => ListNumberDelim::Period,
        "OneParen" => ListNumberDelim::OneParen,
        "TwoParens" => ListNumberDelim::TwoParens,
        _ => ListNumberDelim::Default,
    }
}

fn block_from_list(list: List) -> ERResult<Block> {
    let tag = need_tag(&list)?;
    let si = default_si();
    let asi = || AttrSourceInfo::empty();
    Ok(match tag.as_str() {
        "Plain" => Block::Plain(Plain {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Paragraph" => Block::Paragraph(Paragraph {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "LineBlock" => {
            let line_lists = field(&list, "content")
                .map(|r| items_from_r(&r))
                .transpose()?
                .unwrap_or_default();
            let content: ERResult<Vec<Vec<Inline>>> = line_lists
                .into_iter()
                .map(|l| {
                    let as_robj: Robj = l.into();
                    inlines_from_r(&as_robj)
                })
                .collect();
            Block::LineBlock(LineBlock {
                content: content?,
                source_info: si,
            })
        }
        "CodeBlock" => Block::CodeBlock(CodeBlock {
            attr: attr_field(&list)?,
            text: need_str(&list, "text")?,
            source_info: si,
            attr_source: asi(),
        }),
        "RawBlock" => Block::RawBlock(RawBlock {
            format: need_str(&list, "format")?,
            text: need_str(&list, "text")?,
            source_info: si,
        }),
        "BlockQuote" => Block::BlockQuote(BlockQuote {
            content: blocks_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "OrderedList" => {
            let start = need_i32(&list, "start")? as usize;
            let style = list_number_style(&str_or_empty(&list, "style"));
            let delim = list_number_delim(&str_or_empty(&list, "delim"));
            let item_lists = field(&list, "items")
                .map(|r| items_from_r(&r))
                .transpose()?
                .unwrap_or_default();
            let content: ERResult<Vec<Vec<Block>>> = item_lists
                .into_iter()
                .map(|l| {
                    let as_robj: Robj = l.into();
                    blocks_from_r(&as_robj)
                })
                .collect();
            let attr: ListAttributes = (start, style, delim);
            Block::OrderedList(OrderedList {
                attr,
                content: content?,
                source_info: si,
            })
        }
        "BulletList" => {
            let item_lists = field(&list, "items")
                .map(|r| items_from_r(&r))
                .transpose()?
                .unwrap_or_default();
            let content: ERResult<Vec<Vec<Block>>> = item_lists
                .into_iter()
                .map(|l| {
                    let as_robj: Robj = l.into();
                    blocks_from_r(&as_robj)
                })
                .collect();
            Block::BulletList(BulletList {
                content: content?,
                source_info: si,
            })
        }
        "DefinitionList" => {
            let item_lists = field(&list, "items")
                .map(|r| items_from_r(&r))
                .transpose()?
                .unwrap_or_default();
            let mut content: Vec<(Vec<Inline>, Vec<Vec<Block>>)> =
                Vec::with_capacity(item_lists.len());
            for item in item_lists {
                let term = inlines_from_content_field(&item, "term")?;
                let def_lists = field(&item, "defs")
                    .map(|r| items_from_r(&r))
                    .transpose()?
                    .unwrap_or_default();
                let defs: ERResult<Vec<Vec<Block>>> = def_lists
                    .into_iter()
                    .map(|l| {
                        let as_robj: Robj = l.into();
                        blocks_from_r(&as_robj)
                    })
                    .collect();
                content.push((term, defs?));
            }
            Block::DefinitionList(DefinitionList {
                content,
                source_info: si,
            })
        }
        "Header" => Block::Header(Header {
            level: need_i32(&list, "level")? as usize,
            attr: attr_field(&list)?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "HorizontalRule" => Block::HorizontalRule(HorizontalRule { source_info: si }),
        "Figure" => {
            let caption_blocks = blocks_from_content_field(&list, "caption")?;
            Block::Figure(Figure {
                attr: attr_field(&list)?,
                caption: Caption {
                    short: None,
                    long: Some(caption_blocks),
                    source_info: default_si(),
                },
                content: blocks_from_content_field(&list, "content")?,
                source_info: si,
                attr_source: asi(),
            })
        }
        "Div" => Block::Div(Div {
            attr: attr_field(&list)?,
            content: blocks_from_content_field(&list, "content")?,
            source_info: si,
            attr_source: asi(),
        }),
        "NoteDefinitionPara" => Block::NoteDefinitionPara(NoteDefinitionPara {
            id: need_str(&list, "id")?,
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "NoteDefinitionFencedBlock" => {
            Block::NoteDefinitionFencedBlock(NoteDefinitionFencedBlock {
                id: need_str(&list, "id")?,
                content: blocks_from_content_field(&list, "content")?,
                source_info: si,
            })
        }
        "CaptionBlock" => Block::CaptionBlock(CaptionBlock {
            content: inlines_from_content_field(&list, "content")?,
            source_info: si,
        }),
        "Table" => Block::Table(table_from_list(list)?),
        "BlockMetadata" | "CustomBlock" => {
            return Err(Error::Other(format!(
                "block tag '{}' is not yet supported by the R -> Rust converter",
                tag
            )));
        }
        other => {
            return Err(Error::Other(format!("unknown block tag '{}'", other)));
        }
    })
}

fn config_value_from_r(r: &Robj) -> ERResult<ConfigValue> {
    let lst = as_list(r)?;
    let kind = need_str(&lst, "kind")?;
    let si = default_si();
    Ok(match kind.as_str() {
        "map" => {
            let keys = field(&lst, "keys").map(|x| str_vec(&x)).unwrap_or_default();
            let value_objs: Vec<Robj> = match field(&lst, "values") {
                Some(v) if !v.is_null() => as_list(&v)?.iter().map(|(_, val)| val).collect(),
                _ => Vec::new(),
            };
            if keys.len() != value_objs.len() {
                return Err(Error::Other(format!(
                    "meta map: {} keys but {} values",
                    keys.len(),
                    value_objs.len()
                )));
            }
            let mut entries = Vec::with_capacity(keys.len());
            for (k, vobj) in keys.into_iter().zip(value_objs.iter()) {
                entries.push(ConfigMapEntry {
                    key: k,
                    key_source: default_si(),
                    value: config_value_from_r(vobj)?,
                });
            }
            ConfigValue::new_map(entries, si)
        }
        "list" => {
            let items: Vec<Robj> = match field(&lst, "value") {
                Some(v) if !v.is_null() => as_list(&v)?.iter().map(|(_, val)| val).collect(),
                _ => Vec::new(),
            };
            let mut cvs = Vec::with_capacity(items.len());
            for it in items.iter() {
                cvs.push(config_value_from_r(it)?);
            }
            ConfigValue::new_array(cvs, si)
        }
        "string" => ConfigValue::new_string(need_str(&lst, "value")?, si),
        "path" => ConfigValue::new_path(need_str(&lst, "value")?, si),
        "glob" => ConfigValue::new_glob(need_str(&lst, "value")?, si),
        "expr" => ConfigValue::new_expr(need_str(&lst, "value")?, si),
        "bool" => ConfigValue::new_bool(need_bool(&lst, "value")?, si),
        "null" => ConfigValue::null(si),
        "int" => {
            let n = need_f64(&lst, "value")? as i64;
            let value: ConfigValueKind = serde_json::from_value(serde_json::json!({ "Scalar": n }))
                .map_err(|e| Error::Other(format!("meta int: {}", e)))?;
            ConfigValue {
                value,
                source_info: si,
                merge_op: MergeOp::Concat,
            }
        }
        "real" => {
            let f = need_f64(&lst, "value")?;
            let num = serde_json::Number::from_f64(f)
                .ok_or_else(|| Error::Other("meta real: non-finite value".into()))?;
            let value: ConfigValueKind =
                serde_json::from_value(serde_json::json!({ "Scalar": num }))
                    .map_err(|e| Error::Other(format!("meta real: {}", e)))?;
            ConfigValue {
                value,
                source_info: si,
                merge_op: MergeOp::Concat,
            }
        }
        "inlines" => ConfigValue::new_inlines(inlines_from_content_field(&lst, "value")?, si),
        "blocks" => ConfigValue::new_blocks(blocks_from_content_field(&lst, "value")?, si),
        other => {
            return Err(Error::Other(format!("unknown meta kind '{}'", other)));
        }
    })
}

pub fn pandoc_from_r(r: &Robj) -> ERResult<Pandoc> {
    let lst = as_list(r)?;
    let tag = need_tag(&lst)?;
    if tag != "Pandoc" {
        return Err(Error::Other(format!(
            "expected a 'Pandoc' tagged list, got '{}'",
            tag
        )));
    }
    let meta = match field(&lst, "meta") {
        Some(m) if !m.is_null() => config_value_from_r(&m)?,
        _ => ConfigValue::default(),
    };
    let blocks = blocks_from_content_field(&lst, "blocks")?;
    Ok(Pandoc { meta, blocks })
}
