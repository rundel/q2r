//! Paired string <-> enum conversions for the small Pandoc enums, shared by
//! the to-R (`pd_ast_to_r`) and from-R (`r_to_pd_ast`) converters so the two
//! directions cannot drift, and so the R-facing strings live in one place.

use pampa::pandoc::{
    Alignment, CitationMode, ListNumberDelim, ListNumberStyle, MathType, QuoteType,
};

pub fn alignment_to_str(a: &Alignment) -> &'static str {
    match a {
        Alignment::Left => "Left",
        Alignment::Center => "Center",
        Alignment::Right => "Right",
        Alignment::Default => "Default",
    }
}

pub fn alignment_from_str(s: &str) -> Alignment {
    match s {
        "Left" => Alignment::Left,
        "Right" => Alignment::Right,
        "Center" => Alignment::Center,
        _ => Alignment::Default,
    }
}

pub fn citation_mode_to_str(m: &CitationMode) -> &'static str {
    match m {
        CitationMode::AuthorInText => "AuthorInText",
        CitationMode::SuppressAuthor => "SuppressAuthor",
        CitationMode::NormalCitation => "NormalCitation",
    }
}

pub fn citation_mode_from_str(s: &str) -> CitationMode {
    match s {
        "AuthorInText" => CitationMode::AuthorInText,
        "SuppressAuthor" => CitationMode::SuppressAuthor,
        _ => CitationMode::NormalCitation,
    }
}

pub fn math_type_to_str(m: &MathType) -> &'static str {
    match m {
        MathType::InlineMath => "inline",
        MathType::DisplayMath => "display",
    }
}

pub fn math_type_from_str(s: &str) -> MathType {
    match s {
        "display" => MathType::DisplayMath,
        _ => MathType::InlineMath,
    }
}

pub fn quote_type_to_str(q: &QuoteType) -> &'static str {
    match q {
        QuoteType::SingleQuote => "single",
        QuoteType::DoubleQuote => "double",
    }
}

pub fn quote_type_from_str(s: &str) -> QuoteType {
    match s {
        "single" => QuoteType::SingleQuote,
        _ => QuoteType::DoubleQuote,
    }
}

pub fn list_number_style_to_str(s: &ListNumberStyle) -> &'static str {
    match s {
        ListNumberStyle::Default => "Default",
        ListNumberStyle::Example => "Example",
        ListNumberStyle::Decimal => "Decimal",
        ListNumberStyle::LowerRoman => "LowerRoman",
        ListNumberStyle::UpperRoman => "UpperRoman",
        ListNumberStyle::LowerAlpha => "LowerAlpha",
        ListNumberStyle::UpperAlpha => "UpperAlpha",
    }
}

pub fn list_number_style_from_str(s: &str) -> ListNumberStyle {
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

pub fn list_number_delim_to_str(d: &ListNumberDelim) -> &'static str {
    match d {
        ListNumberDelim::Default => "Default",
        ListNumberDelim::Period => "Period",
        ListNumberDelim::OneParen => "OneParen",
        ListNumberDelim::TwoParens => "TwoParens",
    }
}

pub fn list_number_delim_from_str(s: &str) -> ListNumberDelim {
    match s {
        "Period" => ListNumberDelim::Period,
        "OneParen" => ListNumberDelim::OneParen,
        "TwoParens" => ListNumberDelim::TwoParens,
        _ => ListNumberDelim::Default,
    }
}
