---
description: Sync q2r with upstream q2 - review changes since the pinned rev, identify impact, integrate, and update the bindings
argument-hint: [target-rev]
allowed-tools: [Bash, Read, Edit, Write, Agent]
---

Update q2r to a newer revision of `quarto-dev/q2`. The argument `$ARGUMENTS` is an optional target rev (commit SHA, branch, or tag). If empty, default to `origin/main`.

Work through the phases below in order. Stop and confirm with the user at every checkpoint marked CHECKPOINT. Do not proceed past a checkpoint without explicit go-ahead.

## Scope

The four crates q2r consumes:

- `crates/pampa/`
- `crates/tree-sitter-qmd/`
- `crates/quarto-source-map/`
- `crates/quarto-error-reporting/`

If the diff shows that something outside these four crates has a downstream effect that we need to absorb (e.g., a type re-exported from a sibling crate that we depend on transitively), include it. Otherwise stay narrow.

## Phase 1: Set up

1. Read the current pinned rev from `src/rust/Cargo.toml`. There are four `rev = '...'` lines and they should all match. If they don't, stop and surface the mismatch.
2. Locate the q2 repo at `q2/` (inside this project; gitignored). If it isn't there, ask the user where it lives.
3. In `q2/`, run `git fetch --all --tags`. Do not check out, reset, or modify the working tree.
4. Resolve the target rev to a SHA. Default: `origin/main`.
5. If target SHA equals the current pinned SHA, report "already up to date" and exit.

Report:

- Current pinned SHA (short form + author date + subject)
- Target SHA (short form + author date + subject)
- Number of commits between them

CHECKPOINT 1: confirm the user wants to proceed with this target rev.

## Phase 2: Diff narrowing

For each of the four scoped crate paths:

- `git diff --stat <pinned>..<target> -- <path>` for the file overview
- `git log --oneline <pinned>..<target> -- <path>` for commit-level context

Also do a workspace-level pass for dep edges that could ripple in:

- `git diff --stat <pinned>..<target> -- Cargo.toml crates/*/Cargo.toml`

Report per crate:

- Number of files changed
- The file list
- Notable commit subjects

Plus a separate section for any workspace `Cargo.toml` shifts worth flagging (version bumps on shared deps, new feature flags, etc.).

If no files in the four crates changed, ask the user whether to proceed anyway (they may want a pure rev bump for unrelated reasons).

## Phase 3: Impact analysis

For each changed file in the four crates, determine whether it could affect q2r. The surfaces q2r actually touches:

- `src/rust/src/lib.rs`: `pampa::readers::qmd::read` signature and return shape; `pampa::writers::native::write` signature; the `output_stream: Vec<u8>` argument.
- `src/rust/src/diag_to_r.rs`: `DiagnosticMessage` fields, `SourceContext` / `SourceInfo` / `FileId` constructors and shape, `TextRenderOptions` fields, `map_offset` behavior, `to_text_with_options`.
- `src/rust/src/pd_ast_to_r.rs`: Pandoc AST types (`Block`, `Inline`, attributes, new variants).
- `src/rust/src/ts_ast_to_r.rs`: tree-sitter-qmd node kinds. Watch especially for grammar-gap promotions: any of `pandoc_math`, `pandoc_display_math`, `code_fence_content`, or the `](` lead in `target` becoming first-class named nodes. That would let us drop `@text` fallbacks (and the corresponding `to_qmd()` handlers).
- `R/ts-ast-to-qmd.R`: per-kind handlers in `ts_kind_handlers`. New node kinds in `grammar.js` need handlers; renamed kinds need updates.
- `R/diagnostic.R`, `R/result.R`: field mapping if `DiagnosticMessage` shape changed.

If the diff is large, use parallel `Agent` calls (subagent_type=Explore) with each agent assigned a specific surface above. Otherwise read the relevant diffs directly with `git show` / `git diff`.

Produce a structured impact report. For each affected q2r file:

- The upstream change (file + brief description)
- Why it matters
- What needs to change in q2r (rough sketch)
- Severity, one of:
  - Breaking: won't compile or wrong behavior
  - Opportunity: lets us simplify, e.g., grammar-gap removal
  - Watch: no action needed now but worth noting

Call out grammar-gap obsolescence prominently if it shows up. That has follow-on cleanup in both `ts_ast_to_r.rs` and `R/ts-ast-to-qmd.R`.

CHECKPOINT 2: present the impact report. Ask the user to confirm the integration plan, flag anything they want to defer to a later sync, and approve proceeding.

## Phase 4: Bump the pin

1. Update all four `rev = '...'` lines in `src/rust/Cargo.toml` to the new SHA in a single Edit (use `replace_all`).
2. Refresh `Cargo.lock`: `cargo update --manifest-path src/rust/Cargo.toml`. If that pulls in more than the four target crates, narrow with `-p pampa -p tree-sitter-qmd -p quarto-source-map -p quarto-error-reporting`.
3. Briefly report what changed in `Cargo.lock` (which crates moved, anything surprising).

## Phase 5: Rebuild and absorb breakage

Run `Rscript -e 'devtools::document()'` from the project root. This compiles the Rust side and regenerates the R bindings (`R/extendr-wrappers.R`).

If it fails, work the errors one at a time:

- Match each error to an item in the Phase 3 impact report.
- Propose the fix as an Edit with a brief explanation of why.
- For non-trivial decisions (e.g., a renamed enum variant that changes how we flatten Pandoc AST nodes to R), pause and ask the user before guessing.

After it builds clean, smoke test:

```
Rscript -e 'devtools::load_all(); print(q2r::pampa_parse("# hi"))'
```

Confirms the package loads, the basic parse path works, and diagnostic formatting still rounds through Rust without crashing.

## Phase 6: Reconcile expected-failure skip map (pre-test)

`R/tests.R` defines `QUARTO_WEB_SKIP`, a per-suite map keyed by quarto-web relative path. Each entry's reason has the form `"q2#NNN (short description)"`, marking a fixture as expected-failure pending the named upstream issue. Before running the suite, reconcile this map against current q2 issue state so a closed upstream issue stops hiding its fixtures.

1. Extract all `q2#NNN` references currently in the skip map:

   ```
   grep -oE 'q2#[0-9]+' R/tests.R | sort -u
   ```

2. Query each issue's state in one batch:

   ```
   gh issue list --repo quarto-dev/q2 --state all --limit 500 --json number,state,title
   ```

   Cross-reference the numbers from step 1 against the result. Note any whose `state` is `CLOSED`.

3. For each closed issue, identify the skip-map entries referencing it (`grep -n "q2#NNN" R/tests.R`) and report them to the user before editing.

4. With user go-ahead, remove those entries from `QUARTO_WEB_SKIP` in a single Edit. The auto-regeneration in `helper-quarto-web.R` will pick this up via the `R/tests.R` mtime change when Phase 7 runs the suite — no manual regeneration needed.

5. If nothing closed, say so and continue.

## Phase 7: Tests

Run the full suite **once**. **Always raise the failure cap** — the summary reporter truncates at 10 by default in non-interactive mode, which makes the failure count meaningless. Redirect to a temp file:

```
Rscript -e 'options(testthat.summary.max_reports = Inf); devtools::test(reporter = "summary")' > /tmp/q2r-test.log 2>&1
```

Do not re-run the suite on the same revision. The only acceptable reason to re-run is a critical failure that makes the results unusable (e.g., the suite crashed before reaching most tests, output got truncated/corrupted). Iteratively re-running narrower filters or the full suite to "confirm" things wastes time.

Group failures by failure mode (e.g., "12 tests fail with `pd ast mismatch: trailing blank line in raw block`", "3 tests fail with re-parse error in `<small>{=html}` context"). Do not run a pre-bump comparison sweep — `notes/q2-sync-notes.md` (see below) carries that history.

### Update `notes/q2-sync-notes.md`

`notes/q2-sync-notes.md` is an untracked file under the gitignored `notes/` folder that tracks failure state across syncs so regressions are detectable by diff.

- If the file is missing, create it with just the current sync's results — no historical context to compare against.
- If it exists, read it first. Compare the prior failure list against the current one and call out:
  - **New failures** (regression candidates from this bump)
  - **Resolved failures** (fixtures that now pass)
  - **Unchanged failures** (existing baseline)

Append a new dated section to the top of the file. Each section should contain:

- Header: `## <YYYY-MM-DD>: <old-short-sha> → <new-short-sha>`
- Total failure count
- Failure-mode groups with counts
- Per-fixture failure list (path + line ref + one-line failure-mode tag), sorted alphabetically, so future diffs are stable
- Diff vs. the prior section: New / Resolved / Unchanged counts (omit on the first run)

Keep the file terse — it's a state log, not a narrative. When older sections become uninformative (more than ~5 syncs back, or older than the current pinned rev minus a few), they can be pruned, but do not prune in the same run that added the new section.

For each failure-mode group decide whether it is:

- An absorption gap (we missed updating something on our side): fix it, then re-run only the failing test files (not the full suite) to verify.
- A genuine upstream behavior change (snapshots / golden output need to move): get explicit user sign-off before updating snapshots.
- An upstream bug we should defer behind a skip — handled by the next step.

If grammar-gap cleanup was on the table in Phase 3 and the user approved it, this is the place to rip out the corresponding `@text` paths in `ts_ast_to_r.rs` and the matching handlers in `R/ts-ast-to-qmd.R`, then re-run only the round-trip files to confirm functional equivalence still holds.

### Classify new failures against open q2 issues

For each new failure that the user wants deferred (i.e. it isn't an absorption gap and isn't a snapshot move):

1. Try to match the failure mode + repro to an open q2 issue:
   - Search by keyword: `gh issue list --repo quarto-dev/q2 --state open --search "<short failure-mode phrase>" --limit 20 --json number,title`
   - Also scan filed drafts under `notes/done/*.md` — they often capture exactly the failure mode and may already cite the upstream number in their text.
2. If a match is found, add an entry to the relevant suite map in `QUARTO_WEB_SKIP` (usually `pampa_pd_rt`) tagged `"q2#NNN (short description)"`. After all entries are added, re-run the affected suite once via `--filter` to confirm the new skips fire cleanly.
3. If no match is found, surface the failure to the user. Decide together: file a new q2 issue (drafts in `notes/done/` are good starting material), tag the skip preemptively with the new number, or leave the test failing until an issue exists.

Pre-test removals from Phase 6 also feed into this step. If a previously-skipped fixture reappears as a failure here (i.e. the upstream issue closed without the underlying behavior actually being fixed), surface it to the user — the upstream issue likely needs to be re-opened, or a follow-up filed.

CHECKPOINT 3: present the test results (grouped by failure mode, with the New/Resolved/Unchanged diff vs. the prior `notes/q2-sync-notes.md` entry, and the list of skip-map edits — both removals from Phase 6 and additions from this step). If anything is failing or any snapshot moved, get sign-off before continuing.

## Phase 8: Wrap up

Summarize:

- Old SHA -> new SHA
- Files in q2r that changed, one line each, with why
- Opportunities deferred (e.g., grammar-gap cleanup we noted but did not take)
- Follow-ups: any TODO updates needed in `CLAUDE.md` (the Known risks / TODO sections), or any new memory worth recording about a behavior change.

Do not commit. Leave that to the user.
