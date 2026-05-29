# OthmanAdi/planning-with-files

- URL: https://github.com/OthmanAdi/planning-with-files
- Category: skills-instructions
- Stars snapshot: 22,303 (GitHub REST API repository search in `research/index.md`, captured 2026-05-29; repository page showed 22.3k during review)
- Reviewed commit: 6f94643bd2b77dad9ac30b68ace14a536e2e5619
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for durable file-backed planning and hook-assisted task state. Best reusable pieces are the three-file state model, active-plan resolver, attestation gate, compaction/loop integration, and regression tests for adapter drift. Do not copy the whole multi-IDE packaging surface; adapt the planning contract and verification pieces into a narrower Agentic Coding Lab workflow.

## Why It Matters

`planning-with-files` is one of the clearest examples of turning a simple agent instruction into a persistent workflow system. It starts with a small rule: complex tasks must create `task_plan.md`, `findings.md`, and `progress.md`. Then it adds host hooks, resolver scripts, slash commands, attestation, session recovery, and parity tests so the rule survives long sessions, compaction, multiple terminals, and platform-specific agent clients.

For Agentic Coding Lab, the repo is useful because it focuses on a problem every coding-agent harness hits: ephemeral model context is not a reliable task state store. The project treats Markdown files as the durable source of truth, then uses hooks to repeatedly re-surface only the active slice of state. That is directly relevant to research notes, long-running implementation plans, agent handoffs, and verification logs.

## What It Is

The repository is a Claude Code plugin and Agent Skills package for persistent planning. The canonical skill lives at `skills/planning-with-files/SKILL.md`, version `2.43.0`. It instructs agents to create and maintain three Markdown files in the project, not in the skill directory:

- `task_plan.md`: goal, current phase, phase statuses, decisions, and errors.
- `findings.md`: research findings, discoveries, resources, and external content captured as text.
- `progress.md`: chronological session log, test results, files changed, and reboot summary.

The project also ships helper scripts, templates, command prompts, platform adapters, docs, tests, and plugin manifests. Enhanced adapters exist for Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot hooks, Mastra Code, Hermes, CodeBuddy, FactoryAI Droid, OpenCode, Kiro, and Pi Agent, with additional standard Agent Skills install paths for other clients. The implementation is mostly Markdown, shell, Python, PowerShell, TypeScript for the Pi extension, and tests.

This is not an autonomous planner runtime. The host agent still executes the workflow. The repo improves reliability by making plan state durable and by using hooks to keep that state near the model's attention window.

## Research Themes

- Token efficiency: Moderate to strong. It deliberately stores task state on disk and injects only the first 30-50 plan lines plus recent progress tails. v2.40 normalizes timestamps in injected progress to preserve KV-cache prefixes. The documented evals show better workflow fidelity at the cost of about 68% more tokens and 17% more time in the benchmark tasks, so the gain is reliability rather than raw token reduction.
- Context control: Strong. The workflow separates goal/phase state, research findings, and execution logs. Hooks re-read active plan context on user prompts and before tool use; PreCompact reminds the agent to flush in-memory state before compaction.
- Sub-agent / multi-agent: Conditional. The repo does not implement subagents directly, but slug-mode creates isolated `.planning/<plan-id>/` directories and `PLAN_ID` pinning for concurrent tasks or sessions. Reference docs discuss Manus-style planner/executor separation as design inspiration.
- Domain-specific workflow: Strong for coding-agent process, not domain-specific application code. It is best for multi-step implementation, debugging, research, migration, and long-running operational work.
- Error prevention: Strong. The skill requires error logging, a 3-strike protocol, never repeating identical failed actions, Stop hook completion checks, and opt-in SHA-256 plan attestation to block silent plan tampering from entering model context.
- Self-learning / memory: Moderate. There is no semantic memory engine, but `task_plan.md`, `findings.md`, `progress.md`, topic handoffs, session-catchup reports, and error tables create practical durable memory.
- Popular skills: The canonical `planning-with-files` skill is the core artifact. Important companion commands are `/plan`, `/plan-attest`, `/plan-goal`, `/plan-loop`, and `/plan-status`/`status` variants, depending on install route.

## Core Execution Path

The default path begins when the user invokes `/plan`, `/planning-with-files:start`, or the `planning-with-files` skill. The command asks the host agent to invoke the skill, create the three files in the current project if absent, and guide the user through the workflow. Manual users can run `scripts/init-session.sh`, which creates root-level files in legacy mode or `.planning/YYYY-MM-DD-<slug>/` files in slug mode when given a task name or `--plan-dir`.

Once files exist, the loop is:

1. Read existing planning files before work starts or after a resumed session.
2. Fill `task_plan.md` with a clear goal and 3-7 phases using `**Status:** pending|in_progress|complete`.
3. Write discoveries, browser/search/PDF/image findings, decisions, and resources to `findings.md`, especially after every two view/browser/search operations.
4. Log actions, changed files, tests, and errors in `progress.md`.
5. Mark phases complete in `task_plan.md` and advance the current phase.
6. Run `scripts/check-complete.sh` or let the Stop hook report whether all phases are complete.

The active-plan resolver is the key runtime primitive. `scripts/resolve-plan-dir.sh` checks, in order, `$PLAN_ID`, `.planning/.active_plan`, newest valid `.planning/<dir>/` by mtime, and then lets callers fall back to legacy root files. It validates safe plan IDs, skips hidden/invalid directories, and exits successfully even when no plan exists so hooks do not break normal agent operation.

Hooks make the files active instead of passive. The canonical Claude skill frontmatter declares `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, and `PreCompact`. `UserPromptSubmit` injects an active-plan banner, plan data, recent progress, and a reminder to treat file content as data. `PreToolUse` injects a smaller plan excerpt before read/search/edit/bash-like tools. `PostToolUse` reminds the agent to update `progress.md` and phase status. `Stop` runs the completion check. `PreCompact` reminds the agent to flush state before context compaction and prints the plan hash when attested.

Plan attestation is opt-in. `/plan-attest` or `scripts/attest-plan.sh` hashes the active `task_plan.md` and writes the digest to `.planning/<plan-id>/.attestation` or root `.plan-attestation`. The canonical hooks compare current content against the stored hash. On mismatch they emit `[PLAN TAMPERED - injection blocked]` rather than feeding the plan into context. The write path uses temp-file plus rename and optional `flock`.

Long-running Claude Code sessions can compose `/plan-loop` and `/plan-goal`. `/plan-loop` wraps `/loop` with a default tick that re-reads planning files, runs `check-complete`, writes progress if stalled, and advances phases. `/plan-goal` derives a termination condition from `task_plan.md` so `/goal` stops only when plan statuses and `check-complete` agree.

Session recovery is handled by `scripts/session-catchup.py`. For Claude Code it scans prior JSONL sessions under `~/.claude/projects/`; for OpenCode it reads the SQLite database under the XDG data path. It finds the last planning-file update and prints subsequent unsynced conversation/tool summaries so the agent can update planning files after `/clear` or session loss.

## Architecture

The architecture has five layers:

1. Skill and command layer: `skills/planning-with-files/SKILL.md`, localized skill variants, and `commands/*.md` define the agent-facing behavior.
2. State templates: `templates/task_plan.md`, `templates/findings.md`, `templates/progress.md`, `templates/loop.md`, and analytics variants define the durable file schema.
3. Script layer: `init-session`, `resolve-plan-dir`, `set-active-plan`, `check-complete`, `attest-plan`, and `session-catchup` implement state creation, selection, verification, locking, and recovery.
4. Adapter layer: hidden folders such as `.codex/`, `.cursor/`, `.gemini/`, `.github/hooks/`, `.pi/`, `.hermes/`, `.opencode/`, and `.codebuddy/` map the same workflow onto host-specific skill and hook protocols.
5. Verification and release layer: `tests/` covers scripts, hook bodies, platform adapters, parity, executable bits, session isolation, OpenCode catchup, Pi extension behavior, and sync drift. `scripts/sync-ide-folders.py` copies shared templates/references/scripts into IDE-specific folders while intentionally excluding adapter-specific SKILL frontmatter and hooks.

The canonical source is not perfectly singular. Top-level `scripts/` and `skills/planning-with-files/scripts/` are expected to match for shared user-facing scripts, while adapter hook scripts under folders like `.codex/hooks/` are separate and narrower. Tests acknowledge this by checking canonical script sync and selected adapter behavior separately.

## Design Choices

The most important design choice is splitting durable state by trust and purpose. `task_plan.md` is repeatedly injected, so the docs explicitly say not to put untrusted web/search content there. External content goes to `findings.md`; execution history goes to `progress.md`; phase/goal state stays in `task_plan.md`.

The second choice is "read small, persist large." Hooks inject plan heads and progress tails, not full histories. The full files stay on disk for explicit reads. This makes the workflow useful after compaction without constantly flooding context.

The third choice is backwards compatibility. Legacy root files still work. Slug-mode adds isolated `.planning/<id>/` directories without breaking older users. `check-complete.sh` supports both `**Status:** complete` and older `[complete]` style status markers.

The fourth choice is fail-soft hooks. Most hooks exit 0 and print reminders or JSON messages rather than crashing the agent loop. Stop can block once, then returns a follow-up reminder when re-entered. That is pragmatic for developer tools but means enforcement depends on host semantics.

The fifth choice is adapter breadth. The repo favors broad client support with mirrored folders and docs. To control drift, it uses sync scripts, parity tests, and version-lock tests instead of assuming manual copy updates will stay correct.

The sixth choice is opt-in integrity. Plan attestation is available and well tested, but users must run `/plan-attest` after approving a plan. This keeps editing flexible, but unauthenticated plans are still injected with only delimiter/data-boundary instructions.

## Strengths

The three-file model is simple enough for agents to follow and for humans to audit. The files answer the practical resume questions: what is the goal, what phase is active, what did we learn, what changed, and what remains.

The resolver and slug-mode workflow are reusable. `$PLAN_ID`, `.active_plan`, newest valid plan dir, and root fallback form a clear active-state protocol for multiple tasks in one repo.

The update protocol is explicit. The 2-action rule, phase status updates, error table, progress log, and 5-question reboot test give the agent concrete write triggers instead of vague "keep notes" advice.

The attestation design directly addresses a prompt-injection risk caused by auto-reading plans. Delimiters alone are not treated as enough; the hash gate blocks injection when approved plan content changes unexpectedly.

The repo has unusually strong regression coverage for a skills/instructions project. Tests exercise resolver edge cases, corrupt `.active_plan`, path-separator rejection, concurrent attestation writes, canonical hook bodies, PreCompact behavior, Codex hooks, Codex session isolation, adapter drift, version parity, and script permissions.

The project documents its own tradeoff. The eval write-up admits the skill costs more tokens/time while improving structured workflow adherence. That is better research evidence than pure marketing claims.

## Weaknesses

The workflow can create maintenance overhead. Updating three files after phases, searches, errors, and tests is useful for long tasks but noisy for small edits. Agents can spend too much time tending state unless the trigger threshold is scoped.

Host enforcement is uneven. The canonical Claude skill embeds attestation and delimiter handling in frontmatter hook commands. The Codex adapter uses separate hook scripts that re-inject plan heads and progress reminders, but its reviewed hook scripts do not implement the same hash-attestation gate. For Codex-like clients, Agentic Coding Lab should treat the canonical skill as the stronger security reference and audit adapter parity before relying on tamper blocking.

The broad multi-IDE packaging surface increases drift risk. The project has tests for this, but there are many copies, frontmatter variants, command surfaces, and docs to keep synchronized.

`task_plan.md` is both trusted control state and model-visible data. The project mitigates this with "treat as data" language, untrusted-content routing to `findings.md`, and attestation, but unauthenticated plan content can still influence the model because it is intentionally injected.

Completion detection is simple string counting. `check-complete.sh` is robust enough for the template, but it is not a semantic verifier. A malformed phase, missing status line, or nonstandard plan can produce misleading counts.

The session-catchup path is useful but heuristic. It scans host-specific session stores and extracts summaries after the last planning-file update. That can miss work if the host schema changes, if tool events are not recorded in expected shapes, or if a user wants a privacy-minimal workflow.

The README platform count and support claims are broader than the core mechanism. For research use, source files and tests are more reliable than the headline "17+ platforms" and "40+ agents" framing.

## Ideas To Steal

Adopt the three-file state contract for long Agentic Coding Lab work: plan, findings, progress. Keep the files small and structured enough that an agent can update them safely.

Use an active-plan resolver with a strict precedence order: explicit env var, active pointer file, newest valid scoped directory, then legacy root fallback.

Use scoped plan directories for parallel work in one repository. `.planning/<date-slug>/task_plan.md` plus `.planning/.active_plan` is a practical pattern for avoiding root-file collisions.

Add a lightweight completion checker that is intentionally dumb but predictable, then pair it with human-readable phase status rules.

Use opt-in attestation for files that hooks auto-inject into model context. Hash locking is a cheap way to distinguish approved control state from silent edits.

Build compaction hooks around a simple guarantee: flush current state to disk before compaction, then re-read from disk after compaction. Do not pretend the model context itself is durable.

Test instruction packages like code. Extract hook bodies and run them; test corrupt state; test concurrent writes; test adapter manifests; test version parity across mirrored skill files.

Separate untrusted research from auto-injected plan state. The rule "write web/search results to findings only, never task_plan" is directly reusable.

## Do Not Copy

Do not copy the whole multi-platform adapter tree unless the lab is ready to maintain parity across every client. Start with one canonical workflow and one or two supported harness adapters.

Do not make three-file updates mandatory for tiny tasks. Agentic Coding Lab should scope activation to multi-step work, research, migrations, long debugging, and tasks likely to cross context boundaries.

Do not rely on delimiters alone as a prompt-injection boundary. If a file is auto-injected repeatedly, use hash approval, a restricted schema, or host-level trust boundaries.

Do not treat `check-complete.sh`-style status counting as proof that implementation is correct. It verifies workflow completion, not software correctness.

Do not put raw external content into the file that hooks inject before tool use. Preserve the project's `task_plan.md` versus `findings.md` trust split.

Do not assume adapter docs imply equal behavior. Review each target adapter's actual hook scripts before claiming support for attestation, blocking, session isolation, or compaction.

## Fit For Agentic Coding Lab

Fit is high. The repo is in-scope because it is a skills/instructions system with durable task state, hooks, verification scripts, and adapter patterns for coding agents.

The most useful Agentic Coding Lab adaptation would be a narrower file-backed planning protocol:

- `task_plan.md` or `.planning/<slug>/task_plan.md` for goals, phases, acceptance checks, decisions, and controlled error state.
- `findings.md` for research notes and untrusted external content.
- `progress.md` or a topic handoff file for commands, validation, commits, PRs, risks, and resume points.
- A resolver script that chooses active plan by env var, active pointer, and newest scoped plan.
- A completion script plus repository-specific verification commands.
- Optional plan attestation for any hook-injected state.

For the lab's research index workflow, the repo reinforces the current "owned file only, record commit, run verification" discipline. It suggests adding durable per-review progress logs only for longer multi-turn reviews, not for every small note. It also suggests that future Agentic Coding Lab skills should test hook and instruction behavior, not just ship Markdown.

## Reviewed Paths

- `/tmp/myagents-research/othmanadi-planning-with-files/README.md`: public overview, platform matrix, current release notes, three-file pattern, benchmark summary, usage, and file structure.
- `/tmp/myagents-research/othmanadi-planning-with-files/skills/planning-with-files/SKILL.md`: canonical skill frontmatter, hooks, critical rules, resolver/attestation descriptions, loop/goal integration, security boundary, anti-patterns.
- `/tmp/myagents-research/othmanadi-planning-with-files/templates/task_plan.md`: canonical phase, goal, decisions, errors, and notes schema.
- `/tmp/myagents-research/othmanadi-planning-with-files/templates/findings.md`: research, decisions, issues, resources, visual/browser findings, and 2-action rule schema.
- `/tmp/myagents-research/othmanadi-planning-with-files/templates/progress.md`: session log, actions, files changed, tests, errors, and reboot check schema.
- `/tmp/myagents-research/othmanadi-planning-with-files/templates/loop.md`: planning-aware `/loop` tick prompt.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/init-session.sh`: root versus slug-mode file initialization, slug generation, active plan pointer write.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/resolve-plan-dir.sh`: active-plan resolution order, safe identifier checks, newest-mtime fallback.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/set-active-plan.sh`: active pointer display and switching.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/check-complete.sh`: phase status counting and completion messages.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/attest-plan.sh`: SHA-256 attestation, root versus scoped storage, temp-write/rename, optional `flock`.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/session-catchup.py`: Claude Code and OpenCode session recovery logic.
- `/tmp/myagents-research/othmanadi-planning-with-files/commands/plan.md`, `commands/plan-attest.md`, `commands/plan-goal.md`, `commands/plan-loop.md`: user-facing command wrappers.
- `/tmp/myagents-research/othmanadi-planning-with-files/docs/quickstart.md`: update protocol, phase workflow, topic handoff guidance, completion verification.
- `/tmp/myagents-research/othmanadi-planning-with-files/docs/workflow.md`: hook flow, file relationships, topic handoff pattern, reboot questions.
- `/tmp/myagents-research/othmanadi-planning-with-files/docs/attestation-locking.md`: attestation write path, platform behavior, concurrency caveats, slug-mode recommendation.
- `/tmp/myagents-research/othmanadi-planning-with-files/docs/evals.md`: evaluation methodology, pass rates, token/time tradeoff, prompt-injection motivation.
- `/tmp/myagents-research/othmanadi-planning-with-files/docs/codex.md`: Codex skill and hook install surface, hook events, limitations.
- `/tmp/myagents-research/othmanadi-planning-with-files/.codex/hooks.json`: Codex hook registration.
- `/tmp/myagents-research/othmanadi-planning-with-files/.codex/hooks/*.py` and `.codex/hooks/*.sh`: Codex adapter, pre/post/stop/user-prompt/session-start behavior, session isolation.
- `/tmp/myagents-research/othmanadi-planning-with-files/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: plugin metadata and version.
- `/tmp/myagents-research/othmanadi-planning-with-files/scripts/sync-ide-folders.py`: canonical-to-adapter sync manifest and drift verification.
- `/tmp/myagents-research/othmanadi-planning-with-files/tests/test_resolve_plan_dir.py`: resolver edge cases and safe plan ID behavior.
- `/tmp/myagents-research/othmanadi-planning-with-files/tests/test_plan_attestation.py`: attestation helper behavior and concurrent write regression.
- `/tmp/myagents-research/othmanadi-planning-with-files/tests/test_hook_body_v240.py`: extracted canonical hook behavior, tamper blocking, timestamp normalization.
- `/tmp/myagents-research/othmanadi-planning-with-files/tests/test_precompact_hook.py`: PreCompact declaration and behavior.
- `/tmp/myagents-research/othmanadi-planning-with-files/tests/test_codex_hooks.py`, `tests/test_hook_resolver_integration.py`, `tests/test_codex_session_isolation.py`: Codex adapter events, resolver integration, and session isolation.
- `/tmp/myagents-research/othmanadi-planning-with-files/tests/test_canonical_script_sync.py`, `tests/test_skill_md_version_parity.py`, `tests/test_script_permissions.py`: drift, version parity, and executable-bit checks.
- `https://github.com/OthmanAdi/planning-with-files`: repository page for current public metadata during review.

## Excluded Paths

- `/tmp/myagents-research/othmanadi-planning-with-files/.git/`: VCS internals; only HEAD SHA and latest commit metadata were needed.
- `/tmp/myagents-research/othmanadi-planning-with-files/media/banner.png` and README badge/image assets: presentation-only binaries.
- Localized skill bodies under `skills/planning-with-files-{ar,de,es,zh,zht}/`: reviewed through version/parity tests and directory structure, not line-by-line translation quality.
- Most mirrored adapter skill directories under `.gemini/skills/`, `.codebuddy/skills/`, `.cursor/skills/`, `.factory/skills/`, `.hermes/skills/`, `.mastracode/skills/`, `.opencode/skills/`, `.pi/skills/`: sampled by file listing and sync/parity tests; canonical English skill and Codex adapter were reviewed in depth.
- `.kiro/skills/planning-with-files/assets/**`: Kiro-specific format and templates; not central to the file-backed planning mechanism beyond confirming adapter breadth.
- `.github/workflows/*`: CI metadata. I inspected test coverage and scripts rather than workflow YAML details.
- `.github/hooks/scripts/*.ps1`, `.cursor/hooks/*.ps1`, PowerShell mirrors: platform-specific mirrors; reviewed the shell/Python canonical behavior and tests.
- `examples/boxlite/**` and sandbox quickstart code: useful integration example but not part of the planning execution path.
- `CONTRIBUTORS.md`, `CITATION.cff`, `LICENSE`, and most marketplace copy: provenance/legal/metadata, not core workflow behavior.
- `scripts/_v240_update_hook_bodies.py` and `scripts/bump-version.py`: release maintenance helpers; noted through tests and release notes, not reviewed line-by-line.
