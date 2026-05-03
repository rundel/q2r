# q2 issues to file

Each reprex uses the `pampa` CLI (`cargo run --bin pampa --` or a built `pampa` binary on the path).

> **Status note (2026-05-03):** earlier drafts of this file included Issues 4–7,
> covering QMD writer normalization of list markers, YAML scalar quoting, plain-text
> pipe escapes, and code-fence width. Those were only observable as ts_ast equality
> failures in q2r's `pampa_to_qmd(ts_tree)` round-trip suite. After determining that
> pampa's QMD writer operates on the pd_ast (which intentionally drops marker shape,
> fence width, scalar style, etc.), the ts-suite was retired — pandoc-style surface
> normalization is the documented behavior of an AST-based writer, not a bug. The
> remaining issues below produce output that does not re-parse to the same construct
> (writer bugs) or that fails to parse at all (parser bugs).

---

## Issue 8: Executable code-block info-string emitted as invalid `{.{lang} ...}`

**Summary**

A Quarto-style executable code block `{r eval=FALSE}` (no leading dot) is re-emitted as `{.{r} eval="FALSE"}`. The leading `.{` makes the info-string invalid — re-parsing produces a parse error rather than another code block.

**Reprex**

```console
$ printf -- '```{r eval=FALSE}\nx = 1\n```\n' | pampa -t qmd
[Q-2-8 warning about code-block options in header — expected, not the bug]

```{.{r} eval="FALSE"}
x = 1
```
```

**Expected**

For a plain language tag, emit either `{r eval=FALSE}` (preserving the executable-block shape) or `{.r eval="FALSE"}` (with the conventional leading dot). The current `{.{r} ...}` form is neither.

**Pointer**

`write_code_block` info-string emission in `crates/pampa/src/writers/qmd.rs`. The class-token is being wrapped in literal `{}` when it's already a single token, producing the doubled braces.

---

## Issue 9: Table caption containing only attributes is emitted as a bare `:`

**Summary**

A pipe-table caption that is purely an attribute block (e.g., `: {tbl-colwidths="[30,70]"}`) round-trips to a bare `:` line — the attributes are dropped, and the lone `:` is parse-error material on its own.

**Reprex**

```console
$ printf '%s\n' '| A | B |' '|---|---|' '| 1 | 2 |' '' ': {tbl-colwidths="[30,70]"}' | pampa -t qmd
| A   | B   |
| --- | --- |
| 1   | 2   |

:
```

The trailing `:` does not re-parse as a caption (a caption requires either text or attributes).

**Expected**

Preserve the attribute block on the caption line: emit `: {tbl-colwidths="[30,70]"}` (or `: caption-text {attrs}` when both are present). If the AST genuinely has neither text nor attributes, omit the caption line entirely.

**Pointer**

`write_table` / caption emission in `crates/pampa/src/writers/qmd.rs`. The attribute branch is being unconditionally skipped on the no-text path.

---

## Issue 10: QMD writer destroys grid tables on round-trip

**Summary**

A grid table (using `+---+---+` row separators and `|` cell delimiters) is re-emitted with each data row replaced by a paragraph in which every `|` is escaped as `\|`, and the row separators are kept as bare lines with blank lines between them. The result re-parses to a sequence of paragraphs, not a table.

**Reprex**

```console
$ printf '%s\n' '+------+--------+' '| key  | val    |' '+------+--------+' '| a    | hello  |' '+------+--------+' | pampa -t qmd
+------+--------+
\| key \| val \|

+------+--------+
\| a \| hello \|

+------+--------+
```

Even the simplest grid table — no multi-line cells, no header separator — is mangled. Any document using grid tables (common when cells need block content like sub-paragraphs or hard breaks) loses the table entirely on round-trip.

**Expected**

Either (a) preserve the grid-table form when the input was a grid table, or (b) re-emit the table in pipe-table form with cells properly delimited (and pipes inside cell text correctly escaped, but structural pipes not).

**Pointer**

`write_table` in `crates/pampa/src/writers/qmd.rs`. The current path appears to interleave row-separator lines with cell-text lines that have been Str-escaped (so `|` becomes `\|`); it never produces a valid grid- or pipe-table.

---

## Issue 11: tree-sitter-qmd cannot parse fenced code blocks inside grid-table cells

**Summary**

A grid table cell containing a fenced code block (the standard Quarto pattern for showing OS-specific terminal commands side-by-side) fails to parse. Pampa emits a generic "Parse error" pointing at the backticks. Across the quarto-web fixture set this is the dominant cause of generic "Parse error" diagnostics — currently 38 of 568 fixtures emit at least one generic "Parse error" and a substantial fraction of those trace to grid-table cells holding fenced code.

**Reprex**

```console
$ printf '%s\n' '+-----+----------------+' '| OS  | ```bash         |' '|     | echo hi         |' '|     | ```             |' '+-----+----------------+' | pampa -t native
Error: Parse error
   ╭─[ <stdin>:2:9 ]
   │
 2 │ | OS  | ```bash         |
   │         ┬
   │         ╰── unexpected character or token here
───╯
```

The same content as a plain fenced code block (no surrounding grid table) parses fine.

**Expected**

Grid-table cells should accept block-level constructs, including fenced code blocks. This is supported by pandoc and is the canonical Quarto pattern for tabbed/side-by-side OS instructions.

**Pointer**

`crates/tree-sitter-qmd/tree-sitter-markdown/grammar.js` (and the external scanner in `src/scanner.c`). The grid-table cell content rule needs to allow fenced code blocks, or the scanner needs to recognize that backticks inside a multi-line cell should open a fenced span.

---

## Issue 12: tree-sitter-qmd rejects multi-line image-attribute blocks

**Summary**

`![alt](url){...}` accepts attributes on a single line only. When the attribute brace block spans multiple lines (a common formatting choice for many attributes) the parser rejects the second-line content as "unexpected character or token".

**Reprex**

```console
$ printf '%s\n' '![](x.png){' '  .hero' '  fig-align="center"' '}' | pampa -t native
Error: Parse error
   ╭─[ <stdin>:2:3 ]
   │
 2 │   .hero
   │   ──┬──
   │     ╰──── unexpected character or token here
───╯
```

**Expected**

Multi-line attribute blocks should be parsed identically to single-line ones — the `{` opens an attribute scope that closes at the matching `}`, with line breaks treated as whitespace. Pandoc accepts this form.

**Pointer**

The image / inline-attribute rules in `crates/tree-sitter-qmd/tree-sitter-markdown/grammar.js`.

---

## Issue 13: tree-sitter-qmd rejects Unicode/smart quotes inside shortcode arguments

**Summary**

A shortcode argument quoted with Unicode "smart" double quotes (U+201C / U+201D) fails to parse. Auto-correcting editors frequently produce these characters in pasted URLs, so the parse error surfaces in real documents.

**Reprex**

```console
$ printf '{{< video \xe2\x80\x9chttps://example.com\xe2\x80\x9d >}}\n' | pampa -t native
Error: Parse error
   ╭─[ <stdin>:1:11 ]
   │
 1 │ {{< video "https://example.com" >}}
   │           ┬
   │           ╰── unexpected character or token here
───╯
```

(Using ASCII straight quotes parses fine.)

**Expected**

Either accept smart quotes as valid string delimiters (matching what visual editors emit) or surface a typed diagnostic that names the issue and recommends ASCII quotes. The current generic "Parse error" makes the cause hard to spot.

**Pointer**

Shortcode argument tokenization in `crates/tree-sitter-qmd/tree-sitter-markdown/grammar.js` / `src/scanner.c`.

---

## Issue 14: tree-sitter-qmd does not decode HTML numeric entities inside `<pre>` blocks before lexing

**Summary**

When `<pre>` content contains HTML numeric-character references (e.g. `&#96;` for backtick) followed by characters that would otherwise tokenize, the parser appears to consume the entity bytes literally and the surrounding context fails. This breaks the common pattern of showing example backtick-syntax in documentation.

**Reprex**

```console
$ printf '<pre>\n&#96;&#96;&#96;{python}\nx\n&#96;&#96;&#96;\n</pre>\n' | pampa -t native
Error: Parse error
   ╭─[ <stdin>:2:17 ]
   │
 2 │ &#96;&#96;&#96;{python}
   │                 ───┬──
   │                    ╰──── unexpected character or token here
───╯
```

**Expected**

`<pre>` content should be treated as raw HTML — the parser shouldn't be tokenizing `{python}` as a Quarto attribute block when it's inside a raw-HTML region. (Either don't tokenize attribute syntax in raw-HTML contexts, or pre-decode numeric entities so `&#96;` becomes `` ` `` before evaluating tokens.)

**Pointer**

Raw-HTML block handling in `crates/tree-sitter-qmd/tree-sitter-markdown/grammar.js` — currently appears to leak Quarto attribute tokenization into HTML block contexts.

---

## Issue 15: Cascading generic "Parse error" diagnostics after a typed error

**Summary**

When a typed error like `Q-2-3 Key-value Pair Before Class Specifier` fires, pampa often emits one or more *additional* generic "Parse error" diagnostics whose locations point at unrelated downstream lines (frequently the next `:::`, ``` ``` ```, or table boundary). The downstream diagnostics are tree-sitter recovery artifacts, not separate root causes — fixing the typed error makes them all disappear.

**Reprex**

```console
$ printf '%s\n' '::: outer' '![alt](x.png){fig-alt="caption" .border}' ':::' ':::' | pampa -t native
[Q-2-3 fires correctly at the image, then several generic Parse errors at the :::]
```

In quarto-web's `_visual-editor.qmd`, a single Q-2-3 produces 1 typed + 3 generic errors at the next three `:::` boundaries.

**Expected**

After a typed error, suppress the generic recovery-cascade errors (mark them as warnings, hide them behind a flag, or attach them to the typed error as `details`). They make `pampa_parse_*` output noisy and obscure which error the user actually has to fix.

**Pointer**

The diagnostic emission step in `crates/pampa/src/readers/qmd.rs` — specifically the path that walks tree-sitter `ERROR` nodes after the readers' typed-error pass. Either skip ERROR nodes within N lines/bytes of an already-emitted typed error, or skip ERROR nodes entirely when any typed error fired.
