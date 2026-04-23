# q2r

R package that wraps the `pampa` Rust crate from [quarto-dev/q2](https://github.com/quarto-dev/q2) to expose Quarto's QMD parser to R. Exploratory: a single user-facing function, [`q2r::pampa_parse()`](R/pampa.R), takes text or a file path and returns a list with the tree-sitter concrete syntax tree, parse diagnostics, and the Pandoc AST rendered in native format.

## Architecture

- [src/rust/src/lib.rs](src/rust/src/lib.rs) exposes one `#[extendr]` function, `pampa_parse_impl(text, filename)`, that:
  - calls [`pampa::readers::qmd::read`](../q2/crates/pampa/src/readers/qmd.rs) with a `Vec<u8>` as the `output_stream` argument, capturing the `print_whole_tree` dump that `pampa -v` normally sends to stderr;
  - renders the returned `Pandoc` AST via [`pampa::writers::native::write`](../q2/crates/pampa/src/writers/native.rs) (signature: `(&Pandoc, &ASTContext, &mut impl Write)`);
  - maps `DiagnosticMessage::to_text(None)` for each diagnostic.
- [R/pampa.R](R/pampa.R) wraps the extendr binding with the user-facing `pampa_parse()` and a `print.pampa_parse()` method. The input heuristic lives here: string contains `\n` ⇒ text; else `file.exists() && !dir.exists()` ⇒ file; else text.

## Toolchain

- Rust **edition 2024** ⇒ **rustc ≥ 1.85** (declared in `DESCRIPTION` via `SystemRequirements`).
- Bridge: `extendr` + `rextendr` (matches Posit-authored Rust-backed R packages).
- Rebuild after Rust edits: `rextendr::document()`. Iterate interactively: `devtools::load_all()`.

## Pampa dependency

- Pulled via a Cargo git dependency on the whole `quarto-dev/q2` repo, pinned by `rev`. See [src/rust/Cargo.toml](src/rust/Cargo.toml).
- A whole-repo git dep is required because `pampa` has ~15 workspace-local `path = "../quarto-*"` sibling crates; vendoring or depending on `pampa` alone does not resolve.
- Current pinned commit: `e47c6e1d62ab4d935434a1f5875f7bed10c140f1`. Bumps are deliberate: update the `rev` and regenerate `Cargo.lock`.
- `default-features = false` drops `terminal-support`, `json-filter`, `lua-filter`, `template-fs`. None of these are needed for library-style parsing; disabling keeps builds lean and avoids Lua / subprocess linkage.

## Style

- R: use `=` for assignment, `pkg::fn` over imports, minimize single-line comments.
- Rust: standard rustfmt; no decorative comments.

## Known risks

- First build fetches the entire q2 workspace (~40 crates) via cargo; subsequent builds cache.
- Users must have `rustc ≥ 1.85` installed (rustup is the reliable path).
- `default-features = false` has not yet been verified to build across all pampa library paths we call; if it fails, narrow the feature subset (never re-enable `lua-filter`).
