# Dicklesworthstone/cass_memory_system

- URL: https://github.com/Dicklesworthstone/cass_memory_system
- Category: memory
- Stars snapshot: 370 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: ff49fbd94339880f3b7bac0759026db6368f9bba
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong procedural-memory reference for coding agents. The useful pattern is the complete loop from session search to diary, LLM-reflected candidate rules, evidence gating, deterministic curation, confidence decay, anti-pattern inversion, and agent-friendly retrieval. Do not adopt wholesale without a stricter license review, stronger hard budgets, and caution around heuristic validation and plaintext local memory.

## Why It Matters

cass-memory is directly aimed at the Agentic Coding Lab memory problem: how to turn scattered coding-agent sessions into durable, reusable procedural guidance. Unlike many memory repos that stop at vector recall, it tries to create and maintain explicit rules, anti-patterns, feedback events, maturity state, and source-session provenance. It also treats agents as first-class consumers through JSON output, TOON output, an AGENTS.md blurb, a Claude Code skill file, and an HTTP MCP surface.

The repo is especially useful because it separates three jobs that are often conflated: retrieval before work, reflection after work, and deterministic maintenance of the memory store. That makes it a good design source for a coding-agent memory workflow even if the implementation should not be copied directly.

## What It Is

cass-memory is a Bun/TypeScript CLI published as `cass-memory` and `cm`. It depends on a separate `cass` session-search binary for episodic memory over raw agent sessions. It then stores procedural memory in YAML playbooks, working-memory diary entries in JSON files, processed-session logs in reflection logs, outcomes in JSONL, and optional project-level memory under `.cass/`.

The system exposes CLI commands for pre-task context (`cm context`), rule management (`cm playbook`), session reflection (`cm reflect`), agent-native onboarding (`cm onboard`), rule validation (`cm validate`), feedback (`cm mark`, inline comments, outcomes), privacy controls, diagnostics, and a "trauma guard" safety registry. It also offers an HTTP JSON-RPC MCP-like server with tools for context, feedback, outcomes, memory search, and reflection.

## Research Themes

- Token efficiency: The primary context command returns bounded `relevantBullets`, `antiPatterns`, `historySnippets`, and suggested searches, with `--limit`, `--history`, `--days`, and `--no-history` style controls. It also supports TOON output and token-stat reporting for selected commands. Embedding vectors are stripped from JSON output, and snippets are truncated before return.
- Context control: The recommended protocol is explicit: run `cm context "<task>" --json` before non-trivial work, use rule IDs while working, then let feedback/reflection update memory. Retrieval combines playbook scoring, optional semantic search, cass history, deprecated-pattern warnings, and trauma warnings. Degraded fields tell the agent when cass or semantic search fell back.
- Sub-agent / multi-agent: The repo is not a multi-agent orchestrator, but it is cross-agent oriented. It reads sessions from Claude, Codex, Cursor, Aider, PI, Gemini, and other logs through cass, tags source agents from paths, can enrich diaries with other-agent sessions after explicit consent, and has optional remote cass over SSH.
- Domain-specific workflow: This is strongly coding-agent specific. The rule categories, AGENTS.md protocol, inline feedback syntax, project `.cass/` playbooks, source-session provenance, test commands, and trauma guard are built around software development sessions rather than generic chatbot memory.
- Error prevention: It includes evidence gating, conflict and duplicate detection, harmful-feedback weighting, anti-pattern inversion, stale-rule detection, deprecated-pattern warnings, a dangerous-command trauma registry, MCP host/auth checks, config hardening, ReDoS guards, atomic writes, and lock ownership checks.
- Self-learning / memory: The core loop is session discovery -> sanitized export -> diary -> reflector deltas -> validation -> deterministic curation -> playbook retrieval. Rules gain helpful/harmful feedback, decay over time, mature from candidate to established/proven, and can be deprecated or inverted.
- Popular skills: Reusable skill ideas include "query procedural memory before work", "extract rules from past sessions", "batch-add candidate rules with validation", "leave inline helpful/harmful feedback", "inspect why a rule exists", "stale-rule review", and "block repeated catastrophic commands".

## Core Execution Path

The main usage path starts with `cm context "<task>" --json`. The command loads global and repo playbooks, extracts keywords, filters active bullets by workspace, scores each bullet by keyword or optional embeddings plus effective confidence, searches cass for historical snippets, checks deprecated patterns, and returns a bounded structured result. If cass is missing, it degrades to playbook-only context instead of failing the workflow.

The automated learning path is `cm reflect`. The orchestrator locks a workspace processed log, discovers unprocessed sessions through cass timeline/search or accepts an explicit session path, exports each session through cass, sanitizes it, generates a diary entry, and asks an LLM reflector for playbook deltas. The reflector can emit add, helpful, harmful, replace, deprecate, or merge deltas under a strict schema. Add deltas pass through a cheap evidence-count gate and, when evidence is ambiguous, an LLM validator.

The curation phase is deliberately deterministic. It reloads fresh global and repo playbooks under locks, routes feedback to the playbook that owns each bullet, deduplicates exact and similar rules, records feedback idempotently, applies replacements/deprecations/merges, adds new bullets, inverts repeatedly harmful positive rules into anti-patterns, and promotes or demotes maturity based on decayed feedback.

There is also an agent-native onboarding path. `cm onboard status/gaps/sample/read/prompt/mark-done` helps a coding agent sample historical sessions, read a session with extraction context, manually produce rule JSON, and add rules with `cm playbook add --file`. This is a practical alternative when the operator wants to use the current coding agent instead of paid API-based reflection.

## Architecture

The CLI entrypoint is `src/cm.ts`, with one command module per workflow. The main memory modules are `cass.ts` for search/export/timeline integration, `diary.ts` for working-memory extraction, `reflect.ts` for LLM-produced deltas, `validate.ts` for evidence checks, `curate.ts` for deterministic playbook mutation, `playbook.ts` for YAML persistence and project/global merging, `scoring.ts` for decay and maturity, `outcome.ts` for implicit feedback, and `orchestrator.ts` for the end-to-end reflection loop.

Storage is file-first. Global state defaults to `~/.cass-memory/` with `config.json`, `playbook.yaml`, `diary/*.json`, `reflections/*.processed.log`, `outcomes.jsonl`, `context-log.jsonl`, `usage.jsonl`, `blocked.log`, and `traumas.jsonl`. Repo-local memory lives in `.cass/playbook.yaml`, `.cass/blocked.log`, `.cass/outcomes.jsonl`, `.cass/context-log.jsonl`, and `.cass/traumas.jsonl` when initialized or present. Writes use atomic temp files and `.lock.d` lock directories.

Retrieval is hybrid but pragmatic. The playbook path uses keyword scoring by default and optional semantic embeddings through Xenova or Ollama. Episodic snippets come from `cass search --robot`, with local and optional SSH remote hits merged and sanitized. MCP resources expose merged playbook, diary, outcomes, and stats; MCP tools delegate back to the same command logic.

## Design Choices

The strongest design choice is separating the LLM proposal phase from deterministic curation. The reflector and validator can be fuzzy, but the curator owns deduplication, feedback application, inversion, promotion, demotion, and persistence. That reduces iterative prompt drift and makes rule mutation easier to test.

The memory object is a rule, not an opaque embedding. A playbook bullet has scope, category, content, type, kind, maturity, state, helpful/harmful counts, feedback events, source sessions, source agents, tags, reasoning, and optional embeddings. This is a good procedural-memory shape for coding agents because it can be inspected, exported to AGENTS.md, ranked by confidence, and invalidated.

The repo also chooses graceful degradation. Missing cass yields playbook-only context. Missing or broken semantic embeddings fall back to keyword mode and expose `semanticMode`/`semanticError`. Missing LLM support can still generate fast heuristic diaries. This is important for coding agents because memory should improve a workflow without becoming a single point of failure.

## Strengths

- The procedural-memory lifecycle is unusually complete for a small CLI: session discovery, diary generation, reflection, validation, deterministic merge, retrieval, feedback, decay, and anti-pattern handling are all represented in code and tests.
- Agent ergonomics are strong. JSON mode is documented as the default for agents, structured errors are supported, TOON output exists for token reduction, and the AGENTS.md blurb gives a short adoptable protocol.
- The storage model is inspectable and portable. YAML playbooks, JSON diaries, JSONL outcomes, and repo-local `.cass/` files are easy to debug and can be versioned or shared selectively.
- The validation and feedback mechanisms are practical. Helpful/harmful events, decayed scores, maturity states, explicit `cm mark`, inline feedback comments, and outcome-derived implicit feedback give the system several ways to learn after retrieval.
- Privacy controls are better than many memory tools: cross-agent enrichment is opt-in, agent allowlists exist, repo configs cannot override sensitive paths or consent settings, snippets are sanitized, and remote cass requires explicit SSH config.
- Safety is treated as part of memory. The trauma registry and guard commands turn past catastrophic patterns into mechanical warnings or blocks rather than mere notes.
- Test coverage is broad for the core surfaces, including curation, validation, privacy, config hardening, TOON output, CLI workflows, locks, context, onboarding, outcome feedback, and MCP serving.

## Weaknesses

- The license is a serious adoption caveat. `LICENSE` is "MIT License (with OpenAI/Anthropic Rider)" and GitHub reports `NOASSERTION`, while `package.json` says `MIT`. That mismatch and the rider mean this should be treated as research-only until counsel approves use.
- The "scientific validation" framing is stronger than the implementation. Evidence gating relies on keyword search and simple success/failure regexes, and conflict detection is heuristic token overlap. Useful, but not a rigorous proof that a rule is correct.
- Core memory depends on the separate cass binary and its session index. Without cass, the system still works as a playbook manager but loses the raw-history evidence path that makes reflection and validation compelling.
- Plaintext local storage remains the default for playbooks, diaries, outcomes, context logs, and raw session-derived snippets. Sanitization helps, but there is no built-in encryption, retention enforcement, or high-assurance secret scrubber.
- Cross-agent portability is mostly mediated by file/session conventions and cass support. It can read many agent logs, but automatic hooks are not universally packaged for every client, and reflection/onboarding still require operator setup.
- MCP is HTTP-only and unauthenticated on loopback unless `MCP_HTTP_TOKEN` is set. It refuses non-loopback without auth by default, which is good, but local services can still expose sensitive playbook/diary/history data.
- The curation logic is deterministic but still uses Jaccard similarity and marker heuristics; near-duplicates, contradictory rules, and anti-pattern inversions can still need human review.

## Ideas To Steal

- Model procedural memory as inspectable rules with source sessions, source agents, feedback events, maturity, decay, and reasoning instead of just embedding hits.
- Keep LLM reflection limited to proposal generation; make merge, dedup, conflict handling, anti-pattern inversion, promotion, and persistence deterministic.
- Add an agent-native onboarding mode that lets the current coding agent read old sessions and produce initial rules without a separate LLM API budget.
- Return memory in an agent-first contract: structured JSON or TOON, bounded sections, explicit degraded fields, and rule IDs that can be referenced in feedback.
- Use inline feedback comments as a low-friction way for agents to leave evidence about whether a retrieved rule helped or hurt.
- Split global personal memory from repo-local `.cass/` memory, and prevent repo configs from overriding sensitive user-level settings.
- Make stale and harmful memory visible through scoring, decay, top/stale commands, and anti-pattern conversion rather than silently deleting old guidance.
- Treat catastrophic mistakes as a memory class with stronger affordances: registries, warnings, hooks, and an explicit healing/removal workflow.

## Do Not Copy

- Do not copy the license posture into Agentic Coding Lab artifacts. The rider is intentionally restrictive and conflicts with the simple `MIT` package metadata.
- Do not claim evidence-gated rules are scientifically validated unless the validation uses stronger task outcomes, provenance, and evaluation criteria than keyword hit counts.
- Do not store raw or summarized coding sessions in plaintext without an explicit retention, encryption, redaction, and user-consent policy.
- Do not expose memory over HTTP without authentication, even on localhost, if the environment has untrusted local processes.
- Do not let heuristic curation fully replace human review for high-impact repo rules, security guidance, destructive operations, or team-shared memory.
- Do not require a separate session-search binary as the only raw-evidence path unless installation, indexing, and health checks are part of the managed product.
- Do not rely on prompt guidance alone for memory budgets or tool-call limits; enforce caps in the host or server.

## Fit For Agentic Coding Lab

This is a high-fit design reference for procedural memory. The lab should reuse the workflow shape: pre-task recall, source-linked rules, post-task reflection, candidate validation, deterministic curation, feedback-driven confidence, and compact agent-readable output. The most directly reusable artifacts are the playbook schema ideas, curation phases, inline feedback contract, onboard/sample/read loop, degraded context output, and privacy/config boundaries.

The lab should implement the pattern in its own license-safe code and tighten the parts that remain heuristic. A practical version would use repo-local memory by default, explicit raw-session ingestion permissions, hard token and tool budgets, encrypted or redacted stores where needed, stronger provenance links, and a review queue for candidate rules before they become shared procedural memory.

## Reviewed Paths

- `README.md`, `CHANGELOG.md`, `package.json`, `LICENSE`, `SKILL.md`, `AGENTS.md`: product scope, agent protocol, install surface, license caveat, release history, and documented architecture.
- `src/cm.ts`: CLI command surface, agent JSON flags, TOON-related format flags, onboarding, privacy, serve, reflection, validation, feedback, and safety commands.
- `src/commands/context.ts`, `src/cass.ts`, `src/semantic.ts`, `src/output.ts`, `src/utils.ts`: context assembly, scoring, cass search/export/timeline, remote cass, sanitization, degraded behavior, structured output, and token-oriented output helpers.
- `src/orchestrator.ts`, `src/diary.ts`, `src/reflect.ts`, `src/validate.ts`, `src/curate.ts`: session-to-memory workflow, diary generation, LLM delta extraction, evidence gates, deterministic curation, promotions, demotions, and anti-pattern inversion.
- `src/playbook.ts`, `src/scoring.ts`, `src/tracking.ts`, `src/outcome.ts`, `src/commands/playbook.ts`, `src/commands/mark.ts`, `src/commands/outcome.ts`: playbook schema persistence, global/repo merging, blocked logs, feedback events, confidence decay, outcomes, and rule management.
- `src/commands/onboard.ts`, `src/gap-analysis.ts`, `src/onboard-state.ts`, `docs/AGENT_NATIVE_ONBOARDING.md`: agent-native manual rule extraction, gap-based sampling, session reading templates, and onboarding progress tracking.
- `src/config.ts`, `src/commands/privacy.ts`, `src/sanitize.ts`, `src/commands/serve.ts`: privacy defaults, cross-agent consent, repo config hardening, secret redaction, remote/MCP exposure, and auth boundaries.
- `src/trauma.ts`, `src/commands/trauma.ts`, `src/commands/guard.ts`, `src/trauma_guard_script.ts`: trauma registry, dangerous-pattern scanning, hook installation, and repeated-catastrophe prevention.
- `test/*context*`, `test/*reflect*`, `test/*curate*`, `test/*validate*`, `test/*onboard*`, `test/*privacy*`, `test/*serve*`, `test/*security*`, `test/*trauma*`, `test/*outcome*`, `test/*toon*`, `test/*lock*`, `test/*workflow*`: reviewed for behavioral evidence and coverage breadth.

## Excluded Paths

- `cm_illustration.webp`, `gh_og_share_image.png`, and other visual assets: documentation/marketing assets only.
- `competing_proposal_plans/**` and `docs/planning/**`: historical planning and alternative proposals; sampled for context but not treated as current execution paths.
- `.beads/**`, `.github/**`, install packaging, Homebrew/Scoop references, and release automation scripts: operational/project management surfaces outside the memory workflow.
- `bun.lock`, `package-lock.json`, generated build outputs, caches, and binary artifacts: dependency/build metadata rather than design behavior.
- Full candidate test execution in the cloned repo: not run for this research note because the task was a source review and the required verification is the research-index test suite.
