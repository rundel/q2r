---
description: Sync the quarto-web fixtures submodule with upstream while replaying the local q2r-corrections branch on top
allowed-tools: [Bash, Read, Edit, Write, Agent]
---

Bring the `tests/fixtures/quarto-web` submodule up to date with upstream `origin/main` and replay the local-only `q2r-corrections` branch on top. Upstream always wins — corrections that cannot replay cleanly are dropped and surfaced to the user as separate re-fix work.

Scope: this skill never touches the parent q2r repo's recorded submodule SHA, never pushes inside the submodule, and never overwrites upstream changes with old corrections. It only manages the local `q2r-corrections` branch and the `R/tests.R` `QUARTO_WEB_SKIP` map.

## Phase 1: Setup and report

1. Confirm the submodule is checked out and on `q2r-corrections`:
   - `git -C tests/fixtures/quarto-web rev-parse --abbrev-ref HEAD` should be `q2r-corrections`.
   - If the branch does not exist, create it from `origin/main` and tell the user there are no corrections yet (subsequent phases become no-ops).
2. Fetch upstream (no tags, no working-tree changes):
   - `git -C tests/fixtures/quarto-web fetch origin --no-tags`
3. Resolve the relevant SHAs (call from the project root):
   - `old-upstream` = `git -C tests/fixtures/quarto-web merge-base q2r-corrections origin/main` — the commit that corrections currently sits on top of.
   - `new-upstream` = `git -C tests/fixtures/quarto-web rev-parse origin/main` — the post-fetch upstream tip.
4. If `old-upstream == new-upstream`, report "already up to date" and exit.
5. Report:
   - `old-upstream` short SHA, date, subject
   - `new-upstream` short SHA, date, subject
   - Number of upstream commits between them: `git -C tests/fixtures/quarto-web rev-list --count old-upstream..new-upstream`
   - The current correction-commit list relative to `old-upstream`: `git -C tests/fixtures/quarto-web log --oneline old-upstream..q2r-corrections`

## Phase 2: Conflict prediction (dry run)

1. Files changed upstream: `git -C tests/fixtures/quarto-web diff --name-only <old-upstream>..<new-upstream>`
2. For each correction commit `C` in `old-upstream..q2r-corrections`, get its file list: `git -C tests/fixtures/quarto-web show --name-only --pretty=format: C`
3. Group correction commits into:
   - "should replay cleanly" — no overlap with upstream-changed files
   - "may conflict" — at least one file overlaps with upstream-changed files
4. Print both groups so the user knows what is at risk before any history rewrite.

## Phase 3: Replay correction commits onto new upstream

The user has authorized this strategy: upstream wins, corrections that conflict are dropped and re-applied as separate explicit steps.

1. Create a safety ref so dropped commits remain recoverable:
   - `git -C tests/fixtures/quarto-web branch q2r-corrections-pre-sync-$(date +%Y%m%d-%H%M%S) q2r-corrections`
2. Snapshot the original correction-commit SHAs (the output of `git log --pretty=%H <old-upstream>..q2r-corrections` in oldest-first order) before any reset.
3. Hard-reset `q2r-corrections` to the new upstream:
   - `git -C tests/fixtures/quarto-web checkout q2r-corrections`
   - `git -C tests/fixtures/quarto-web reset --hard <new-upstream>`
4. Walk the snapshot in oldest-first order. For each commit `C`:
   - `git -C tests/fixtures/quarto-web cherry-pick C`
   - On success: record as "replayed cleanly".
   - On conflict: `git -C tests/fixtures/quarto-web cherry-pick --abort`, record as "dropped — needs manual re-fix", and continue with the next commit. Do **not** attempt automatic resolution.
5. After the loop, `q2r-corrections` is `new-upstream` + every correction that replayed cleanly. Dropped correction SHAs remain reachable through the safety ref.

## Phase 4: Report and re-fix loop

1. Report:
   - Number of corrections replayed cleanly
   - Number dropped, with file path, original commit subject, and the upstream commit (short SHA + subject) that touched the same file (use `git log --oneline -n1 <old-upstream>..<new-upstream> -- <path>` to find it)
   - The safety ref name
2. For each dropped correction, walk the user through:
   - Show the previous corrected text: `git -C tests/fixtures/quarto-web show <safety-ref>:<path>`
   - Show the new upstream text: `cat tests/fixtures/quarto-web/<path>`
   - Ask whether the original issue still exists in the new upstream:
     - If yes → re-apply the fix as a fresh commit on `q2r-corrections` using the standard message format `fix(qmd): <path> — <category>`
     - If no (upstream fixed it independently) → also remove the matching row(s) from every suite in `QUARTO_WEB_SKIP` in [R/tests.R](R/tests.R) so the test starts running.
3. Skip-map reconciliation against current q2 issue state (same idea as `/q2-sync` Phase 6):
   - Extract referenced numbers: `grep -oE 'q2#[0-9]+' R/tests.R | sort -u`
   - Look up state: `gh issue list --repo quarto-dev/q2 --state all --limit 500 --json number,state,title`
   - For any closed issue, surface the matching skip rows to the user before editing. Remove them only with go-ahead.

## Phase 5: Verify

1. From the project root, run the quarto-web sweep with the failure cap raised, redirected to a temp file (the summary reporter caps at 10 failures by default in non-interactive mode):

   ```
   Rscript -e 'options(testthat.summary.max_reports = Inf); devtools::test(filter = "quarto-web", reporter = "summary")' > /tmp/qw-sync-test.log 2>&1
   ```

2. Read the result and report:
   - Total failures vs the previous run
   - Newly passing fixtures (a removed skip whose fixture now passes)
   - Newly failing fixtures (most likely a corrected fixture that an upstream change broke — these become new entries on the re-fix list).

## Phase 6: Wrap up

- Print the final corrections set: `git -C tests/fixtures/quarto-web log --oneline origin/main..q2r-corrections`
- Tell the user the safety ref is left in place and can be deleted manually once they're satisfied.
- Remind the user that this skill makes no commits in the parent q2r repo — any `R/tests.R` edits are uncommitted working-tree changes for them to review.
- The parent repo's recorded submodule SHA is unchanged. Bumping it is a separate decision (it requires the gitlink advance to match what other contributors / CI will see — out of scope for this skill).
