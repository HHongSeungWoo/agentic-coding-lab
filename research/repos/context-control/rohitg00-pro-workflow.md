# rohitg00/pro-workflow

- URL: https://github.com/rohitg00/pro-workflow
- Category: context-control
- Stars snapshot: 2,161 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: 9fc35f5e3cb419da8a095fa8f32015be7ce267f6
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit context-control reference. Steal the SQLite/FTS knowledge plane, lifecycle hook wiring, context-engineering taxonomy, compact/worktree/team patterns, and hard safety gates; do not copy the overclaimed parts until they have tests and real enforcement.

## Why It Matters

Pro Workflow is one of the more complete public attempts to make context control a runtime system instead of a prompt convention. It combines memory, persistent research wikis, context budgeting, compaction rituals, worktree isolation, agent-team patterns, and safety checks in one Claude Code plugin-style bundle.

For Agentic Coding Lab, the useful lesson is the shape of the control loop: session lifecycle events write and retrieve durable state, prompt submission searches prior knowledge, tool hooks enforce or warn on risky behavior, and long-running research becomes a wiki indexed outside the model context. The repo is also valuable because its source reveals the difference between advertised workflow patterns and the actual enforcement points.

## What It Is

The repo is a Claude Code plugin plus cross-agent workflow pack. It ships skills, agents, slash-command markdown files, hook scripts, settings examples, rule files, split `CLAUDE.md`/`AGENTS.md` templates, and a small TypeScript package that provides a `better-sqlite3` store with FTS5 search.

The core product surface is:

- `skills/`: 34 workflow skills covering context engineering, wiki building/querying/research, compact guard, token efficiency, worktrees, agent teams, orchestration, safety, permission tuning, and commit/review rituals.
- `commands/`: 22 slash-command playbooks such as `/develop`, `/wiki`, `/parallel`, `/replay`, `/wrap-up`, `/safe-mode`, and `/context-optimizer`.
- `agents/`: 8 Claude Code agent definitions including `scout`, `orchestrator`, `reviewer`, `debugger`, `context-engineer`, `permission-analyst`, and `cost-analyst`.
- `hooks/hooks.json` and `scripts/`: 37 Node hook scripts across Claude Code lifecycle/tool events.
- `src/db` and `src/search`: SQLite schema/store plus FTS and optional embedding helpers.
- `docs/`, `rules/`, and `templates/`: reference material and portable instruction artifacts for Claude Code, Cursor, Codex, Gemini CLI, and SkillKit translation.

## Research Themes

- Token efficiency: Strong as a pattern library, partial as enforcement. The skills define tool-call budgets, read-before-write, no re-reads, MCP caps, subagent isolation, compact-at-boundaries, and terse output. Runtime hooks track tool-call counts and block repeated unchanged reads, but several other checks only warn.
- Context control: Core theme. The repo uses SQLite tables for learnings, sessions, wikis, wiki pages, seeds, wiki-scoped learnings, and embeddings; hooks surface recent learnings/wikis at session start and wiki hits at prompt time; compact hooks save/restore session state.
- Sub-agent / multi-agent: Strong workflow guidance. `scout` runs read-only in worktree isolation, `/parallel` and `parallel-worktrees` lean on native `claude -w`, and `agent-teams` documents lead/teammate coordination, shared tasks, mailbox messaging, and file locks. Implementation mostly relies on Claude Code features rather than custom coordination code.
- Domain-specific workflow: Broad developer workflow rather than one domain. The wiki layer supports research, paper, domain, product, person, organization, project, codebase, and incident flavors; commands cover feature development, review, commits, and research.
- Error prevention: Good mix of hard and soft controls. Hard blocks exist for destructive git operations, secret-like writes, and invalid conventional commit messages. Quality gates, permission warnings, post-edit checks, test-failure learning prompts, config-change notices, and pre-push reminders are mostly advisory.
- Self-learning / memory: Strongest concrete subsystem. `[LEARN]` blocks are parsed into SQLite, FTS5 indexes rules, `SessionStart` surfaces recent learnings, `/replay` searches correction history, and wiki-scoped learnings avoid polluting unrelated contexts.
- Popular skills: Most relevant for the lab are `context-engineering`, `context-optimizer`, `compact-guard`, `token-efficiency`, `learn-rule`, `replay-learnings`, `wiki-builder`, `wiki-query`, `wiki-research-loop`, `parallel-worktrees`, `agent-teams`, `orchestrate`, `smart-commit`, `llm-gate`, and `safe-mode`.

## Core Execution Path

Install/build starts from plugin metadata and `package.json`. The package compiles TypeScript and copies `src/db/schema.sql` into `dist/db/schema.sql`; most hook scripts that use the database require built `dist` files and silently degrade or fail with a "build first" message if the build has not run.

On `SessionStart`, `scripts/session-start.js` finds the project root, starts or resumes a session row, logs up to five recent learnings, lists registered wikis, and reports available worktrees. This gives the next model turn a small summary rather than raw history.

On `UserPromptSubmit`, `scripts/prompt-submit.js` detects correction and learning-trigger phrases, increments prompt/correction counters, and runs loose FTS search over wiki pages for prompts with at least three words. It prints the top three matching wiki page references. `scripts/drift-detector.js` separately tracks the original prompt intent in `/tmp/pro-workflow` and warns after several edits when current prompts look unrelated.

Before tools run, `hooks/hooks.json` wires several controls. Every tool call increments the tool-budget counter. `Read` calls update the reread tracker and read-before-write tracker. `Edit`/`Write` calls update edit counters, warn on writes to unread existing files, and run deterministic secret scanning. `Bash` calls pass through git blast-radius checks; `git commit` also gets quality-gate and commit-message validation; `git push` gets a wrap-up reminder.

After tools run, code edits are scanned for console/debug/print statements, untracked task-marker comments, and hardcoded secret patterns. Test commands that produce `fail` or `error` output prompt a possible learning capture. Stop/session-end hooks remind the user to wrap up, auto-capture `[LEARN]` blocks from assistant responses, close the session, and warn about uncommitted changes.

Compaction has a simple persistence path. `pre-compact.js` saves summary, edit count, prompt count, and session id to `/tmp/pro-workflow/compacts/*.json`; `post-compact.js` reads the newest compact file and reprints the saved summary and counts.

The wiki execution path is more substantial. `wiki-cli.js init` validates a slug, scaffolds a folder under `~/.pro-workflow/wikis/<slug>/` or `<project>/.claude/wikis/<slug>/`, and registers it in SQLite. `page` validates that relative paths stay inside the wiki root, writes or reads markdown, extracts title/summary/type, and upserts the page into `wiki_pages` and `wiki_pages_fts`. `query.js` performs BM25 search, `embed-wiki.js` adds optional OpenAI/Voyage embeddings and hybrid RRF search, and `wiki-viewer` renders a single-file HTML viewer from the database and `sources.md`.

The auto-research path is a seed queue. `research-loop.js seed` inserts `wiki_seeds`; `run` claims the next pending seed, fetches up to three docs from configured fetchers, extracts sentence-like claims, writes a markdown page under `wiki/questions/`, upserts it into FTS, derives follow-up seeds, and halts on max pages, max depth, budget, convergence, queue empty, private-wiki guard, or `~/.pro-workflow/STOP`.

## Architecture

The first layer is packaging. `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `settings.example.json`, `mcp-config.example.json`, and `docs/cross-agent-workflows.md` describe how the same patterns travel across Claude Code, Cursor, Codex, Gemini CLI, and SkillKit.

The second layer is procedural context. Skills, commands, agents, rules, and templates are markdown contracts that teach the model when to plan, when to compact, how to decompose work, how to capture learnings, and how to use worktrees or teams.

The third layer is hooks. `hooks/hooks.json` binds Claude Code events to Node scripts. Some scripts are passive observability, some are advisory reminders, and a smaller set blocks operations via nonzero exit codes.

The fourth layer is durable state. `src/db/schema.sql` creates `learnings`, `sessions`, `wikis`, `wiki_pages`, `wiki_sources`, `wiki_claims`, `wiki_seeds`, `wiki_embeddings`, and `learnings_wiki`. FTS5 virtual tables keep learnings and wiki pages searchable. `src/db/store.ts` wraps common operations and guards wiki slug collisions across roots/scopes.

The fifth layer is external knowledge growth. Wiki markdown stays on disk for review and versioning; SQLite stores searchable shadows; fetchers pull web/arXiv/GitHub snippets; optional embeddings support hybrid retrieval; council/survey scripts can persist higher-cost LLM outputs back into a wiki.

The sixth layer is ephemeral session telemetry. Several hooks use `/tmp/pro-workflow` for edit counts, prompt counts, reread tracking, intent tracking, permission denials, worktree logs, and compact snapshots. That keeps model context small but is not a durable source of truth.

## Design Choices

The most important design choice is the single "knowledge plane": personal learnings and research wikis share one SQLite database, FTS search, and hook surface. This lets both "do not repeat my correction" and "what did my research wiki say" use the same retrieval habit.

The repo uses the context-engineering taxonomy `Write / Select / Compress / Isolate` consistently across skills and docs. It gives users a mental model for when to persist state, retrieve narrow context, compact, or split work across subagents/worktrees.

The wiki design keeps markdown as the editable artifact and SQLite as the recall index. That is a good split for agent workflows because humans can review the wiki folder while hooks and commands query the index.

Most controls are placed at lifecycle/tool boundaries instead of only in `CLAUDE.md`. That is the right direction: read/write/commit/push/compact/session-start are the moments where context and safety policy can be enforced.

The project intentionally leans on native Claude Code capabilities for worktrees, background agents, agent teams, hooks, and plugin packaging. This keeps custom implementation smaller, but it means many features are portability patterns rather than standalone code.

Safety uses a mixed hard/soft policy. Secret scans, dangerous git operations, reread tracking, and commit message validation can block. Quality reminders, read-before-write, permission warnings, pre-push wrap-up, and many context controls advise without blocking.

## Strengths

The SQLite/FTS implementation is real and small enough to steal. The schema, triggers, `store.ts`, and search helpers are a practical starting point for persistent memory and wiki recall.

The hook map covers the right lifecycle. Session start, prompt submit, pre-tool, post-tool, stop, session end, pre/post compact, permission events, worktree events, file changes, and cwd changes together form a usable context-control state machine.

The wiki system is a strong lab pattern. It separates raw sources, compiled pages, derived artifacts, prompts, logs, and `sources.md`; it allows global or project scope; and it gives every session a retrieval path without redoing research.

The docs are unusually concrete about token economics and context discipline. MCP caps, tool-call budgets, root memory size limits, compaction thresholds, and subagent isolation guidance are directly actionable.

The worktree and agent-team guidance is pragmatic. It clearly separates subagents, teams, and worktrees by duration, isolation, communication, and coordination overhead.

The hard safety checks are useful. `git-blast-radius.js` blocks common destructive git patterns, `secret-scan.js` blocks secret-like content and secret-like paths, and `commit-validate.js` enforces conventional commits when a message can be parsed.

## Weaknesses

Several README claims are stronger than the implementation. Prompt-time wiki "auto-injection" is currently a stderr hint listing matching pages, not actual content injection. The research loop compiles pages by heuristic sentence extraction rather than a cited LLM synthesis step. The loop writes source links into markdown but does not populate `wiki_sources` or `wiki_claims`.

The auto-research budget model is mostly notional. Built-in fetchers return zero estimated cost, and the loop does not account for a real compile model because the current compiler is local string processing.

`/safe-mode` is mostly documentation in this repo. The skill describes session-scoped cautious/lockdown state and edit blocking, but the reviewed source has no corresponding safe-mode state script; the always-on global path is only the simpler `permission-request.js` warning hook plus other general safety scripts.

Build dependency is a sharp edge. Database-backed hooks require built `dist` files, but the plugin can be installed as source-like markdown/scripts. Several scripts silently degrade when `dist` is missing, so users may think memory is active when it is not.

Test coverage is thin. CI builds TypeScript, runs `tsc --noEmit`, checks dist files, and validates plugin/hooks metadata, but `rg` found no unit tests for the database store, FTS query behavior, hook blocking behavior, safe-mode behavior, wiki CLI path guards, research-loop state transitions, or fetcher parsing.

Some controls may be too blunt for real coding. `reread-tracker.js` exits nonzero on a second unchanged file read, which can block legitimate verification reads. Meanwhile `read-before-write.js` only warns, so enforcement strength is inconsistent.

Many slash commands are markdown playbooks, not executable CLIs. That is normal for Claude Code commands, but it means the actual behavior depends on the model following instructions. For lab artifacts, critical paths need tests or deterministic scripts.

Global home-directory storage is convenient but weak for reproducible research. `~/.pro-workflow/data.db`, `~/.pro-workflow/wikis`, and `/tmp/pro-workflow` make cross-machine, CI, and multi-project behavior harder to reason about unless project-local overrides are used deliberately.

## Ideas To Steal

Use a small SQLite store as the common substrate for learnings, sessions, wiki pages, seed queues, embeddings, and scoped learning links. Add FTS triggers at schema level so search stays current without relying on caller discipline.

Make `SessionStart` load only high-signal summaries: recent learnings, previous-session stats, available wikis, and active worktrees. Avoid replaying transcript history.

Make `UserPromptSubmit` run lightweight retrieval over durable knowledge. For the lab version, inject or write a structured context packet that includes page title, path, snippet, and citation policy.

Keep durable wiki artifacts as markdown and use the DB as a searchable shadow index. This gives humans reviewable files and agents fast recall.

Add wiki-scoped learnings. A rule learned while maintaining one wiki or domain should not automatically become a global behavior rule.

Use the `Write / Select / Compress / Isolate` taxonomy as the top-level context-control model for lab docs and skills.

Wire context policy into lifecycle events: start restores, prompt retrieves, pre-tool controls waste/risk, post-tool captures facts, pre-compact writes emergency state, post-compact restores, stop/session-end captures learnings and handoff.

Steal hard safety gates with explicit exit codes: git blast-radius blocking, secret scanning, and commit-message parsing. Pair every gate with tests.

Adopt the worktree/team decision tables. They are clear enough to become an Agentic Coding Lab guide for choosing subagent vs team vs worktree vs batch orchestration.

Use a kill switch for autonomous loops. A plain `STOP` file is crude but operationally useful.

## Do Not Copy

Do not copy the overclaiming gap. If a feature says "auto-injects wiki context", the implementation should actually provide content to the model, not only print page references.

Do not use the current research-loop compiler as a fact pipeline. It extracts early sentences from fetched snippets, has weak provenance, and does not populate the claims/sources tables. A lab version needs source rows, claim rows, dedupe tests, citation validation, and explicit "unverified" states.

Do not treat markdown instructions as enforcement. For safety, privacy, context budgets, and durable memory, define which controls are advisory and which are blocking.

Do not rely on `/tmp` counters and compact snapshots as authoritative state. They are good for hints, but durable session state should live in the DB or a project file.

Do not use a global user database as the only mode. Agentic Coding Lab should support project-local stores for reproducibility, privacy, and test fixtures.

Do not ship hook-heavy behavior without fixture tests for hook JSON input/output and exit codes. Hooks are the runtime contract.

Do not block re-reads categorically. Re-read prevention should distinguish wasteful repetition from verification, line-range narrowing, and user-requested review.

Do not copy model names or provider defaults without current validation. Some defaults are likely illustrative and will age quickly.

## Fit For Agentic Coding Lab

This repo is a strong fit for `context-control`. The lab should mine it as a pattern source, not adopt it whole.

Best lab artifact candidates:

- `context-store`: project-local SQLite/FTS schema for learnings, sessions, wiki pages, seeds, citations, and embeddings, with migration tests.
- `session-brief`: a start/prompt hook pair that emits a compact, machine-readable retrieval packet.
- `wiki-kb`: markdown-on-disk plus DB shadow index, with citation-required page writes and search tests.
- `compact-handoff`: pre/post compact state saved to a stable handoff file, not only `/tmp`.
- `tool-budget`: a soft budget hook that warns by task type and writes metrics to DB.
- `safety-gates`: tested hard blocks for secrets, destructive git, and invalid commit messages.
- `parallel-work-contract`: concise instructions for subagent vs team vs worktree selection, with file ownership and verification evidence.

The central adaptation is to turn Pro Workflow's broad personal workflow pack into smaller, testable lab components. Keep the lifecycle architecture and knowledge-plane schema; reduce the number of loosely enforced rituals.

## Reviewed Paths

- `README.md` for product claims, component counts, wiki flow, knowledge-plane framing, storage layout, cross-agent support, MCP recommendations, and pattern list.
- `.claude-plugin/plugin.json`, `.claude-plugin/settings.json`, `.claude-plugin/README.md`, `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`, `config.json`, `package.json`, `settings.example.json`, and `mcp-config.example.json` for packaging, install/config assumptions, permissions, MCP guidance, dependencies, and build scripts.
- `hooks/hooks.json` for the actual Claude Code event-to-script wiring.
- `src/db/schema.sql`, `src/db/index.ts`, `src/db/store.ts`, `src/search/fts.ts`, and `src/search/embeddings.ts` for memory, wiki, FTS, seed queue, and hybrid retrieval implementation.
- `scripts/session-start.js`, `prompt-submit.js`, `drift-detector.js`, `learn-capture.js`, `session-check.js`, `session-end.js`, `pre-compact.js`, and `post-compact.js` for session, prompt, learning, and compaction behavior.
- `scripts/read-before-write.js`, `reread-tracker.js`, `tool-call-budget.js`, `quality-gate.js`, `post-edit-check.js`, `test-failure-check.js`, `secret-scan.js`, `git-blast-radius.js`, `commit-validate.js`, `pre-commit-check.js`, and `pre-push-check.js` for token, quality, and safety checks.
- `scripts/permission-request.js`, `permission-denied.js`, `notification-handler.js`, `tool-failure.js`, `file-changed.js`, `config-watcher.js`, `research-tick.js`, `worktree-create.js`, `worktree-remove.js`, `subagent-start.js`, `subagent-stop.js`, `task-created.js`, `task-completed.js`, `teammate-idle.js`, `cwd-changed.js`, and `stop-failure.js` for observability, permissions, reactive seeds, team/worktree events, and failure hints.
- `commands/develop.md`, `wiki.md`, `parallel.md`, `context-optimizer.md`, `compact-guard.md`, `learn-rule.md`, `replay.md`, `safe-mode.md`, `wrap-up.md`, `permission-tuner.md`, `mcp-audit.md`, `commit.md`, and `doctor.md` for command-level workflows.
- `skills/context-engineering/SKILL.md`, `context-optimizer/SKILL.md`, `compact-guard/SKILL.md`, `token-efficiency/SKILL.md`, `learn-rule/SKILL.md`, `replay-learnings/SKILL.md`, `wrap-up/SKILL.md`, `orchestrate/SKILL.md`, `smart-commit/SKILL.md`, `llm-gate/SKILL.md`, `safe-mode/SKILL.md`, `mcp-audit/SKILL.md`, `permission-tuner/SKILL.md`, `cost-tracker/SKILL.md`, `parallel-worktrees/SKILL.md`, `batch-orchestration/SKILL.md`, `agent-teams/SKILL.md`, `module-map/SKILL.md`, `plan-interrogate/SKILL.md`, `session-handoff/SKILL.md`, and `bug-capture/SKILL.md` for reusable workflow patterns.
- `skills/wiki-builder/SKILL.md`, `skills/wiki-builder/scripts/wiki-cli.js`, `skills/wiki-builder/scripts/init_wiki.sh`, `skills/wiki-query/SKILL.md`, `skills/wiki-query/scripts/query.js`, `skills/wiki-research-loop/SKILL.md`, `skills/wiki-research-loop/scripts/research-loop.js`, `skills/wiki-research-loop/scripts/source-fetchers/{web,arxiv,github}.js`, `scripts/embed-wiki.js`, `skills/wiki-viewer/SKILL.md`, `skills/wiki-viewer/scripts/render.js`, `skills/llm-council/SKILL.md`, `skills/llm-council/scripts/council.js`, `skills/survey-generator/SKILL.md`, and `skills/survey-generator/scripts/build-survey.js` for the wiki, research, hybrid retrieval, council, and survey paths.
- `agents/scout.md`, `agents/context-engineer.md`, `agents/orchestrator.md`, `agents/reviewer.md`, `agents/debugger.md`, `agents/permission-analyst.md`, `agents/cost-analyst.md`, and `agents/planner.md` for agent frontmatter, model/tool constraints, isolation, and phase design.
- `docs/context-engineering.md`, `docs/context-loading.md`, `docs/agent-teams.md`, `docs/cross-agent-workflows.md`, `docs/orchestration-patterns.md`, `docs/settings-guide.md`, `docs/daily-habits.md`, `docs/cli-cheatsheet.md`, `docs/decision-framework.md`, and `docs/new-features.md` for context-control docs and cross-agent mapping.
- `templates/split-claude-md/CLAUDE.md`, `AGENTS.md`, `LEARNED.md`, `COMMANDS.md`, and `SOUL.md`, plus `templates/AGENTS.md`, for portable instruction structure.
- `rules/context-discipline.mdc`, `self-correction.mdc`, `quality-gates.mdc`, `pre-flight-discipline.mdc`, `token-efficiency.mdc`, `atomic-commits.mdc`, `communication-style.mdc`, `module-shape.mdc`, `incremental-verify.mdc`, and `no-debug-statements.mdc` for always-apply rule packs.
- `.github/workflows/ci.yml`, `release.yml`, and `npm-publish.yml` for verification and publishing controls.

## Excluded Paths

- `.git/**` was excluded as version-control metadata; the reviewed commit records the source state.
- `package-lock.json` was not deeply reviewed beyond dependency provenance because it is generated lockfile data, not workflow logic.
- `assets/*.svg`, `docs/index.html`, and `docs/infographic.html` were excluded as UI/marketing surfaces. The same product claims were checked against README and source paths instead.
- `docs/agent-teams.md` and other docs were sampled for workflow semantics, but visual-only/generated sections in docs were not treated as source of truth.
- `references/claude-code-resources.md` was excluded as an external link list with no direct execution path.
- `skills/wiki-builder/templates/**` and `skills/survey-generator/templates/**` were reviewed only for layout relevance where needed; prompt/template prose was not exhaustively audited because runtime behavior lives in the scripts and skills.
- `dist/**` was not present in the checkout; if generated by `npm run build`, it should be excluded in favor of `src/**`.
- `node_modules/**`, build caches, runtime databases, and local wiki data were not present and would be excluded as vendor/generated/user state.
- No binary artifacts or vendored source paths were relevant in this checkout.
