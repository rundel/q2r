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
