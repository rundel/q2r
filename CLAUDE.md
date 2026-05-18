# q2r

R package that wraps the `pampa` Rust crate from [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto's QMD parser to R. Exploratory. The two main entry points are [`pampa_parse_pd()`](R/pampa.R) (returns an S7 [`pandoc`](R/pd-ast-pandoc.R) object — the parsed Pandoc AST) and [`pampa_parse_ts()`](R/pampa.R) (returns an S7 [`ts_tree`](R/ts-ast.R) — the tree-sitter AST). Both accept text or a file path and attach any parse [`pampa_diagnostic`](R/diagnostic.R) records to the returned object's `@diagnostics` slot. Helpers: [`pampa_to_qmd()`](R/pampa.R) renders back to QMD via pampa's writer, [`pampa_native()`](R/pampa.R) emits Pandoc's native AST format, [`pampa_tree()`](R/pampa.R) captures pampa's `-v` tree dump.

## Architecture

### Rust

- [src/rust/src/lib.rs](src/rust/src/lib.rs) exposes seven `#[extendr]` functions; all parser entry points call [`pampa::readers::qmd::read`](../q2/crates/pampa/src/readers/qmd.rs) and convert each `DiagnosticMessage` into a structured R list via `diag_to_r::diag_to_r`. No pretty-printed diagnostic text is produced at parse time.
  - `pampa_parse_pd_impl(text, filename, prune_errors)` returns `list(pd_ast, diagnostics)`. `pd_ast` is the tagged nested list produced by `pd_ast_to_r::pandoc_to_r` (or `NULL` on error).
  - `pampa_parse_ts_impl(text, filename, prune_errors)` returns `list(ts_ast, diagnostics)`. `ts_ast` is built directly via `ts_ast_to_r::parse_ts_ast_to_r` (tree-sitter parsing never fails); diagnostics are still produced by running `qmd::read` and discarding the Pandoc result.
  - `pampa_tree_impl(text, filename)` is the only entry point that uses `qmd::read`'s `output_stream` argument as a non-sink — passes a `Vec<u8>` to capture the `print_whole_tree` dump that `pampa -v` normally sends to stderr. Returns it as `Vec<String>`.
  - `pampa_native_impl(text, filename)` runs `qmd::read` then `pampa::writers::native::write` and returns the lines. Testing helper.
  - `pampa_write_qmd_text_impl(text, filename)` and `pampa_write_qmd_ast_impl(r_ast)` invoke `pampa::writers::qmd::write` from text input or from an R-constructed tagged-list AST (reconstructed via `r_to_pd_ast::pandoc_from_r`). Both return `list(text, diagnostics)`. Used by `pampa_to_qmd()`.
  - `pampa_diag_format_impl(kind, code, title, problem, details, hints, location, source_text, source_filename, hyperlinks)` reconstructs a `DiagnosticMessage` from the slot values of a [`pampa_diagnostic`](R/diagnostic.R) S7 object, builds a fresh `SourceContext` from `source_text` + `source_filename`, and calls `DiagnosticMessage::to_text_with_options` to render ariadne output. This is the "S7 → Rust → formatted text" path used by `print()` / `format()`.
- [src/rust/src/diag_to_r.rs](src/rust/src/diag_to_r.rs) owns both halves of the round trip:
  - `diag_to_r(&DiagnosticMessage, &SourceContext) -> Robj` flattens the message into a named list with `kind`, `code`, `title`, `problem`, `details`, `hints`, `location` (`map_offset`-resolved to `file`, `start_offset`/`row`/`column`, `end_offset`/`row`/`column`).
  - `format_diag(...)` + `reconstruct_diagnostic(...)` rebuild a `DiagnosticMessage` directly from those fields. `SourceInfo` is reconstructed as `Original { file_id: FileId(0), ... }` because the rebuilt `SourceContext` always has exactly one file at position 0; this is enough for ariadne rendering but drops any `Substring`/`Concat` transformation history that the original had.
- [src/rust/src/pd_ast_to_r.rs](src/rust/src/pd_ast_to_r.rs) and [src/rust/src/ts_ast_to_r.rs](src/rust/src/ts_ast_to_r.rs) convert the Pandoc AST (`pd_ast`) and tree-sitter AST (`ts_ast`) into tagged nested lists. Note on `ts_ast` `@text`: populated only where R cannot recover the source otherwise — on leaves (whose text is the sole carrier of the lexeme) and on "grammar-gap" non-leaves whose children do not cover the node's full byte range (`pandoc_math`, `pandoc_display_math`, `code_fence_content`, and structural leads like the `](` in `target`). Everywhere else the slot is `NULL`, and the text is obtainable by walking children. This is a deliberate stopgap: the gap cases exist because tree-sitter-qmd parses those bytes via anonymous regexes and never surfaces them as named nodes. When upstream promotes them to real nodes, `@text` on non-leaves (and the corresponding Rust logic here) should go away. Consumers must not treat `@text` as a general byte-reconstruction field — all text reconstruction goes through [`to_qmd()`](R/ts-ast-to-qmd.R); `@text` is only consulted inside the handlers for those specific gap kinds.
- [src/rust/src/r_to_pd_ast.rs](src/rust/src/r_to_pd_ast.rs) is the inverse of `pd_ast_to_r.rs`: it reconstructs a `pampa::pandoc::Pandoc` value from the tagged-list shape emitted by `pandoc_to_r`. Used only by `pampa_write_qmd_ast_impl` to drive pampa's QMD writer from an R-constructed AST (e.g. a `pandoc` S7 object converted via `pandoc_to_list()`).

### R

- [R/pampa.R](R/pampa.R) wraps the extendr bindings with `pampa_parse_pd()`, `pampa_parse_ts()`, `pampa_to_qmd()`, `pampa_tree()`, `pampa_native()`. Input heuristic (in `pampa_read_input`): string contains `\n` ⇒ text; else `file.exists() && !dir.exists()` ⇒ file; else text. The original `text` and `filename` are threaded into every `pampa_diagnostic` so each diagnostic is self-contained for later rendering. Both parsers accept `quiet` (suppress signaling) and `prune_errors` (matches pampa CLI: dedupe parser-error diagnostics by tree-sitter `ERROR` node, keeping the earliest); `pampa_parse_pd()` additionally accepts a `ts_tree` input by routing through `to_qmd()` first. `pampa_to_qmd()` accepts text/file path, a `ts_tree` (rendered via R-side `to_qmd()` then re-parsed and written), or a `pandoc` / tagged-list AST (handed straight to `pampa_write_qmd_ast_impl`). The pampa QMD writer is pd_ast-only — every input path ultimately produces a `pampa::pandoc::Pandoc` and runs `pampa::writers::qmd::write` on it.
- [R/diagnostic.R](R/diagnostic.R) defines the `pampa_diagnostic` S7 class plus `pampa_signal_diagnostics()` (the function `pampa_parse_*` calls to raise R warnings/errors when `quiet = FALSE`). Slots mirror the Rust list plus `source_text` / `source_filename`. `format(x, color = ...)` and `print(x, color = ...)` call back into Rust via `pampa_diag_format_impl`; when `color = FALSE`, remaining ANSI is stripped with `cli::ansi_strip()`. `color` is **only** a display-time argument — neither `pampa_parse_pd()` nor `pampa_parse_ts()` has a `color` parameter.
- Diagnostics ride on the parsed object's `@diagnostics` slot (`pandoc@diagnostics`, `ts_tree@diagnostics`). There is no longer a wrapper `pampa_result` class.
- [R/ts-ast-to-qmd.R](R/ts-ast-to-qmd.R) defines `to_qmd()` (S7 generic on `ts_tree` / `ts_node`), which walks the tree-sitter AST and emits QMD source text via a per-kind handler table (`ts_kind_handlers`). The goal is **functional equivalence**: the output must re-parse to a structurally identical `ts_ast`. For wrapper nodes whose children leave gaps (e.g. `section` between metadata and the first heading, math, `code_fence_content`), handlers fall back to `@text` populated by the Rust exporter, so inter-element whitespace round-trips verbatim. Unknown kinds emit a warning and default to plain child concatenation. Use [`ts_to_text()`](R/ts-ast.R) when byte-exact reconstruction is required instead.
- [R/pd-ast-to-qmd.R](R/pd-ast-to-qmd.R) is the pd_ast counterpart: it defines `to_qmd()` methods for the `pandoc` S7 hierarchy (`pandoc`, `pandoc_block`, `pandoc_inline`, and every concrete leaf). This is an R-side QMD renderer used for testing parity with pampa's writer; production rendering of a `pandoc` object via `pampa_to_qmd()` goes through `pampa_write_qmd_ast_impl` instead.
- [R/from-rust.R](R/from-rust.R) and [R/to-rust.R](R/to-rust.R) convert between the tagged-list shape that crosses the extendr boundary and the S7 `pandoc` hierarchy. `pandoc_from_list` / `pandoc_to_list` are the top-level entry points used by `pampa_parse_pd()` and `pampa_to_qmd(pandoc_obj)` respectively.
- The `pandoc` S7 hierarchy itself is defined across [pd-ast-pandoc.R](R/pd-ast-pandoc.R), [pd-ast-block.R](R/pd-ast-block.R), [pd-ast-inline.R](R/pd-ast-inline.R), [pd-ast-support.R](R/pd-ast-support.R) (helper types: `pandoc_attr`, `pandoc_target`, `pandoc_caption`, citations, table cells, etc.), and [pd-ast-print.R](R/pd-ast-print.R) (S7 `print`/`format` methods).
- [R/tests.R](R/tests.R) holds the three `gen_*_rt_test` factories (`gen_ts_rt_test`, `gen_pd_rt_test`, `gen_pampa_pd_rt_test`) and the `QUARTO_WEB_SKIP` skip-map that `helper-quarto-web.R` uses to (re)generate the sweep test files. Per-fixture skip lists are keyed by upstream q2 issue: each entry's reason is `"q2#NNN (short description)"`, and the test surfaces it as `Known failure: q2#NNN ...`. When an upstream issue closes, remove its entries from `QUARTO_WEB_SKIP` and verify the previously-skipped fixtures pass. Tests that hit an initial parse error still skip themselves inline via `if (has_error_diagnostics(...)) skip(...)`. Note: there is no `pampa_to_qmd(ts_tree)` round-trip suite — pampa's QMD writer only consumes pd_ast, so the ts variant would just be `to_qmd(ts) → pampa_parse + pampa_pd_rt` glued together and is covered by those two suites separately.

## Toolchain

- Rust **edition 2024** ⇒ **rustc ≥ 1.85** (declared in `DESCRIPTION` via `SystemRequirements`).
- Bridge: `extendr` + `rextendr` (matches Posit-authored Rust-backed R packages).
- Rebuild after Rust edits: `devtools::document()` (recompiles Rust and regenerates `R/extendr-wrappers.R`). Iterate interactively: `devtools::load_all()`.
- Running `devtools::test()` non-interactively: the `summary` reporter caps at 10 failures by default, which makes counts meaningless. Always raise the cap with `options(testthat.summary.max_reports = Inf)` when running for tally/comparison purposes (the per-reporter `max_fails` / env var / `set_max_fails()` knobs all silently no-op for the summary reporter — `testthat.summary.max_reports` is the only one that works).

## Round-trip iteration tools

The `tools/` directory (gitignored, in `.Rbuildignore`) holds throwaway scripts for iterating on the pd_ast → QMD round-trip. Both load the package via `devtools::load_all()` and run against the `tests/fixtures/quarto-web/` submodule.

- [`tools/rt/rt.R`](tools/rt/rt.R) — round-trip a small named set of files. Pass `-v` for diff context.
  ```
  Rscript tools/rt/rt.R about.qmd docs/authoring/_kbd.qmd
  Rscript tools/rt/rt.R -v docs/reference/globs.qmd
  ```
- [`tools/rt/rt-fails.R`](tools/rt/rt-fails.R) — sweep every quarto-web `.qmd` (or a regex-filtered subset) and print only failures with one-line diff context. ~100s for the full ~568-file sweep, much faster than running the testthat round-trip files. This sweep uses the R-side pd_ast round-trip path (`to_qmd(pd) → pampa_parse_pd → expect_pd_ast_equal`), not pampa's writer.
  ```
  Rscript tools/rt/rt-fails.R              # all files
  Rscript tools/rt/rt-fails.R "_kbd|globs" # filter by regex
  ```
- [`tools/rt/rt-ts-fails.R`](tools/rt/rt-ts-fails.R) — same sweep idea for the **ts_ast** round-trip (`to_qmd(ts) → pampa_parse_ts → expect_ts_ast_equal`). Use this when iterating on `ts_kind_handlers` in `R/ts-ast-to-qmd.R`.

Each FAIL line from the pd_ast sweep is followed by either a `rt-diag:` reason (rendered output failed to re-parse) or a `native | CTX/A/B` block showing the first byte at which the original and re-rendered native ASTs diverge — useful for guessing the failing renderer.

Top-level [`tools/config.R`](tools/config.R) and [`tools/msrv.R`](tools/msrv.R) are **not** throwaway: they run at install time from `configure` to validate the rust toolchain and template `Makevars{,.win}.in`. Do not delete or rename without updating `configure`.

## Pampa dependency

- A local working copy of `quarto-dev/q2` lives at `../q2/` (sibling of this project, not embedded). It is the canonical location for `/q2-sync` work and for capturing reprex output via the `pampa` CLI. Cargo fetches its own copy independently — see below — so the local checkout is a developer convenience, not a build dependency.
- Pulled via a Cargo git dependency on the whole `quarto-dev/q2` repo, pinned by `rev`. See [src/rust/Cargo.toml](src/rust/Cargo.toml).
- A whole-repo git dep is required because `pampa` has ~15 workspace-local `path = "../quarto-*"` sibling crates; vendoring or depending on `pampa` alone does not resolve.
- Current pinned commit: `1afd5a6ac95ddc7887dc6d92085d6f5c539d493d`. Bumps are deliberate: update the `rev` **and** regenerate `Cargo.lock`. All four q2 deps (`pampa`, `tree-sitter-qmd`, `quarto-source-map`, `quarto-error-reporting`) must be bumped together.
- `default-features = false` on `pampa` drops `terminal-support`, `json-filter`, `lua-filter`, `template-fs`, and (since q2#192) transitively the new `filters` feature these activate. Dropping `filters` removes `quarto-system-runtime` and its v8/deno_core transitive deps from the link graph — important for the R-package shared-library build on Linux, where v8 linkage is problematic. None of these features are needed for library-style parsing; disabling keeps builds lean and avoids Lua / subprocess linkage.
- `quarto-source-map` is a direct dep because we construct a `SourceContext` ourselves on the `Err` branch of `qmd::read` (the reader only returns a context on `Ok`) and on every `pampa_diag_format_impl` call.
- `quarto-error-reporting` is a direct dep because we need `TextRenderOptions` (hyperlink toggle) and to `Deserialize`/reconstruct `DiagnosticMessage` values.

## ts_ast → QMD rendering contract

- `to_qmd()` aims for **functional equivalence**: the output must re-parse to a `ts_ast` equal to the original (same kind tree and same `@text` slots). The correctness check used by the round-trip tests is `expect_ts_ast_equal(ts2, ts)` after `to_qmd(ts) -> pampa_parse_ts(...)`. Wrapper nodes that have a grammar gap (children don't cover the full byte range) preserve the gap by falling back to verbatim `@text`; this is how blank lines, indentation, and other inter-element whitespace stay byte-identical across the round trip.
- `to_qmd()` is the sole text-reconstruction path for `ts_ast`. There is no byte-exact reconstruction helper by design: pampa re-parses any text we feed back to it, so functional equivalence is sufficient. Paths like [`pampa_parse_pd(ts_tree)`](R/pampa.R) and [`pampa_to_qmd(ts_tree)`](R/pampa.R) route through `to_qmd()` for this reason.
- Per-kind handlers live in `ts_kind_handlers` in [R/ts-ast-to-qmd.R](R/ts-ast-to-qmd.R) and are derived empirically + by consulting [grammar.js](../q2/crates/tree-sitter-qmd/tree-sitter-markdown/grammar.js). Extending to a new kind: run a few parses, observe how that kind's children map to source bytes, and add a handler. When adjusting a handler, verify the round-trip property holds.
- `@text` on non-leaves is the escape hatch for grammar gaps and is **the only place** handlers read `@text` directly. Handlers that use it: `pandoc_math`, `pandoc_display_math`, `code_fence_content`. Treat any other use of `@text` as a bug — all other kinds must emit by walking children, because `@text` is `NULL` on them. If upstream tree-sitter-qmd promotes those anonymous regexes to named nodes, these three fallbacks (and the corresponding Rust exporter logic in [ts_ast_to_r.rs](src/rust/src/ts_ast_to_r.rs)) can be removed.

## Diagnostic rendering contract

- Parse output carries only structured data — no pre-rendered strings.
- Pretty-printing is lazy: R calls `pampa_diag_format_impl` at print/format time. This means each `print(diag)` re-runs ariadne.
- Reconstruction is lossy for `SourceInfo` transformation chains (see above); if we ever need the original chain preserved (e.g., for diagnostics nested in language-block substrings), the reconstruction path will need to be revisited.
- ANSI colours come from ariadne's hardcoded config; we can't disable them at render time, so `color = FALSE` strips them afterward in R via `cli::ansi_strip()`. `hyperlinks` (OSC 8) **can** be toggled at render time via `TextRenderOptions.enable_hyperlinks`, which is tied to the R-side `color` flag.

## Style

- R: use `=` for assignment, `pkg::fn` over imports, minimize single-line comments.
- Rust: standard rustfmt; no decorative comments.
- Commit messages: one sentence, no body, no `Co-Authored-By` or other self-attribution trailers.

## Notes folder

All ad-hoc notes, drafts, state logs, and upstream-bug write-ups live under `notes/` (gitignored). This includes upstream issue drafts (`notes/<short-name>_issue.md`), the sync-failure log (`notes/q2-sync-notes.md`), and the running upstream issue list (`notes/issues.md`). Do not put these at the project root or under `../q2/`.

`notes/done/` holds issue drafts that have been **filed upstream** (a q2 issue number now exists), regardless of whether they have since been resolved. The skip reason in [R/tests.R](R/tests.R) is the authoritative source of truth for whether a given upstream issue is still affecting q2r tests — when an issue closes, drop its entries from `QUARTO_WEB_SKIP` and verify the previously-skipped fixtures pass, but leave the corresponding note in `notes/done/` as a historical record.

## Filing q2 issues

Draft upstream q2 bug reports to `notes/<short-name>_issue.md`. Format:

- Before running any pampa CLI command in `../q2/` for a reprex, verify that `git -C ../q2 rev-parse HEAD` matches the `rev = '...'` value pinned in [src/rust/Cargo.toml](src/rust/Cargo.toml). The local `../q2/` checkout is independent of the cargo-fetched build cache, and a stale checkout will produce CLI output that disagrees with the behavior q2r actually sees — silently leading to misdiagnosed bug reports. If they differ, `git -C ../q2 checkout <pinned-rev>` (and `git -C ../q2 rev-parse HEAD` again) before capturing any output for the reprex.
- H1 with a one-line declarative summary of the bug. Sentence case. No "Title:" prefix, no headers like "Body" or "Reproduction" inside the file.
- One short paragraph stating what is wrong and the observable consequence. No "Expected:" footer; the reprex output is the expectation.
- A single four-backtick fenced block holding the reproduction. Inside it, run the pampa CLI three ways: reader-only (`cargo run --bin pampa --`), writer-only (`cargo run --bin pampa -- -t qmd`), and the round trip (the writer piped back into the reader). Show each `$ <cmd>` immediately followed by its output, separated by blank lines.
- Build the input via `printf -- '...'` from the smallest possible bytes that exhibit the bug and pipe it directly into pampa (`printf -- '...' | cargo run --bin pampa -- 2>&1`). Do not write to a temp file — pampa reads from stdin when no filename arg is given, which keeps each command self-contained and avoids stale-fixture pitfalls.
- Do not pass `--quiet` to `cargo run` in reprex commands, and always append `2>&1` so pampa's diagnostics (which go to stderr) land in the captured output. Reprexes that only capture stdout silently drop the error and make the bug look like it isn't reproducing.
- When the printf input spans multiple lines, lead the reprex with a bare `$ printf -- '...'` followed by its expanded output so a reader can see the source bytes before the pampa commands run on them.
- After the reprex, list 1-3 in-the-wild occurrences in the `tests/fixtures/quarto-web/` submodule as GitHub permalinks. Use `https://github.com/quarto-dev/quarto-web/blob/<submodule-HEAD-sha>/<path>#L<line>` so the line numbers stay valid as upstream evolves. Get the SHA with `git -C tests/fixtures/quarto-web rev-parse HEAD`.
- No bolding, no decorative prose. Target under 20 lines (excluding the in-the-wild list).

## Known risks

- First build fetches the entire q2 workspace (~40 crates) via cargo; subsequent builds cache.
- Users must have `rustc ≥ 1.85` installed (rustup is the reliable path).
- `default-features = false` has not yet been verified to build across all pampa library paths we call; if it fails, narrow the feature subset (never re-enable `lua-filter`).
- The diagnostic reconstruction path assumes a single-file `SourceContext` and `SourceInfo::Original`. Diagnostics coming from pampa that point into `Substring`/`Concat` sources render correctly *because* `map_offset` has already resolved them to file-level byte offsets before we flatten to R; changes to pampa's diagnostic shape (e.g., multi-file details) could break this silently.

## TODO

- pd_ast → QMD: `pandoc_figure` only round-trips for the "single image wrapped in a Plain block" shape (handled in `pandoc_figure_single_image()` in [R/pd-ast-to-qmd.R](R/pd-ast-to-qmd.R) — emits a bare `![alt](url)` so pandoc's implicit-figure lifting reconstructs the original). For figures with non-trivial captions or multi-block content the renderer falls back to a `::: {}` fenced div with a warning, which re-parses to `Div { Paragraph [Image] }` without the `pandoc_figure` wrapper. Decide how to serialize non-trivial figure captions (image title vs. standard caption syntax) and extend the handler.
