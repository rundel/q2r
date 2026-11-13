---
description: Sync q2r with an upstream q2 GitHub release - review changes since the pinned release, identify impact, integrate, and update the bindings
argument-hint: [release-tag | prerelease]
allowed-tools: [Bash, Read, Edit, Write, Agent]
---

Update q2r to a newer GitHub release of `quarto-dev/q2`. Syncs track published releases, not arbitrary commits. The argument `$ARGUMENTS` selects the target release:

- Empty: the latest stable release (`gh release view -R quarto-dev/q2 --json tagName,name,isPrerelease`, which never returns a prerelease).
- `prerelease` (or `nightly`): the most recent prerelease, i.e. the first entry with `isPrerelease: true` in `gh release list -R quarto-dev/q2 --json tagName,name,isPrerelease,publishedAt`. Today that is the moving `nightly` tag, whose release name carries the version and short SHA (e.g. `q2 nightly 0.45.0-nightly.20261112 (a76c96abf)`).
- A tag (e.g. `v0.44.0`): that specific release. Confirm it exists with `gh release view <tag> -R quarto-dev/q2`; if it does not, stop and say so rather than falling back to a commit.

The pin in `src/rust/Cargo.toml` is always the release tag's resolved commit SHA in `rev = '...'` (never `tag = '...'`, since the `nightly` tag moves), with a `# q2 <release>` comment on the line above each `rev` naming the release it came from (the tag for a stable release, the full nightly version string for a prerelease).

Work through the phases below in order. Stop and confirm with the user at every checkpoint marked CHECKPOINT. Do not proceed past a checkpoint without explicit go-ahead.

## Scope

The four crates q2r consumes:

- `crates/pampa/`
- `crates/tree-sitter-qmd/`
- `quarto-source-map` (crates.io; no longer in the q2 tree since the `bd-egcyeym9` cutover, so there is no in-tree path to diff)
- `quarto-error-reporting` (crates.io; same)

The two crates.io crates are consumed by `version` and move only when q2's workspace requirement for them moves. `quarto-yaml` (crates.io, reached only transitively via `quarto-config`) is not one of the four but has to be bumped in `Cargo.lock` with them; see Phase 4.

If the diff shows that something outside these four crates has a downstream effect that we need to absorb (e.g., a type re-exported from a sibling crate that we depend on transitively), include it. Otherwise stay narrow.

## Phase 1: Set up

1. Read the current pinned rev from `src/rust/Cargo.toml`. There are two `rev = '...'` lines (`pampa`, `tree-sitter-qmd`) and they should match. If they don't, stop and surface the mismatch. Note the `# q2 <release>` comment above them if present (pins made before the move to releases have none).
2. Locate the q2 repo at `../q2/` (sibling of this project). If it isn't there, ask the user where it lives.
3. In `../q2/`, run `git fetch --tags --force origin` (`--force` because the `nightly` tag is rewritten on every nightly). Do not check out, reset, or modify the working tree.
4. Pick the target release from `$ARGUMENTS` as described above, then resolve its tag to a SHA with `git -C ../q2 rev-parse <tag>^{commit}`. For a prerelease, check that the short SHA in the release name matches; if it does not, the local tag is stale or the release is mid-publish, so stop and report it.
5. Describe the current pin relative to releases: `git -C ../q2 tag --points-at <pinned> 'v*'` names it if it is a release, otherwise `git -C ../q2 describe --tags --match 'v*' <pinned>` gives the nearest release (e.g. `v0.43.0-34-gd644dc95f`, an older commit pin).
6. If the target SHA equals the pinned SHA, report "already up to date" and exit. If the target is an ancestor of the pin (`git merge-base --is-ancestor <target> <pinned>`), it would be a downgrade (likely when a commit or nightly pin is ahead of the latest stable release): stop and ask whether to wait for the next release, take the prerelease instead, or downgrade.

Report:

- Current pin: release (or nearest-release description) + short SHA + author date + subject
- Target: release name + tag + short SHA + publish date
- Number of commits between them, and the stable releases crossed (`git -C ../q2 tag --merged <target> --no-merged <pinned> 'v*' --sort=version:refname`)

CHECKPOINT 1: confirm the user wants to proceed with this target release.

## Phase 2: Diff narrowing

Start with the release notes for each release crossed (`gh release view <tag> -R quarto-dev/q2 --json body --jq .body`, plus the target prerelease's notes if it is one). They summarize user-facing changes and often name the bd-/q2# ids, which makes the commit-level pass below faster to triage, but they are not a substitute for it.

For the two in-tree crates (`crates/pampa/`, `crates/tree-sitter-qmd/`):

- `git diff --stat <pinned>..<target> -- <path>` for the file overview
- `git log --oneline <pinned>..<target> -- <path>` for commit-level context

For the two crates.io crates, compare the versions q2's root `Cargo.toml` requires at `<pinned>` vs `<target>` (`git show <rev>:Cargo.toml | grep -A1 'dependencies.quarto-source-map'`, likewise `quarto-error-reporting`), and compare `quarto-yaml` via q2's `Cargo.lock` at each rev rather than the manifest (the manifest has under-declared it before). For any that moved, fetch both tarballs (`curl -sfL https://static.crates.io/crates/<name>/<name>-<ver>.crate | tar xz` into the scratchpad) and `diff -ru` their `src/` directories; that diff is the Phase 3 input for those crates.

Also do a workspace-level pass for dep edges that could ripple in:

- `git diff --stat <pinned>..<target> -- Cargo.toml crates/*/Cargo.toml`

Report per crate:

- Number of files changed
- The file list
- Notable commit subjects

Plus a separate section for any workspace `Cargo.toml` shifts worth flagging (version bumps on shared deps, new feature flags, etc.).

If no files in the four crates changed, ask the user whether to proceed anyway (they may want a pure release bump for unrelated reasons).

## Phase 3: Impact analysis

For each changed file in the four crates, determine whether it could affect q2r. The surfaces q2r actually touches:

- `src/rust/src/lib.rs`: `pampa::readers::qmd::read` signature and return shape; `pampa::writers::native::write` signature; the `output_stream: Vec<u8>` argument.
- `src/rust/src/diag_to_r.rs`: `DiagnosticMessage` fields, `SourceContext` / `SourceInfo` / `FileId` constructors and shape, `TextRenderOptions` fields, `map_offset` behavior, `to_text_with_options`.
- `src/rust/src/pd_ast_to_r.rs`: Pandoc AST types (`Block`, `Inline`, attributes, new variants).
- `src/rust/src/ts_ast_to_r.rs`: tree-sitter-qmd node kinds. Watch especially for grammar-gap promotions: any of `pandoc_math`, `pandoc_display_math`, `code_fence_content`, or the `](` lead in `target` becoming first-class named nodes. That would let us drop `@text` fallbacks (and the corresponding `to_qmd()` handlers).
- `R/to-qmd.R`: per-kind handlers in `ts_kind_handlers`. New node kinds in `grammar.js` need handlers; renamed kinds need updates.
- `R/diagnostic.R` (the `pampa_diagnostic` slots; diagnostics ride on the parsed object's `@diagnostics` slot, there is no wrapper result class): field mapping if `DiagnosticMessage` shape changed.

If the diff is large, use parallel `Agent` calls (subagent_type=Explore) with each agent assigned a specific surface above. Otherwise read the relevant diffs directly with `git show` / `git diff`.

Produce a structured impact report. For each affected q2r file:

- The upstream change (file + brief description)
- Why it matters
- What needs to change in q2r (rough sketch)
- Severity, one of:
  - Breaking: won't compile or wrong behavior
  - Opportunity: lets us simplify, e.g., grammar-gap removal
  - Watch: no action needed now but worth noting
- Coverage: yes or no. Yes whenever the change alters what `parse_qmd()`, `to_qmd()`, or `@diagnostics` return for some input, whatever the severity; Phase 8 turns every yes into a targeted test.

Call out grammar-gap obsolescence prominently if it shows up. That has follow-on cleanup in both `ts_ast_to_r.rs` and `R/to-qmd.R`.

CHECKPOINT 2: present the impact report. Ask the user to confirm the integration plan, flag anything they want to defer to a later sync, and approve proceeding.

## Phase 4: Bump the pin

1. Update both `rev = '...'` lines in `src/rust/Cargo.toml` to the target release's full SHA in a single Edit (use `replace_all`), and set the `# q2 <release>` comment above each (add it if missing) to the release tag, or to the full nightly version string for a prerelease. Update the "Current pinned commit" line in `CLAUDE.md` to the new SHA and release.
2. Refresh `Cargo.lock`: `cargo update --manifest-path src/rust/Cargo.toml`. If that pulls in more than the four target crates, narrow with `-p pampa -p tree-sitter-qmd -p quarto-source-map -p quarto-error-reporting -p quarto-yaml`. Always include `quarto-yaml`: q2's workspace manifest has under-declared its requirement (`0.1.2` while the code needed `0.1.3`), and a narrowed update that skips it leaves `quarto-config` failing to compile against the stale version.
3. Briefly report what changed in `Cargo.lock` (which crates moved, anything surprising).

## Phase 5: Rebuild and absorb breakage

Run `Rscript -e 'devtools::document()'` from the project root. This compiles the Rust side and regenerates the R bindings (`R/extendr-wrappers.R`).

If it fails, work the errors one at a time:

- Match each error to an item in the Phase 3 impact report.
- Propose the fix as an Edit with a brief explanation of why.
- For non-trivial decisions (e.g., a renamed enum variant that changes how we flatten Pandoc AST nodes to R), pause and ask the user before guessing.

After it builds clean, smoke test:

```
Rscript -e 'devtools::load_all(); print(q2r::parse_qmd("# hi"))'
```

Confirms the package loads, the basic parse path works, and diagnostic formatting still rounds through Rust without crashing.

## Phase 6: Reconcile expected-failure skip map (pre-test)

`tests/testthat/_gen-quarto-web.R` defines `QUARTO_WEB_SKIP`, a per-suite map keyed by quarto-web relative path. Each entry's reason has the form `"q2#NNN (short description)"`, marking a fixture as expected-failure pending the named upstream issue. Before running the suite, reconcile this map against current q2 issue state so a closed upstream issue stops hiding its fixtures.

1. Extract all `q2#NNN` references currently in the skip map:

   ```
   grep -oE 'q2#[0-9]+' tests/testthat/_gen-quarto-web.R | sort -u
   ```

2. Query each issue's state in one batch:

   ```
   gh issue list --repo quarto-dev/q2 --state all --limit 500 --json number,state,title
   ```

   Cross-reference the numbers from step 1 against the result. Note any whose `state` is `CLOSED`.

3. For each closed issue, identify the skip-map entries referencing it (`grep -n "q2#NNN" tests/testthat/_gen-quarto-web.R`) and report them to the user before editing.

4. With user go-ahead, remove those entries from `QUARTO_WEB_SKIP` in a single Edit. The auto-regeneration in `helper-quarto-web.R` will pick this up via the `tests/testthat/_gen-quarto-web.R` mtime change when Phase 7 runs the suite — no manual regeneration needed.

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

- Header: `## <YYYY-MM-DD>: <old-release> (<old-short-sha>) → <new-release> (<new-short-sha>)`, using the nearest-release description for an old commit pin and the nightly version string for a prerelease
- Total failure count
- Failure-mode groups with counts
- Per-fixture failure list (path + line ref + one-line failure-mode tag), sorted alphabetically, so future diffs are stable
- Diff vs. the prior section: New / Resolved / Unchanged counts (omit on the first run)

Keep the file terse — it's a state log, not a narrative. When older sections become uninformative (more than ~5 syncs back, or older than the current pinned rev minus a few), they can be pruned, but do not prune in the same run that added the new section.

For each failure-mode group decide whether it is:

- An absorption gap (we missed updating something on our side): fix it, then re-run only the failing test files (not the full suite) to verify.
- A genuine upstream behavior change (snapshots / golden output need to move): get explicit user sign-off before updating snapshots.
- An upstream bug we should defer behind a skip — handled by the next step.

If grammar-gap cleanup was on the table in Phase 3 and the user approved it, this is the place to rip out the corresponding `@text` paths in `ts_ast_to_r.rs` and the matching handlers in `R/to-qmd.R`, then re-run only the round-trip files to confirm functional equivalence still holds.

### Classify new failures against open q2 issues

For each new failure that the user wants deferred (i.e. it isn't an absorption gap and isn't a snapshot move):

1. Try to match the failure mode + repro to an open q2 issue:
   - Search by keyword: `gh issue list --repo quarto-dev/q2 --state open --search "<short failure-mode phrase>" --limit 20 --json number,title`
   - Also scan filed drafts under `notes/done/*.md` — they often capture exactly the failure mode and may already cite the upstream number in their text.
2. If a match is found, add an entry to the relevant suite map in `QUARTO_WEB_SKIP` (usually `pampa_pd_rt`) tagged `"q2#NNN (short description)"`. After all entries are added, re-run the affected suite once via `--filter` to confirm the new skips fire cleanly.
3. If no match is found, surface the failure to the user. Decide together: file a new q2 issue (drafts in `notes/done/` are good starting material), tag the skip preemptively with the new number, or leave the test failing until an issue exists.

Pre-test removals from Phase 6 also feed into this step. If a previously-skipped fixture reappears as a failure here (i.e. the upstream issue closed without the underlying behavior actually being fixed), surface it to the user — the upstream issue likely needs to be re-opened, or a follow-up filed.

CHECKPOINT 3: present the test results (grouped by failure mode, with the New/Resolved/Unchanged diff vs. the prior `notes/q2-sync-notes.md` entry, and the list of skip-map edits — both removals from Phase 6 and additions from this step). If anything is failing or any snapshot moved, get sign-off before continuing.

## Phase 8: Cover absorbed behavior changes

Every Phase 3 item marked `Coverage: yes` needs a targeted test, even when the quarto-web sweeps pass. The sweeps only prove round-trip stability on fixtures that happen to contain the construct, and a later upstream regression would otherwise surface as an unexplained sweep failure with no test naming the behavior. Precedent: `tests/testthat/test-task-list.R` (65a888b0) and `test-html-block-lift.R` / `test-fenced-div-tight.R` / `test-shortcode-separator.R` / `test-doubled-brace.R` (914f2069).

1. One file per behavior, `tests/testthat/test-<behavior>.R`, opened with a short comment naming the upstream commit (plus its bd-/q2# id) and what moved. Take the smallest inputs from the upstream integration test or from the Phase 5 smoke test.
2. Assert the shape, not just "it parses": AST class and slot values on the pd path (and ts kinds where the grammar moved), diagnostic `@code` / `@kind` / hint text where a diagnostic changed, and `to_qmd()` output where the writer changed. Finish with a round trip (`expect_pd_ast_equal`; on the ts path `expect_ts_ast_equal` plus byte identity).
3. Include the negative neighbour that keeps the change narrow (an inline tag that must not be lifted, a colon run that must stay in a paragraph, a correctly spaced shortcode that must not warn).
4. Do not touch `NEWS.md`. It tracks high-level feature changes only, with at most one `## Upstream` bullet per release naming the pinned q2 rev and subcrate versions; that line is refreshed at release time, not per bump. Per-bump detail belongs in `notes/q2-sync-notes.md` and the targeted tests.
5. Run only the new files (`devtools::test(filter = "...")`), then list them in the current `notes/q2-sync-notes.md` section.

Skip this phase only for a pure release bump (Phase 3 found nothing on a linked surface).

## Phase 9: Wrap up

Summarize:

- Old release + SHA -> new release + SHA
- Files in q2r that changed, one line each, with why
- Tests added for absorbed behavior changes (Phase 8), one line each with what they pin; say explicitly if none were needed
- Opportunities deferred (e.g., grammar-gap cleanup we noted but did not take)
- Follow-ups: any TODO updates needed in `CLAUDE.md` (the Known risks / TODO sections), or any new memory worth recording about a behavior change.

Do not commit. Leave that to the user.
