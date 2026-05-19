# HexmosTech/git-lrc

- URL: https://github.com/HexmosTech/git-lrc
- Category: error-prevention
- Stars snapshot: 919 (GitHub REST API repository search, captured 2026-05-11 in `research/index.md`)
- Reviewed commit: 292398a73534326482c99da4f0049199c5d534e4
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for commit-time AI review gates, review attestations, and human decision capture around staged diffs. The useful Agentic Coding Lab patterns are git-native trigger points, narrow diff bundles, review/vouch/skip audit trails, iteration coverage, first-valid-decision arbitration, and explicit storage/network boundaries. It should not be copied as a full review engine because prompt construction and model-side sanitization live in the external LiveReview service, and some docs/behavior around skip/blocking are inconsistent.

## Why It Matters

`git-lrc` attacks a concrete AI-coding failure mode: agents can silently delete logic, weaken checks, or introduce insecure changes, and the developer may not notice before committing. Instead of adding another chat workflow, it sits on `git commit` and makes review status part of the commit path.

For Agentic Coding Lab, this is valuable because it treats git as the universal integration layer. The tool does not need IDE-specific support, agent-specific protocol hooks, or repository conventions beyond staged diffs and hooks. It also records whether a change was reviewed, vouched for, or skipped, which turns "I think the agent checked it" into local evidence that can appear in `git log`.

## What It Is

`git-lrc` is a Go CLI and git-hook integration for submitting local diffs to the LiveReview API for AI code review. It can run as `lrc`, `lrc review`, or `git lrc review`, and its installer can place global hook dispatchers so every repository gets the same review gate.

Core pieces:

- CLI wiring with `urfave/cli` for review, setup, UI, hooks, self-update, usage inspection, cleanup, and attestation trailer commands.
- Diff collection from staged changes, working tree, explicit git range, specific commit/range, or diff file.
- Review submission as a zip containing `diff.txt`, base64 encoded into a fixed JSON payload.
- Polling and event proxying against LiveReview review endpoints.
- Browser UI and terminal UI for inline comments, progress events, commit message editing, commit/commit-and-push/abort decisions, and skip/vouch options during review.
- Hook scripts for `pre-commit`, `prepare-commit-msg`, `commit-msg`, and `post-commit`.
- Local attestation JSON files and SQLite review-session tracking under `.git/lrc`.
- Setup and connector management for LiveReview auth plus BYOK providers such as Gemini, OpenAI, Claude, DeepSeek, and OpenRouter.
- Fake review mode and simulator tests for deterministic review-flow testing without model calls.

## Research Themes

- Token efficiency: Strong at the CLI boundary. It sends the selected diff only, not the full repository, and optionally saves the exact transmitted bundle for inspection. Token use after submission is controlled by the LiveReview backend, not this repo.
- Context control: Strong for source selection, weak for model prompt control. The local tool explicitly chooses staged/working/range/commit/file diff sources, but it does not construct the code-review prompt or select prompt context beyond `diff.txt`.
- Sub-agent / multi-agent: Limited. The notable agent handoff is a Claude Code action that writes selected findings to `.git/lrc/reviews/<review-id>/review_findings.json` and launches `claude` with a remediation prompt.
- Domain-specific workflow: Strong. The workflow is specifically git commit review: staged diff capture, web/terminal review, commit message sync, safe push, and commit trailer evidence.
- Error prevention: Strong. It prevents unreviewed non-interactive commits when attestation is missing, catches large diff submission failures, surfaces authentication/quota/polling failures, and makes skip/vouch explicit rather than silent.
- Self-learning / memory: Moderate. Local review-session DB tracks branch, tree hash, action, hunks, review id, and iteration coverage, but it is session/audit memory rather than autonomous learning.
- Popular skills: Not a skill-pack repo. Reusable practices are git-hook dispatching, review attestation, coverage tracking, local UI decision arbitration, storage/network boundary inventories, and fake review simulation.

## Core Execution Path

The default command path starts in `main.go`, which configures version/update state and builds the CLI app in `cmd/app.go`. The app default action and `review` subcommand build `reviewopts.Options` and call `appcore.RunReviewWithOptions()`.

`reviewopts.BuildFromContext()` normalizes flags and environment variables. `--diff-file` forces file mode, `--commit` forces historical commit mode and disables precommit/skip, `--range` selects range mode, `--staged` selects staged mode, and the fallback is staged diff. `--skip` and `--vouch` bypass the AI review path and force non-precommit behavior.

`runReviewWithOptions()` handles short-circuit decisions first. `--skip` best-effort collects/parses the diff, records coverage, writes a skipped attestation, and exits. `--vouch` requires non-empty diff content, parses it, records coverage, writes a vouched attestation, and exits. Normal review mode resolves `.git`, clears any pending commit message for precommit mode, refuses to rerun when an attestation already exists unless `--force` is used, loads config from `~/.lrc.toml` or flags/env, and derives the repo name.

Diff collection is deterministic and simple: staged mode runs `git diff --staged`, working mode runs `git diff`, range mode runs `git diff <range>`, commit range mode runs `git diff <range>`, single commit mode runs `git show --format= <commit>`, and file mode reads a supplied diff file. Empty diff is an error.

The collected diff is zipped as `diff.txt`, base64 encoded, and sent to `POST /api/v1/diff-review` as `{diff_zip_base64, repo_name}` with `X-API-Key`. The CLI then starts a local web server unless explicitly producing non-interactive output. The browser UI initially displays parsed diff hunks before model comments arrive, polls/proxies `/api/v1/diff-review/<id>/events`, streams external comments into files, and fetches final review data when status becomes completed or failed.

In interactive precommit mode, terminal and web decisions race through `decisionruntime.Runtime`. During review, abort, skip, and vouch are accepted. After review completion, commit and handoff are the primary accepted actions, with a grace/compatibility path allowing late skip/vouch decisions. The first valid decision wins. Commit decisions persist commit-message and push-request marker files for downstream hooks, while non-hook `lrc review` can run `git commit` and optional guarded push directly.

The hook path uses global or repo-local dispatchers. `prepare-commit-msg` is the primary interactive trigger: in a TTY it runs `lrc review --staged --precommit`, passes any initial commit message through an env-file, and maps the returned decision code into commit continuation or abort. `pre-commit`, `prepare-commit-msg`, and `commit-msg` block non-interactive commits when no attestation exists for the staged tree hash. `commit-msg` appends the attestation-derived `LiveReview Pre-Commit Check: ...` trailer. `post-commit` deletes the attestation for the committed tree, cleans branch review sessions, and performs a guarded push only when the push marker was set.

## Architecture

- `main.go` and `cmd/app.go`: CLI surface, flags, subcommands, version wiring, and injected handler boundaries.
- `internal/reviewopts`: option construction, defaults, diff-source selection, and default HTML/serve behavior.
- `internal/appcore/review_runtime.go`: main review orchestration, diff collection, submission, polling, local server, progressive UI state, output files, rendering, commit/push, and error handling.
- `internal/reviewapi`: git command wrapper, git-dir resolution, current tree hash, zip creation, API submit/poll wrappers, telemetry, and JSON parse diagnostics.
- `network`: outbound HTTP boundary for review, setup/auth/connectors, UI forwarding, and self-update downloads.
- `storage`: local persistence boundary for config, hooks, attestation files, review DB, temp HTML, update state, uninstall cleanup, and SQL wrappers.
- `hooks` and `internal/appcore/hooks_management.go`: hook templates, dispatcher generation, install/uninstall, backups, global `core.hooksPath`, local hook resolution, enable/disable/status.
- `internal/appcore/attestation_flow.go`, `attestation`, and `internal/reviewdb`: attestation files, trailer formatting, SQLite review sessions, branch-local iteration counts, and prior AI coverage calculation.
- `internal/decisionflow`, `internal/appcore/decisionruntime`, `interactive`, and `internal/ctrlkey`: phase rules, first-valid-decision arbitration, keyboard bindings, terminal UI, and signal handling.
- `internal/staticserve`, `internal/reviewhtml`, `result`, and `internal/staticserve/static/**`: embedded browser UI, diff/comment rendering, event polling, copy issue, severity filtering, and precommit action bar.
- `setup`, `internal/appui`, `ui`, and `config`: guided auth, API key provisioning, Gemini connector setup, re-auth, connector CRUD/reorder/proxy, and managed connector snapshots in config.
- `review`, fake-review build wiring, `internal/simulator`, and tests: deterministic fake review results/events and scenario coverage for race-sensitive flows.
- `internal/selfupdate`: auto-update check, update locks, manifest/binary download, checksum verification, pending update state, and apply-on-exit behavior.

## Design Choices

The most important design choice is using git as the enforcement point. The project does not try to integrate with each AI coding tool; it catches the artifact those tools ultimately produce: a staged diff.

Review input is intentionally narrow. The CLI sends a zip with only the selected diff. It does not upload full repository context locally, and `--save-bundle` writes the raw diff, zip size, and transmitted base64 for audit.

Attestation is tied to `git write-tree`. The review, vouch, or skip decision creates `.git/lrc/attestations/<tree-hash>.json`, so later hook stages can check the exact staged snapshot rather than trusting process state.

Review evidence has two layers. Attestation files support the immediate commit gate and trailer generation; `.git/lrc/reviews.db` supports iteration count and prior coverage across review cycles on the same branch.

The UI and terminal are peers. Both can make decisions, both synchronize a draft commit message, and `decisionruntime` avoids double execution with first-valid-decision-wins semantics.

The project accepts explicit escape hatches. Users can skip, vouch, disable hooks for one repo, run with `--force`, or bypass git hooks with normal git mechanisms. The key is that many escapes become visible through trailers or explicit markers rather than disappearing.

Storage and network are treated as auditable boundaries. The repo has dedicated `storage/*` and `network/*` packages plus status documents and architecture tests intended to make data-at-rest and data-in-transit review easier.

Model/provider concerns are backend-owned. Setup can validate/create connectors and the UI can reorder BYOK providers, but local prompt assembly, model calls, and LLM input/output sanitization are delegated to LiveReview.

## Strengths

Git-native enforcement is practical. A global hook dispatcher can cover many repositories and existing editor/agent workflows without each tool opting in.

The staged tree attestation model is stronger than a loose "review ran recently" flag. It binds the decision to the exact tree hash that later hook stages inspect.

Review/vouch/skip are separate actions. This is a good pattern for agent workflows because "AI reviewed", "human accepts responsibility", and "not reviewed" have different meaning and should not collapse into one boolean.

Coverage tracking turns iterative repair into measurable evidence. The tool can say how many review cycles occurred and what percentage of the current diff was already covered by prior AI-reviewed hunks.

Failure handling is user-oriented. Missing API key, malformed endpoint returning HTML, 401 auth failure, invalid LiveReview API key recovery, 403/429 quota blocks, 413 large diff, timeout, failed review, and duplicate attestations all get specific paths instead of one generic error.

Progressive UI is well matched to review latency. Users can see the diff immediately, then comments/events stream in while terminal decisions remain available.

Hook chaining respects existing local hooks. The dispatcher runs the managed LRC hook first and then the repo-local hook, preserving existing hook workflows unless LRC blocks.

Tests cover nontrivial race and UX behavior: decision phase gates, first-valid-decision wins, fake review polling/cancellation, streamed comments, UI state, auth recovery, hook section replacement, connector secret redaction, setup flags, and simulator cases.

Fake review mode is an excellent development pattern. It makes end-to-end review UI and decision behavior testable without depending on AI services, accounts, quota, or browser/manual timing.

Security and procurement evidence is unusually concrete for a small CLI. `SECURITY.md`, `storage/storage_status.md`, and `network/network_status.md` enumerate payloads, risks, controls, and known gaps.

## Weaknesses

The actual AI review engine is outside this repo. Local code does not show the system prompt, batching strategy, model selection logic, sanitization, or LLM output validation. This limits how much can be copied for prompt-level error prevention.

The CLI trusts backend comments and summaries structurally. It normalizes severity/category/line fields and renders Markdown/UI output, but deep response sanitization is documented as LiveReview-service responsibility.

Docs and behavior diverge in places. `docs/LRC_README.md` says hooks never block commits, while current hook scripts block non-interactive commits without attestation. README language around "Skip" also conflicts between "abort the commit" and "commit without review" semantics.

The diff parser is deliberately simple. It parses `diff --git` headers and hunk ranges with regex/string splitting. That is adequate for display and coverage in common unified diffs, but fragile around unusual filenames, binary diffs, renames, mode-only changes, and advanced git patch metadata.

Coverage is approximate. It counts new-side hunk ranges and uses tree diffs to infer unchanged prior-reviewed lines, but it does not prove semantic equivalence or line movement correctness.

Some safety boundaries are aspirational or leaky. The architecture test intends file/network operations to stay in `storage` and `network`, but there are direct `os.WriteFile`/`os.MkdirAll` style uses in higher-level paths such as Claude handoff and temp review directories.

Provider keys can be persisted locally in `~/.lrc.toml` through connector snapshots. Files are written with `0600`, but this is still sensitive local secret material that an agentic lab should treat as out-of-scope for normal coding-agent reads.

The local browser server binds broadly on non-Windows in the reviewed path (`:%d`), while it carries API-key-backed event proxy behavior. It is local-workstation UX, but stricter loopback binding would be a safer default.

Self-update adds supply-chain complexity. It has host validation, locks, staged state, and checksum verification, but any auto-update path in a commit-time tool increases the trusted computing base.

## Ideas To Steal

Use git staged-tree hash as the review evidence key. Agentic Coding Lab can bind "agent reviewed", "tests passed", or "human approved" to the exact tree hash before commit.

Separate `reviewed`, `vouched`, and `skipped` states. Do not model safety as a boolean; record who or what accepted responsibility and whether an AI review actually ran.

Add a commit trailer for agent-safety evidence. A standardized trailer such as `Agentic Check: ran (iter:N, coverage:X%)` would make later audits and PR review easier.

Make non-interactive paths stricter than interactive paths. Humans can decide in a UI; CI, editor integrations, and headless commits should fail closed unless a matching attestation exists.

Keep review input inspectable. A `--save-bundle` equivalent for any agent feedback loop lets users see exactly what context leaves the workspace.

Use progressive local UI with terminal fallback. Long-running review or verification can show immediate artifacts, stream logs/comments, and still allow keyboard decisions without waiting for the browser.

Model decisions as a small runtime with phase gates and first-valid-decision wins. This avoids duplicate commits, stale button clicks, and signal/web/terminal races.

Track iteration coverage across repair loops. Even an approximate measure helps distinguish "reviewed then changed again" from "reviewed and only lightly adjusted".

Build fake-review mode first-class. Deterministic fake comments/events let UI, hooks, handoff, and race behavior be tested without paid APIs or nondeterministic model output.

Maintain explicit storage and network inventories. Agent systems benefit from a readable list of where code is persisted, what leaves the machine, which secrets are involved, and what compensating controls exist.

Preserve existing user hooks by installing a dispatcher and chaining. A lab-wide hook should coexist with repo hooks rather than overwrite them silently.

## Do Not Copy

Do not delegate the prompt and output contract to an opaque service if the lab needs reproducible safety behavior. Keep prompts, schemas, sanitizer rules, and model-output contracts in reviewed source or pinned artifacts.

Do not rely on LLM review as a hard correctness guarantee. Treat it as advisory and still require deterministic tests, typechecks, linting, secret scans, and policy checks.

Do not store provider API keys in files that coding agents can freely read. If connector snapshots are needed, isolate them from normal workspace context and redact aggressively in logs.

Do not expose API-key-backed local proxy endpoints beyond loopback. A browser UI server for review events should bind narrowly by default.

Do not let skip semantics become ambiguous. If skip means "commit without review", name and document it that way; if it means "abort and fix", make it a separate abort action.

Do not use simple regex diff parsing for high-stakes patch correctness. Use a proper patch parser or git plumbing when filenames, renames, binary files, and mode changes matter.

Do not hide important controls in global git state without a clear status command and uninstall/restore path. `core.hooksPath` changes are powerful and must be visible.

Do not let auto-update mutate a security gate without strong operator policy. Checksum verification is necessary, but teams may still need pinned versions.

## Fit For Agentic Coding Lab

Fit is high for `error-prevention`. `git-lrc` is not a general agent framework, but it is a strong example of a practical review gate that catches agent-written code at the commit boundary and records evidence.

Best adaptations:

- A local "agent safety attestation" keyed by staged tree hash.
- A hook-based gate that blocks headless commits unless review/test/policy evidence exists.
- A review iteration database that tracks what changed after prior agent review.
- A web/terminal decision runtime for long-running verification with safe race handling.
- A fake backend for deterministic E2E testing of review UX and hook side effects.
- Storage/network boundary documentation for any tool that reads secrets, writes git state, or sends code externally.

The main caution is that Agentic Coding Lab should own more of the deterministic contract than this CLI does. `git-lrc` is excellent at orchestration, evidence, and developer ergonomics, but model prompting and model-response validation are mostly backend concerns outside the reviewed repo.

## Reviewed Paths

- `README.md`: product positioning, setup, review/vouch/skip workflow, commit trailers, BYOK connectors, data-sent claims, quick reference, and license/team context.
- `docs/LRC_README.md`, `docs/lrc_cases.md`, `docs/internal_install.md`, and selected `docs/releases/*.md`: CLI behavior, diff sources, troubleshooting, case notes, and release evolution.
- `SECURITY.md`, `storage/storage_status.md`, and `network/network_status.md`: security model, storage/network inventories, risk acknowledgements, and documented limits.
- `go.mod`, `Makefile`, `main.go`, and `cmd/app.go`: dependencies, build/test targets, fake-review build, CLI commands, flags, and handler wiring.
- `internal/reviewopts/options.go`: option normalization, source selection, skip/vouch/precommit interactions, timeout defaults, and HTML serve defaults.
- `internal/appcore/review_runtime.go`: primary review flow, diff collection, zip/base64 bundle creation, submit/poll, progressive server, UI endpoints, decision routing, commit/push, output formats, and major failure paths.
- `internal/appcore/bridge.go`, `review/fake_mode.go`, and `scripts/fake_review.sh`: fake review mode, synthetic comments/events, fake E2E scenario setup, and local dev workflow.
- `internal/reviewapi/helpers.go`, `internal/reviewmodel/types.go`, `network/*.go`: git helpers, API request/response models, HTTP clients, review/setup/connector/update endpoints, redirect policy, proxying, and telemetry.
- `storage/*.go`: config, hook, attestation, review input, SQLite, temp file, self-update state, and cleanup persistence wrappers.
- `setup/*.go`, `internal/appui/setup*.go`, `internal/appui/ui_connectors*.go`, `ui/*.go`, and `config/ai_connectors.go`: guided login, API key provisioning, Gemini setup, config writes, re-auth, connector CRUD/reorder/validation proxy, and local connector snapshots.
- `hooks/*.sh`, `hooks/*.go`, `gitops/config.go`, and `internal/appcore/hooks_management.go`: hook templates, managed section replacement, global/local install, dispatcher chaining, enable/disable/status, backups, and git config changes.
- `internal/appcore/attestation_flow.go`, `attestation/*.go`, `internal/reviewdb/service.go`, and `storage/attestation_review_db_io.go`: attestation JSON, commit trailer output, review DB schema, branch cleanup, coverage computation, and SQLite controls.
- `internal/decisionflow`, `internal/appcore/decisionruntime`, `internal/appcore/interactive_decision.go`, `internal/appcore/interactive_tui.go`, `interactive/**`, and `internal/ctrlkey/**`: phase gates, first-valid-decision runtime, keyboard controls, terminal UI, draft sync, and action execution.
- `internal/reviewhtml/template.go`, `result/types.go`, `internal/staticserve/static/app.js`, selected `internal/staticserve/static/components/*.js`, and selected `*.mjs` state modules: result shape, diff/comment rendering, event streaming, all-clear outcome, precommit action bar, copy issue, and UI state handling.
- `internal/selfupdate/*.go` and `network/selfupdate*.go`: auto-update hooks in review flow, manifest/download endpoints, trusted host checks, lock/state files, checksum verification, and failure handling.
- `internal/simulator/**`, `cmd/app_test.go`, `setup/*_test.go`, `hooks/*_test.go`, `internal/appcore/*_test.go`, `internal/staticserve/static/components/*_test.mjs`, `storage/*_test.go`, `configpath/*_test.go`, and `internal/architecture/boundary_enforcement_test.go`: behavior coverage for review decisions, fake mode, hooks, auth recovery, UI state, storage, path handling, and architecture boundaries.

## Excluded Paths

- `gfx/**`, videos, GIFs, screenshots, SVG badges, and image-heavy README assets: presentation/media assets, not review execution or error-prevention logic.
- `internal/staticserve/static/vendor/**`, `preact-bootstrap.js`, and vendored/minified browser libraries: third-party UI runtime dependencies; reviewed local UI code that consumes them instead.
- Most CSS and markup-only static files such as `internal/staticserve/static/styles.css`, `css/slideshow.css`, `index.html`, `ui-connectors.html`, and static demo HTML snapshots: useful for UI appearance but not core review/control behavior.
- Most connector-manager frontend page/component files under `internal/staticserve/static/ui-connectors/**`: UI-only management screens; backend connector setup/proxy/config paths were reviewed for behavior.
- `readme/README.*.md`: translated copies of the main README; main `README.md` was reviewed as canonical documentation.
- Release packaging, B2 upload/audit, SBOM generation, and maintenance scripts under `scripts/` except `fake_review.sh`: operational release plumbing, not commit-time review execution.
- `.github/workflows/**`: CI/security workflow definitions were noted through `SECURITY.md` and directory listing, but workflow YAML internals were not central to the local execution path.
- `go.sum`, generated dependency lock data, and binary/test media artifacts: dependency metadata or non-source data, not design logic.
- `.git/**` in the external checkout and any local runtime files that would be created under `.git/lrc/**`: repository metadata or runtime artifacts, not source.
- Unvendored LiveReview backend code referenced from docs: prompt construction, model execution, and deep LLM sanitization are outside this repository and were treated as external dependencies.
