# q2r

R package that wraps the `pampa` Rust crate from [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto's QMD parser to R. Exploratory: the main user-facing function [`q2r::pampa_parse()`](R/pampa.R) takes text or a file path and returns a [`pampa_result`](R/result.R) S7 object carrying the tree-sitter AST (`ts_ast`), parse diagnostics, the Pandoc AST (`pd_ast`, as S7 `pandoc` objects), and the Pandoc AST rendered in native format.

## Architecture

### Rust

- [src/rust/src/lib.rs](src/rust/src/lib.rs) exposes two `#[extendr]` functions:
  - `pampa_parse_impl(text, filename)` calls [`pampa::readers::qmd::read`](../q2/crates/pampa/src/readers/qmd.rs) with a `Vec<u8>` as the `output_stream` argument (captures the `print_whole_tree` dump that `pampa -v` normally sends to stderr), renders the returned `Pandoc` AST via [`pampa::writers::native::write`](../q2/crates/pampa/src/writers/native.rs), and converts each `DiagnosticMessage` into a structured R list via `diag_to_r::diag_to_r`. No pretty-printed diagnostic text is produced at parse time.
  - `pampa_diag_format_impl(kind, code, title, problem, details, hints, location, source_text, source_filename, hyperlinks)` reconstructs a `DiagnosticMessage` from the slot values of a [`pampa_diagnostic`](R/diagnostic.R) S7 object, builds a fresh `SourceContext` from `source_text` + `source_filename`, and calls `DiagnosticMessage::to_text_with_options` to render ariadne output. This is the "S7 → Rust → formatted text" path used by `print()` / `format()`.
- [src/rust/src/diag_to_r.rs](src/rust/src/diag_to_r.rs) owns both halves of the round trip:
  - `diag_to_r(&DiagnosticMessage, &SourceContext) -> Robj` flattens the message into a named list with `kind`, `code`, `title`, `problem`, `details`, `hints`, `location` (`map_offset`-resolved to `file`, `start_offset`/`row`/`column`, `end_offset`/`row`/`column`).
  - `format_diag(...)` + `reconstruct_diagnostic(...)` rebuild a `DiagnosticMessage` directly from those fields. `SourceInfo` is reconstructed as `Original { file_id: FileId(0), ... }` because the rebuilt `SourceContext` always has exactly one file at position 0; this is enough for ariadne rendering but drops any `Substring`/`Concat` transformation history that the original had.
- [src/rust/src/pd_ast_to_r.rs](src/rust/src/pd_ast_to_r.rs) and [src/rust/src/ts_ast_to_r.rs](src/rust/src/ts_ast_to_r.rs) convert the Pandoc AST (`pd_ast`) and tree-sitter AST (`ts_ast`) into tagged nested lists. Note: `ts_ast` `text` semantics diverge from `pd_ast`: `ts_ast` leaves always carry their source text, and any non-leaf whose children do not cover its full byte range (a grammar "gap": `pandoc_math`, `pandoc_display_math`, `code_fence_content`, and structural leads like the `](` in `target`) also carries its full source span. This is required for [`to_qmd()`](R/ts-ast-to-qmd.R) to reconstruct bytes that tree-sitter-qmd parses via anonymous regexes and therefore never surfaces as named nodes. Revisit if the upstream grammar ever promotes those bytes to real named nodes.

### R

- [R/pampa.R](R/pampa.R) wraps the extendr bindings with `pampa_parse()`. Input heuristic: string contains `\n` ⇒ text; else `file.exists() && !dir.exists()` ⇒ file; else text. The original `text` and `filename` are threaded into every `pampa_diagnostic` so each diagnostic is self-contained for later rendering.
- [R/diagnostic.R](R/diagnostic.R) defines the `pampa_diagnostic` S7 class. Slots mirror the Rust list plus `source_text` / `source_filename`. `format(x, color = ...)` and `print(x, color = ...)` call back into Rust via `pampa_diag_format_impl`; when `color = FALSE`, remaining ANSI is stripped with `cli::ansi_strip()`. `color` is **only** a display-time argument — `pampa_parse()` itself has no `color` parameter.
- [R/result.R](R/result.R) defines `pampa_result`, whose `@diagnostics` slot is a list of `pampa_diagnostic` objects. `print.pampa_result(x, color = ...)` threads `color` through to each diagnostic.
- [R/ts-ast-to-qmd.R](R/ts-ast-to-qmd.R) defines `to_qmd()` (S7 generic on `ts_tree` / `ts_node`), which walks the tree-sitter AST and emits QMD source text via a per-kind handler table (`ts_kind_handlers`). Output is canonical: blank-line runs collapse to one blank, trailing whitespace is dropped, missing trailing newlines are added. For nodes whose children leave gaps (math, `code_fence_content`) the handlers fall back to `@text` populated by the Rust exporter. Unknown kinds emit a warning and default to plain child concatenation.

## Toolchain

- Rust **edition 2024** ⇒ **rustc ≥ 1.85** (declared in `DESCRIPTION` via `SystemRequirements`).
- Bridge: `extendr` + `rextendr` (matches Posit-authored Rust-backed R packages).
- Rebuild after Rust edits: `rextendr::document()`. Iterate interactively: `devtools::load_all()`.

## Pampa dependency

- Pulled via a Cargo git dependency on the whole `quarto-dev/q2` repo, pinned by `rev`. See [src/rust/Cargo.toml](src/rust/Cargo.toml).
- A whole-repo git dep is required because `pampa` has ~15 workspace-local `path = "../quarto-*"` sibling crates; vendoring or depending on `pampa` alone does not resolve.
- Current pinned commit: `e47c6e1d62ab4d935434a1f5875f7bed10c140f1`. Bumps are deliberate: update the `rev` **and** regenerate `Cargo.lock`. All three q2 deps (`pampa`, `tree-sitter-qmd`, `quarto-source-map`, `quarto-error-reporting`) must be bumped together.
- `default-features = false` on `pampa` drops `terminal-support`, `json-filter`, `lua-filter`, `template-fs`. None of these are needed for library-style parsing; disabling keeps builds lean and avoids Lua / subprocess linkage.
- `quarto-source-map` is a direct dep because we construct a `SourceContext` ourselves on the `Err` branch of `qmd::read` (the reader only returns a context on `Ok`) and on every `pampa_diag_format_impl` call.
- `quarto-error-reporting` is a direct dep because we need `TextRenderOptions` (hyperlink toggle) and to `Deserialize`/reconstruct `DiagnosticMessage` values.

## ts_ast → QMD rendering contract

- `to_qmd()` is lossy by design: it normalizes whitespace rather than preserving it byte-for-byte. Re-parsing the output should produce a structurally identical `ts_ast` (same kind tree), but the source bytes may differ (blank line counts, trailing spaces, indentation).
- Per-kind handlers live in `ts_kind_handlers` in [R/ts-ast-to-qmd.R](R/ts-ast-to-qmd.R) and are derived empirically + by consulting [grammar.js](../q2/crates/tree-sitter-qmd/tree-sitter-markdown/grammar.js). Extending to a new kind: run a few parses, observe how that kind's children map to source bytes, and add a handler.
- `@text` on non-leaves is the escape hatch for grammar gaps. Handlers that use it: `pandoc_math`, `pandoc_display_math`, `code_fence_content`. If upstream tree-sitter-qmd promotes those anonymous regexes to named nodes, this fallback (and the corresponding Rust exporter logic in [ts_ast_to_r.rs](src/rust/src/ts_ast_to_r.rs)) can be removed.

## Diagnostic rendering contract

- Parse output carries only structured data — no pre-rendered strings.
- Pretty-printing is lazy: R calls `pampa_diag_format_impl` at print/format time. This means each `print(diag)` re-runs ariadne.
- Reconstruction is lossy for `SourceInfo` transformation chains (see above); if we ever need the original chain preserved (e.g., for diagnostics nested in language-block substrings), the reconstruction path will need to be revisited.
- ANSI colours come from ariadne's hardcoded config; we can't disable them at render time, so `color = FALSE` strips them afterward in R via `cli::ansi_strip()`. `hyperlinks` (OSC 8) **can** be toggled at render time via `TextRenderOptions.enable_hyperlinks`, which is tied to the R-side `color` flag.

## Style

- R: use `=` for assignment, `pkg::fn` over imports, minimize single-line comments.
- Rust: standard rustfmt; no decorative comments.

## Known risks

- First build fetches the entire q2 workspace (~40 crates) via cargo; subsequent builds cache.
- Users must have `rustc ≥ 1.85` installed (rustup is the reliable path).
- `default-features = false` has not yet been verified to build across all pampa library paths we call; if it fails, narrow the feature subset (never re-enable `lua-filter`).
- The diagnostic reconstruction path assumes a single-file `SourceContext` and `SourceInfo::Original`. Diagnostics coming from pampa that point into `Substring`/`Concat` sources render correctly *because* `map_offset` has already resolved them to file-level byte offsets before we flatten to R; changes to pampa's diagnostic shape (e.g., multi-file details) could break this silently.

## TODO

- pd_ast → QMD: `pandoc_figure` does not structurally round-trip. Pandoc lifts a standalone-image paragraph into `Figure { content: [Plain [Image ...]], caption, ... }`; our fallback wraps that in a `::: {}` fenced div, which on re-parse yields `Div { Paragraph [Image] }` with no `pandoc_figure` wrapper. Fix: detect the common "figure wrapping a single image" shape and emit just the bare `![alt](url)` line (and carry the caption through the image's title / standard caption syntax) so pandoc's implicit-figure lifting reconstructs the original. Also decide how to serialize non-trivial figure captions.
