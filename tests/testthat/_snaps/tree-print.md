# print.pandoc renders a representative document (unicode)

    Code
      print(pd)
    Output
      pandoc
      ├─meta: map
      ├─header level=1 (#sec-intro .intro)
      │ ├─str "Heading"
      │ ├─space
      │ └─str "1"
      ├─paragraph
      │ ├─str "Plain"
      │ ├─space
      │ ├─str "text"
      │ ├─space
      │ ├─str "with"
      │ ├─space
      │ ├─emph
      │ │ └─str "emphasis"
      │ ├─str ","
      │ ├─space
      │ ├─strong
      │ │ └─str "strong"
      │ ├─str ","
      │ ├─space
      │ ├─str "and"
      │ ├─space
      │ ├─code "inline code"
      │ ├─str "."
      │ ├─soft_break
      │ ├─str "See"
      │ ├─space
      │ ├─link url="https://example.com" title="tip"
      │ │ ├─str "a"
      │ │ ├─space
      │ │ └─str "link"
      │ └─str "."
      ├─header level=2 (#heading-2)
      │ ├─str "Heading"
      │ ├─space
      │ └─str "2"
      ├─block_quote
      │ └─paragraph
      │   ├─str "A"
      │   ├─space
      │   ├─str "block"
      │   ├─space
      │   ├─str "quote."
      │   ├─soft_break
      │   ├─str "Second"
      │   ├─space
      │   └─str "line."
      ├─bullet_list
      │ ├─plain
      │ │ ├─str "bullet"
      │ │ ├─space
      │ │ └─str "one"
      │ ├─plain
      │ │ ├─str "bullet"
      │ │ ├─space
      │ │ └─str "two"
      │ └─bullet_list
      │   └─plain
      │     └─str "nested"
      ├─ordered_list start=1 style=Decimal delim=Period
      │ ├─plain
      │ │ └─str "ordered"
      │ └─plain
      │   └─str "second"
      ├─code_block "x = 1" (.{r})
      ├─paragraph
      │ ├─str "Inline"
      │ ├─space
      │ ├─str "math"
      │ ├─space
      │ ├─math type=inline "a + b"
      │ ├─space
      │ ├─str "and"
      │ ├─space
      │ ├─str "display"
      │ ├─space
      │ └─str "math:"
      ├─paragraph
      │ └─math type=display "\n\\sum_i x_i\n"
      ├─div (.callout-note)
      │ └─paragraph
      │   ├─str "A"
      │   ├─space
      │   ├─str "note"
      │   ├─space
      │   └─str "div."
      └─figure (#fig-img)
        ├─caption
        │ └─long:
        │   └─plain
        │     ├─str "alt"
        │     ├─space
        │     └─str "text"
        └─content:
          └─plain
            └─image url="img.png"
              ├─str "alt"
              ├─space
              └─str "text"

# print.pandoc renders a representative document (ascii)

    Code
      print(pd)
    Output
      pandoc
      +-meta: map
      +-header level=1 (#sec-intro .intro)
      | +-str "Heading"
      | +-space
      | \-str "1"
      +-paragraph
      | +-str "Plain"
      | +-space
      | +-str "text"
      | +-space
      | +-str "with"
      | +-space
      | +-emph
      | | \-str "emphasis"
      | +-str ","
      | +-space
      | +-strong
      | | \-str "strong"
      | +-str ","
      | +-space
      | +-str "and"
      | +-space
      | +-code "inline code"
      | +-str "."
      | +-soft_break
      | +-str "See"
      | +-space
      | +-link url="https://example.com" title="tip"
      | | +-str "a"
      | | +-space
      | | \-str "link"
      | \-str "."
      +-header level=2 (#heading-2)
      | +-str "Heading"
      | +-space
      | \-str "2"
      +-block_quote
      | \-paragraph
      |   +-str "A"
      |   +-space
      |   +-str "block"
      |   +-space
      |   +-str "quote."
      |   +-soft_break
      |   +-str "Second"
      |   +-space
      |   \-str "line."
      +-bullet_list
      | +-plain
      | | +-str "bullet"
      | | +-space
      | | \-str "one"
      | +-plain
      | | +-str "bullet"
      | | +-space
      | | \-str "two"
      | \-bullet_list
      |   \-plain
      |     \-str "nested"
      +-ordered_list start=1 style=Decimal delim=Period
      | +-plain
      | | \-str "ordered"
      | \-plain
      |   \-str "second"
      +-code_block "x = 1" (.{r})
      +-paragraph
      | +-str "Inline"
      | +-space
      | +-str "math"
      | +-space
      | +-math type=inline "a + b"
      | +-space
      | +-str "and"
      | +-space
      | +-str "display"
      | +-space
      | \-str "math:"
      +-paragraph
      | \-math type=display "\n\\sum_i x_i\n"
      +-div (.callout-note)
      | \-paragraph
      |   +-str "A"
      |   +-space
      |   +-str "note"
      |   +-space
      |   \-str "div."
      \-figure (#fig-img)
        +-caption
        | \-long:
        |   \-plain
        |     +-str "alt"
        |     +-space
        |     \-str "text"
        \-content:
          \-plain
            \-image url="img.png"
              +-str "alt"
              +-space
              \-str "text"

# print.ts_tree renders a representative document (unicode)

    Code
      print(ts)
    Output
      ts_tree language=qmd
      └─document
        ├─metadata "---\ntitle: Demo\nauthor: A\n---\n"
        ├─section "\n"
        └─section
          ├─atx_heading
          │ ├─atx_h1_marker "#"
          │ ├─pandoc_str "Heading"
          │ ├─pandoc_space " "
          │ ├─pandoc_str "1"
          │ ├─pandoc_space " "
          │ └─attribute_specifier
          │   ├─"{" "{"
          │   ├─commonmark_specifier
          │   │ ├─attribute_id "#sec-intro"
          │   │ └─attribute_class ".intro"
          │   └─"}" "}"
          ├─pandoc_paragraph
          │ ├─pandoc_str "Plain"
          │ ├─pandoc_space " "
          │ ├─pandoc_str "text"
          │ ├─pandoc_space " "
          │ ├─pandoc_str "with"
          │ ├─pandoc_emph
          │ │ ├─emphasis_delimiter " *"
          │ │ ├─pandoc_str "emphasis"
          │ │ └─emphasis_delimiter "*"
          │ ├─pandoc_str ","
          │ ├─pandoc_strong
          │ │ ├─strong_emphasis_delimiter " **"
          │ │ ├─pandoc_str "strong"
          │ │ └─strong_emphasis_delimiter "**"
          │ ├─pandoc_str ","
          │ ├─pandoc_space " "
          │ ├─pandoc_str "and"
          │ ├─pandoc_code_span
          │ │ ├─code_span_delimiter " `"
          │ │ ├─content "inline code"
          │ │ └─code_span_delimiter "`"
          │ ├─pandoc_str "."
          │ ├─pandoc_soft_break "\n"
          │ ├─pandoc_str "See"
          │ ├─pandoc_space " "
          │ ├─pandoc_span
          │ │ ├─"[" "["
          │ │ ├─content
          │ │ │ ├─pandoc_str "a"
          │ │ │ ├─pandoc_space " "
          │ │ │ └─pandoc_str "link"
          │ │ └─target
          │ │   ├─url "https://example.com"
          │ │   ├─title ""tip""
          │ │   └─")" ")"
          │ └─pandoc_str "."
          └─section
            ├─atx_heading
            │ ├─atx_h2_marker "##"
            │ ├─pandoc_str "Heading"
            │ ├─pandoc_space " "
            │ └─pandoc_str "2"
            ├─pandoc_block_quote
            │ ├─block_quote_marker "> "
            │ └─pandoc_paragraph
            │   ├─pandoc_str "A"
            │   ├─pandoc_space " "
            │   ├─pandoc_str "block"
            │   ├─pandoc_space " "
            │   ├─pandoc_str "quote."
            │   ├─pandoc_soft_break "\n> "
            │   ├─pandoc_str "Second"
            │   ├─pandoc_space " "
            │   └─pandoc_str "line."
            ├─pandoc_list
            │ ├─list_item
            │ │ ├─list_marker_minus "- "
            │ │ └─pandoc_paragraph
            │ │   ├─pandoc_str "bullet"
            │ │   ├─pandoc_space " "
            │ │   └─pandoc_str "one"
            │ └─list_item
            │   ├─list_marker_minus "- "
            │   ├─pandoc_paragraph
            │   │ ├─pandoc_str "bullet"
            │   │ ├─pandoc_space " "
            │   │ ├─pandoc_str "two"
            │   │ └─block_continuation "  "
            │   └─pandoc_list
            │     └─list_item
            │       ├─list_marker_minus "- "
            │       └─pandoc_paragraph
            │         └─pandoc_str "nested"
            ├─pandoc_list
            │ ├─list_item
            │ │ ├─list_marker_dot "1. "
            │ │ └─pandoc_paragraph
            │ │   └─pandoc_str "ordered"
            │ └─list_item
            │   ├─list_marker_dot "2. "
            │   └─pandoc_paragraph
            │     └─pandoc_str "second"
            ├─pandoc_code_block
            │ ├─fenced_code_block_delimiter "```"
            │ ├─attribute_specifier
            │ │ ├─"{" "{"
            │ │ ├─language_specifier "r"
            │ │ └─"}" "}"
            │ ├─block_continuation
            │ ├─code_fence_content "x = 1\n"
            │ │ └─block_continuation
            │ └─fenced_code_block_delimiter "```"
            ├─pandoc_paragraph
            │ ├─pandoc_str "Inline"
            │ ├─pandoc_space " "
            │ ├─pandoc_str "math"
            │ ├─pandoc_space " "
            │ ├─pandoc_math "$a + b$"
            │ │ ├─"$" "$"
            │ │ └─"$" "$"
            │ ├─pandoc_space " "
            │ ├─pandoc_str "and"
            │ ├─pandoc_space " "
            │ ├─pandoc_str "display"
            │ ├─pandoc_space " "
            │ ├─pandoc_str "math"
            │ └─pandoc_str ":"
            ├─pandoc_paragraph
            │ └─pandoc_display_math "$$\n\\sum_i x_i\n$$"
            │   ├─"$$" "$$"
            │   └─"$$" "$$"
            ├─pandoc_div
            │ ├─attribute_specifier
            │ │ ├─"{" "{"
            │ │ ├─commonmark_specifier
            │ │ │ └─attribute_class ".callout-note"
            │ │ └─"}" "}"
            │ ├─block_continuation
            │ └─pandoc_paragraph
            │   ├─pandoc_str "A"
            │   ├─pandoc_space " "
            │   ├─pandoc_str "note"
            │   ├─pandoc_space " "
            │   ├─pandoc_str "div."
            │   └─block_continuation
            └─pandoc_paragraph
              └─pandoc_image
                ├─"![" "!["
                ├─content
                │ ├─pandoc_str "alt"
                │ ├─pandoc_space " "
                │ └─pandoc_str "text"
                ├─target
                │ ├─url "img.png"
                │ └─")" ")"
                └─attribute_specifier
                  ├─"{" "{"
                  ├─commonmark_specifier
                  │ └─attribute_id "#fig-img"
                  └─"}" "}"

# print.ts_tree renders a representative document (ascii)

    Code
      print(ts)
    Output
      ts_tree language=qmd
      \-document
        +-metadata "---\ntitle: Demo\nauthor: A\n---\n"
        +-section "\n"
        \-section
          +-atx_heading
          | +-atx_h1_marker "#"
          | +-pandoc_str "Heading"
          | +-pandoc_space " "
          | +-pandoc_str "1"
          | +-pandoc_space " "
          | \-attribute_specifier
          |   +-"{" "{"
          |   +-commonmark_specifier
          |   | +-attribute_id "#sec-intro"
          |   | \-attribute_class ".intro"
          |   \-"}" "}"
          +-pandoc_paragraph
          | +-pandoc_str "Plain"
          | +-pandoc_space " "
          | +-pandoc_str "text"
          | +-pandoc_space " "
          | +-pandoc_str "with"
          | +-pandoc_emph
          | | +-emphasis_delimiter " *"
          | | +-pandoc_str "emphasis"
          | | \-emphasis_delimiter "*"
          | +-pandoc_str ","
          | +-pandoc_strong
          | | +-strong_emphasis_delimiter " **"
          | | +-pandoc_str "strong"
          | | \-strong_emphasis_delimiter "**"
          | +-pandoc_str ","
          | +-pandoc_space " "
          | +-pandoc_str "and"
          | +-pandoc_code_span
          | | +-code_span_delimiter " `"
          | | +-content "inline code"
          | | \-code_span_delimiter "`"
          | +-pandoc_str "."
          | +-pandoc_soft_break "\n"
          | +-pandoc_str "See"
          | +-pandoc_space " "
          | +-pandoc_span
          | | +-"[" "["
          | | +-content
          | | | +-pandoc_str "a"
          | | | +-pandoc_space " "
          | | | \-pandoc_str "link"
          | | \-target
          | |   +-url "https://example.com"
          | |   +-title ""tip""
          | |   \-")" ")"
          | \-pandoc_str "."
          \-section
            +-atx_heading
            | +-atx_h2_marker "##"
            | +-pandoc_str "Heading"
            | +-pandoc_space " "
            | \-pandoc_str "2"
            +-pandoc_block_quote
            | +-block_quote_marker "> "
            | \-pandoc_paragraph
            |   +-pandoc_str "A"
            |   +-pandoc_space " "
            |   +-pandoc_str "block"
            |   +-pandoc_space " "
            |   +-pandoc_str "quote."
            |   +-pandoc_soft_break "\n> "
            |   +-pandoc_str "Second"
            |   +-pandoc_space " "
            |   \-pandoc_str "line."
            +-pandoc_list
            | +-list_item
            | | +-list_marker_minus "- "
            | | \-pandoc_paragraph
            | |   +-pandoc_str "bullet"
            | |   +-pandoc_space " "
            | |   \-pandoc_str "one"
            | \-list_item
            |   +-list_marker_minus "- "
            |   +-pandoc_paragraph
            |   | +-pandoc_str "bullet"
            |   | +-pandoc_space " "
            |   | +-pandoc_str "two"
            |   | \-block_continuation "  "
            |   \-pandoc_list
            |     \-list_item
            |       +-list_marker_minus "- "
            |       \-pandoc_paragraph
            |         \-pandoc_str "nested"
            +-pandoc_list
            | +-list_item
            | | +-list_marker_dot "1. "
            | | \-pandoc_paragraph
            | |   \-pandoc_str "ordered"
            | \-list_item
            |   +-list_marker_dot "2. "
            |   \-pandoc_paragraph
            |     \-pandoc_str "second"
            +-pandoc_code_block
            | +-fenced_code_block_delimiter "```"
            | +-attribute_specifier
            | | +-"{" "{"
            | | +-language_specifier "r"
            | | \-"}" "}"
            | +-block_continuation
            | +-code_fence_content "x = 1\n"
            | | \-block_continuation
            | \-fenced_code_block_delimiter "```"
            +-pandoc_paragraph
            | +-pandoc_str "Inline"
            | +-pandoc_space " "
            | +-pandoc_str "math"
            | +-pandoc_space " "
            | +-pandoc_math "$a + b$"
            | | +-"$" "$"
            | | \-"$" "$"
            | +-pandoc_space " "
            | +-pandoc_str "and"
            | +-pandoc_space " "
            | +-pandoc_str "display"
            | +-pandoc_space " "
            | +-pandoc_str "math"
            | \-pandoc_str ":"
            +-pandoc_paragraph
            | \-pandoc_display_math "$$\n\\sum_i x_i\n$$"
            |   +-"$$" "$$"
            |   \-"$$" "$$"
            +-pandoc_div
            | +-attribute_specifier
            | | +-"{" "{"
            | | +-commonmark_specifier
            | | | \-attribute_class ".callout-note"
            | | \-"}" "}"
            | +-block_continuation
            | \-pandoc_paragraph
            |   +-pandoc_str "A"
            |   +-pandoc_space " "
            |   +-pandoc_str "note"
            |   +-pandoc_space " "
            |   +-pandoc_str "div."
            |   \-block_continuation
            \-pandoc_paragraph
              \-pandoc_image
                +-"![" "!["
                +-content
                | +-pandoc_str "alt"
                | +-pandoc_space " "
                | \-pandoc_str "text"
                +-target
                | +-url "img.png"
                | \-")" ")"
                \-attribute_specifier
                  +-"{" "{"
                  +-commonmark_specifier
                  | \-attribute_id "#fig-img"
                  \-"}" "}"

