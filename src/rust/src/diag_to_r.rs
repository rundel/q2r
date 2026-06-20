use extendr_api::prelude::*;
use quarto_error_reporting::{
    DetailItem, DetailKind, DiagnosticKind, DiagnosticMessage, MessageContent, TextRenderOptions,
};
use quarto_source_map::{FileId, SourceContext, SourceInfo};

fn kind_str(k: DiagnosticKind) -> &'static str {
    match k {
        DiagnosticKind::Error => "error",
        DiagnosticKind::Warning => "warning",
        DiagnosticKind::Info => "info",
        DiagnosticKind::Note => "note",
    }
}

fn detail_kind_str(k: DetailKind) -> &'static str {
    match k {
        DetailKind::Error => "error",
        DetailKind::Info => "info",
        DetailKind::Note => "note",
        DetailKind::Faded => "faded",
    }
}

fn parse_kind(s: &str) -> DiagnosticKind {
    match s {
        "warning" => DiagnosticKind::Warning,
        "info" => DiagnosticKind::Info,
        "note" => DiagnosticKind::Note,
        _ => DiagnosticKind::Error,
    }
}

fn parse_detail_kind(s: &str) -> DetailKind {
    match s {
        "info" => DetailKind::Info,
        "note" => DetailKind::Note,
        "faded" => DetailKind::Faded,
        _ => DetailKind::Error,
    }
}

fn content_to_r(c: &MessageContent) -> Robj {
    let ty = match c {
        MessageContent::Plain(_) => "plain",
        MessageContent::Markdown(_) => "markdown",
    };
    list!(format = ty, text = c.as_str()).into()
}

fn location_to_r(loc: &SourceInfo, ctx: &SourceContext) -> Robj {
    let len = loc.length();
    let start = loc.map_offset(0, ctx);
    // Fall back to the last in-range byte, then to the start, so a mappable
    // start with an unmappable end keeps a location rather than dropping it
    // (matching pampa's json/diagnostic writers).
    let end = loc
        .map_offset(len, ctx)
        .or_else(|| if len > 0 { loc.map_offset(len - 1, ctx) } else { None })
        .or_else(|| start.clone());

    let file = start
        .as_ref()
        .and_then(|s| ctx.get_file(s.file_id))
        .map(|f| f.path.clone())
        .unwrap_or_default();

    let as_pos = |m: &Option<quarto_source_map::MappedLocation>| -> (Robj, Robj, Robj) {
        match m {
            Some(loc) => (
                (loc.location.offset as i32).into(),
                ((loc.location.row + 1) as i32).into(),
                ((loc.location.column + 1) as i32).into(),
            ),
            None => (
                Robj::from(NA_INTEGER),
                Robj::from(NA_INTEGER),
                Robj::from(NA_INTEGER),
            ),
        }
    };

    let (so, sr, sc) = as_pos(&start);
    let (eo, er, ec) = as_pos(&end);

    list!(
        file = file,
        start_offset = so,
        start_row = sr,
        start_column = sc,
        end_offset = eo,
        end_row = er,
        end_column = ec
    )
    .into()
}

fn opt_location(loc: &Option<SourceInfo>, ctx: &SourceContext) -> Robj {
    match loc {
        Some(l) => location_to_r(l, ctx),
        None => NULL.into(),
    }
}

pub fn diag_to_r(diag: &DiagnosticMessage, ctx: &SourceContext) -> Robj {
    let details: Vec<Robj> = diag
        .details
        .iter()
        .map(|d| {
            list!(
                kind = detail_kind_str(d.kind),
                content = content_to_r(&d.content),
                location = opt_location(&d.location, ctx)
            )
            .into()
        })
        .collect();

    // Hints flatten to bare strings, dropping the Plain/Markdown tag that
    // `problem`/`details` preserve; on reconstruction they all become Markdown.
    // This is deliberate and render-safe - full symmetry is not worth an
    // R-side slot change.
    let hints: Vec<&str> = diag.hints.iter().map(|h| h.as_str()).collect();

    let problem: Robj = match &diag.problem {
        Some(p) => content_to_r(p),
        None => NULL.into(),
    };

    let code: Robj = match &diag.code {
        Some(c) => c.as_str().into(),
        None => NULL.into(),
    };

    list!(
        kind = kind_str(diag.kind),
        code = code,
        title = diag.title.as_str(),
        problem = problem,
        details = List::from_values(details),
        hints = hints,
        location = opt_location(&diag.location, ctx)
    )
    .into()
}

fn list_get(list: &List, name: &str) -> Option<Robj> {
    list.iter()
        .find(|(n, _)| *n == name)
        .map(|(_, v)| v.clone())
}

fn robj_as_list(r: &Robj) -> Option<List> {
    if r.is_null() {
        None
    } else {
        List::try_from(r.clone()).ok()
    }
}

fn opt_str(r: &Robj) -> Option<String> {
    if r.is_null() {
        return None;
    }
    r.as_str().map(|s| s.to_string())
}

fn parse_content(r: &Robj) -> Option<MessageContent> {
    let list = robj_as_list(r)?;
    let format = list_get(&list, "format").and_then(|v| opt_str(&v))?;
    let text = list_get(&list, "text").and_then(|v| opt_str(&v))?;
    match format.as_str() {
        "plain" => Some(MessageContent::Plain(text)),
        _ => Some(MessageContent::Markdown(text)),
    }
}

fn parse_location(r: &Robj) -> Option<SourceInfo> {
    let list = robj_as_list(r)?;
    let start = list_get(&list, "start_offset").and_then(|v| v.as_integer())?;
    let end = list_get(&list, "end_offset").and_then(|v| v.as_integer())?;
    Some(SourceInfo::Original {
        file_id: FileId(0),
        start_offset: start.max(0) as usize,
        end_offset: end.max(0) as usize,
    })
}

fn parse_detail(r: &Robj) -> Option<DetailItem> {
    let list = robj_as_list(r)?;
    let kind = list_get(&list, "kind")
        .and_then(|v| opt_str(&v))
        .map(|s| parse_detail_kind(&s))
        .unwrap_or(DetailKind::Error);
    let content = list_get(&list, "content")
        .and_then(|v| parse_content(&v))
        .unwrap_or_else(|| MessageContent::Plain(String::new()));
    let location = list_get(&list, "location").and_then(|v| parse_location(&v));
    Some(DetailItem {
        kind,
        content,
        location,
    })
}

fn reconstruct_diagnostic(
    kind: &str,
    code: Robj,
    title: &str,
    problem: Robj,
    details: Robj,
    hints: Robj,
    location: Robj,
) -> DiagnosticMessage {
    let details_vec: Vec<DetailItem> = robj_as_list(&details)
        .map(|l| l.iter().filter_map(|(_, v)| parse_detail(&v)).collect())
        .unwrap_or_default();

    let hints_vec: Vec<MessageContent> = if hints.is_null() {
        Vec::new()
    } else {
        hints
            .as_string_vector()
            .unwrap_or_default()
            .into_iter()
            .map(MessageContent::Markdown)
            .collect()
    };

    DiagnosticMessage {
        code: opt_str(&code),
        title: title.to_string(),
        kind: parse_kind(kind),
        problem: parse_content(&problem),
        details: details_vec,
        hints: hints_vec,
        location: parse_location(&location),
    }
}

pub fn format_diag(
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
    let diag = reconstruct_diagnostic(kind, code, title, problem, details, hints, location);

    let mut ctx = SourceContext::new();
    // Pad to a trailing newline (as the parser did) so an offset at the
    // appended newline still resolves and the caret renders at format time.
    let padded = if source_text.ends_with('\n') {
        source_text.to_string()
    } else {
        format!("{source_text}\n")
    };
    ctx.add_file(source_filename.to_string(), Some(padded));

    let opts = TextRenderOptions {
        enable_hyperlinks: hyperlinks,
    };
    diag.to_text_with_options(Some(&ctx), &opts)
}
