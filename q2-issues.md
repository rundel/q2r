# q2 issues to file

Each reprex uses the `pampa` CLI (`cargo run --bin pampa --` or a built `pampa` binary on the path).

---

## Issue 4: QMD writer normalizes list markers, breaking source-fidelity round-trips

**Summary**

The QMD writer always emits `*` as the bullet-list marker regardless of the source's marker character (`-`, `+`, or `*`), and collapses any wider marker indent down to a single space. Ordered-list markers are preserved (`.` vs `)`) but gain an extra space after the marker (`1. ` → `1.  `). Each rewrite changes the tree-sitter `list_marker_*` node kind and/or text, so round-tripping a document with non-`*` bullets or non-default indentation does not produce structurally equivalent output. This affects ~482 of ~568 quarto-web fixtures in q2r's `pampa_to_qmd` ts round-trip suite.

**Reprex**

```console
$ printf -- '- alpha\n- beta\n' | pampa -t qmd
* alpha
* beta

$ printf '+ alpha\n+ beta\n' | pampa -t qmd
* alpha
* beta

$ printf '*   alpha\n*   beta\n' | pampa -t qmd
* alpha
* beta

$ printf '1. alpha\n2. beta\n' | pampa -t qmd
1.  alpha
2.  beta
```

The corresponding `pampa -t native` output is identical for all three bullet inputs (a single `BulletList` containing two `Plain [Str ...]` items), so the writer has no way to recover the original marker — the marker shape is dropped at parse time.

**Expected**

The Pandoc AST should retain enough information for the writer to reproduce the source marker, or — failing that — the writer should not silently change marker shapes during a no-op round-trip. For ordered lists, the writer should emit `1. ` (single space) when that's what the source had.

**Pointer**

The bullet-marker emission path is in `crates/pampa/src/writers/qmd.rs` (`write_bullet_list` / `write_list_item`). The drop happens earlier — in the QMD reader's bullet-list construction (`crates/pampa/src/readers/qmd.rs`), which discards the marker character because pandoc's `BulletList` shape has no slot for it. To fix the round-trip cleanly the AST would need a side-channel for marker shape, or the writer would need to consult the original source text via `SourceContext`. The single-space ordered-marker indent is a simpler writer-side bug.

---

## Issue 5: QMD writer normalizes YAML scalar quoting in front matter

**Summary**

The YAML metadata block is re-emitted by walking the parsed metadata map rather than passing the source bytes through verbatim. As a side effect, scalar quoting is normalized: quoted strings whose contents do not require quoting lose their quotes, and unquoted URL-like strings gain quotes. This changes the `pampa_block_metadata` text, breaking source-fidelity round-trips even though the parsed metadata is semantically identical.

**Reprex**

```console
$ printf -- '---\ntitle: "Finley Malloc"\ndescription: "A short bio."\n---\n' | pampa -t qmd
---
title: Finley Malloc
description: A short bio.
---

$ printf -- '---\nabout:\n  links:\n    - href: https://example.com\n---\n\n# hi\n' | pampa -t qmd
---
about:
  links:
    - href: "https://example.com"
---

# hi
```

**Expected**

The writer should preserve the source's YAML scalar quoting style. Easiest path: emit the YAML block verbatim from the original `SourceContext` rather than reserializing it. (If reserialization is required for some reason, match yq/pandoc behavior of preserving the original style annotations.)

**Pointer**

`crates/pampa/src/writers/qmd.rs` — wherever metadata blocks are emitted. The reader at `crates/pampa/src/readers/qmd.rs` already keeps the metadata raw text; the writer just needs to use it.

---

## Issue 6: QMD writer over-escapes `|` in plain text outside tables

**Summary**

The writer emits `\|` for any literal pipe character in inline text, including text that is not inside a table cell. This adds a backslash that wasn't in the source and changes the parsed leaf text.

**Reprex**

```console
$ printf 'Wengo Analytics | Head Data Scientist | April 2018 - present\n' | pampa -t qmd
Wengo Analytics \| Head Data Scientist \| April 2018 - present
```

`$` and `\` (line break) are correctly escaped only when context demands it — only `|` is unconditionally escaped.

**Expected**

The writer should only escape `|` when emitting inside a pipe-table cell; in paragraph / heading / blockquote contexts it should emit a bare `|`.

**Pointer**

The escape rule lives in `crates/pampa/src/writers/qmd.rs` (likely the inline `Str` writer). It needs context awareness — pipe-table writer should request escaping; everything else should not.

---

## Issue 7: QMD writer normalizes code-fence width to the minimum required

**Summary**

A 4-backtick fence whose body does not contain a 3-backtick run is rewritten as a 3-backtick fence. This changes the leaf text of `fenced_code_block_delimiter` and (more seriously) breaks nested fences when the inner fence width is no longer strictly less than the outer fence's width.

**Reprex**

```console
$ printf -- '````markdown\nno inner backticks\n````\n' | pampa -t qmd
```markdown
no inner backticks
```

$ printf -- '````markdown\n```python\nnested\n```\n````\n' | pampa -t qmd
````markdown
```python
nested
```
````
```

The first case loses a backtick on each delimiter when none was needed; the second case correctly keeps four because the inner ` ``` ` requires it.

**Expected**

Preserve the source's fence width. A wider-than-needed fence is a stylistic choice (often used to host nested fences in tutorials), and demoting it can break embedded examples whose own fences then collide with the outer delimiter.

**Pointer**

`write_code_block` in `crates/pampa/src/writers/qmd.rs`. The fence width is computed from content; it should be max(source-width, content-required-width).

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

`write_table` in `crates/pampa/src/writers/qmd.rs`. The current path appears to interleave row-separator lines with cell-text lines that have been Str-escaped (so `|` becomes `\|`); it never produces a valid grid- or pipe-table. Likely the same code path Issue 6 escapes through — the writer wraps each row's text rather than building proper cell delimiters.

---

## Issue 11: tree-sitter-qmd cannot parse fenced code blocks inside grid-table cells

**Summary**

A grid table cell containing a fenced code block (the standard Quarto pattern for showing OS-specific terminal commands side-by-side) fails to parse. Pampa emits a generic "Parse error" pointing at the backticks. This affects 17 of the ~568 quarto-web fixtures, accounting for ~120 of the 241 initial-parse-error sites in the test suite — the dominant source of files that have to be skipped before round-trip even starts.

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
