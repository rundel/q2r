# q2 issues to file

Each reprex uses the `pampa` CLI (`cargo run --bin pampa --` or a built `pampa` binary on the path).

---

## Issue 2: QMD writer doesn't escape `@` in link text, breaking `Str` → `Cite`

**Summary**

When a link's content contains a literal `@`-prefixed token (parsed as `Str` because the source had `\@`), the QMD writer emits the `@` unescaped. On re-parse the same text becomes a `Cite`, so the AST is not preserved across round-trip.

**Reprex**

```console
$ printf 'See [\\@jjallaire](https://github.com/jjallaire/) for details.\n' | pampa -t native
[ Para [Str "See", Space, Link ( "" , [] , [] ) [Str "@jjallaire"] ("https://github.com/jjallaire/" , ""), Space, Str "for", Space, Str "details."] ]

$ printf 'See [\\@jjallaire](https://github.com/jjallaire/) for details.\n' | pampa -t qmd
See [@jjallaire](https://github.com/jjallaire/) for details.

$ printf 'See [@jjallaire](https://github.com/jjallaire/) for details.\n' | pampa -t native
[ Para [Str "See", Space, Link ( "" , [] , [] ) [Cite [Citation { citationId = "jjallaire", ... }] [Str "@jjallaire"]] ("https://github.com/jjallaire/" , ""), Space, Str "for", Space, Str "details."] ]
```

The first parse is a `Link [Str "@jjallaire"]`; after a writer round-trip the same text re-parses as `Link [Cite ... [Str "@jjallaire"]]`.

**Expected**

When emitting a `Str` whose text starts with `@` in a context where bare `@token` would parse as `Cite`, the writer should emit `\@`. (The same likely applies to other inline contexts, not just `Link`.)

**Pointer**

`write_link` at `crates/pampa/src/writers/qmd.rs:1388` emits link text via `write_inline` with no awareness that some `Str` values need to be escaped to suppress `Cite` parsing on the round trip.

---

## Issue 3: QMD writer mangles a `Div` containing a `Figure`

**Summary**

A bare-attribute div wrapping a single image is parsed as `Div [ Figure [Plain [Image]] ]`. The QMD writer round-trips this to a doubly-nested `:::` block where the figure caption is duplicated as a plain text line, producing output that re-parses to a different AST and is visually broken.

**Reprex**

```console
$ printf '![Webpage](image.png){.lightbox}\n' | cargo run --bin pampa -- -t native
[ Div ( "" , [] , [] ) [Figure ( "" , [] , [] ) (Caption Nothing [ Plain [Str "Webpage"] ]) [Plain [Image ( "" , ["lightbox"] , [] ) [Str "Webpage"] ("image.png" , "")]]] ]

$ printf '![Webpage](image.png){.lightbox}\n' | cargo run --bin pampa -- -t qmd

```

The `Figure` has been re-emitted as another `:::` block, and its caption (`Webpage`) is rendered both inside the image and as a separate plain-text paragraph below it.

**Expected**

The writer should reproduce the original (or at minimum a structurally equivalent) `Div { Figure ... }` — typically just the bare image line, since pandoc's implicit-figure rule lifts a standalone-image paragraph into a `Figure`.

**Pointer**

`write_figure` at `crates/pampa/src/writers/qmd.rs:721`. The duplicated caption suggests both the `Image` content and the `Caption` `long` blocks are being written; for the implicit-figure shape (`Figure { content: [Plain [Image]], caption: Caption { long: [Plain [Str "Webpage"]] } }`) only the image line should be emitted.

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
