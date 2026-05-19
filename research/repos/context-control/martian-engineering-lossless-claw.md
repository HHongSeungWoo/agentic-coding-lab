# Martian-Engineering/lossless-claw

- URL: https://github.com/Martian-Engineering/lossless-claw
- Category: context-control
- Stars snapshot: 4,606 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: a97b4aef365c1a125bd68232252cd548d4084541
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value context-control reference. It is tightly coupled to OpenClaw, but its durable transcript store, summary DAG, prompt assembly rules, recall tools, and scoped expansion subagent are directly useful patterns for Agentic Coding Lab.

## Why It Matters

Most coding agents treat context compaction as a lossy in-prompt rewrite. `lossless-claw` separates the durable source of truth from the active prompt: every message is persisted in SQLite, compacted views are built from summaries plus a fresh raw tail, and recall tools can expand exact source material on demand.

That makes it a strong specimen for studying context control as infrastructure rather than a one-shot summarization prompt. The useful idea is not just "summarize old messages"; it is "keep raw history addressable, show the model compressed handles, and give it audited tools to recover details when exactness matters."

## What It Is

`lossless-claw` is an OpenClaw context-engine plugin distributed as `@martian-engineering/lossless-claw`. It registers lifecycle hooks, a context engine, recall tools, a visible `/lossless` command, a hidden `/lcm` alias, and a bundled skill that tells agents when to use those controls.

The plugin ingests OpenClaw JSONL transcripts into an LCM SQLite database, compacts older context into linked summaries, assembles prompt context under a token budget, externalizes large file and tool payloads, and exposes tools such as `lcm_grep`, `lcm_describe`, `lcm_expand`, and `lcm_expand_query` for retrieval.

## Research Themes

- Token efficiency: Uses leaf chunks, condensed summary levels, fresh-tail preservation, prompt-aware eviction, large-payload stubbing, file externalization, cache-aware deferred compaction, and optional dynamic leaf chunk sizing to reduce active prompt size without deleting raw history.
- Context control: Maintains an ordered `context_items` table of raw messages and summary references, reconciles JSONL transcript state on bootstrap, tracks session-key continuity, and controls `/new`, `/reset`, and `/lossless rotate` semantics explicitly.
- Sub-agent / multi-agent: Routes high-risk expansions through `lcm_expand_query`, which creates scoped grants and launches a delegated subagent. The low-level `lcm_expand` path is intentionally subagent-only in normal use.
- Domain-specific workflow: The summarizer prompt is tuned for coding-agent history: file operations, commands, paths, decisions, failures, and causal chains are supposed to survive summary layers.
- Error prevention: Provides live-context fallback, tool-call/result repair, SQLite integrity checks, transaction serialization, policy-denied model override failures, auth circuit breakers, safe file realpath validation, backups, doctor diagnostics, and rotate guards.
- Self-learning / memory: It acts as durable episodic session memory across resets and transcript rotation. It is not a preference-learning system; the memory is mostly conversation and artifact history.
- Popular skills: Ships `skills/lossless-claw/SKILL.md` with operational guidance for `/lossless status`, `/lossless doctor`, `/lossless doctor clean`, and session lifecycle questions.

## Core Execution Path

OpenClaw loads `index.ts`, which exports the plugin from `src/plugin/index.ts`. `register()` wires a shared LCM instance per normalized database path, registers the `lossless-claw` context engine, registers recall tools, registers the `/lossless` command, and injects a recall policy prompt before prompt construction.

The runtime loop is:

1. `bootstrap()` reconciles the OpenClaw session file into the SQLite store. It uses transcript checkpoints, hash anchors, import caps, and session-key rules to avoid replay floods or accidental conversation splits.
2. `afterTurn()` reads new transcript tail entries, deduplicates them by message identity, ingests message parts, evaluates compaction thresholds, and either compacts inline or records deferred compaction debt.
3. `maintain()` drains deferred compaction when the host allows it, can run transcript garbage collection when configured, and performs safe auto-rotation of oversized session files.
4. `assemble()` resolves `context_items` into prompt messages: compact XML summary blocks for old context plus raw fresh-tail messages. If assembly looks unsafe, empty, stale, or missing a user turn, it falls back to live context.
5. Recall tools search and expand the durable store when summaries are not enough.

Compaction runs in two phases. Leaf compaction replaces the oldest contiguous raw-message chunk outside the fresh tail with a leaf summary. Condensation then groups shallow same-depth summaries into higher-depth summaries. Both paths keep lineage rows, source time ranges, token counts, and file references.

## Architecture

The main layers are:

- Plugin integration: `src/plugin/index.ts`, `src/plugin/shared-init.ts`, `openclaw.plugin.json`, and `skills/lossless-claw` connect LCM to OpenClaw hooks, commands, config, tools, and agent instructions.
- Lifecycle engine: `src/engine.ts` owns bootstrap, ingest, after-turn maintenance, compaction orchestration, assembly, transcript rotation, and per-session operation queues.
- Storage: `src/db/connection.ts`, `src/db/migration.ts`, `src/store/conversation-store.ts`, and `src/store/summary-store.ts` manage SQLite schema, migrations, FTS fallback, conversations, messages, rich message parts, summaries, lineage, active context rows, large files, and bootstrap checkpoints.
- Compaction and summarization: `src/compaction.ts` selects chunks and replaces context ranges. `src/summarize.ts` builds prompts, resolves host-owned runtime LLM models, handles provider fallback, and avoids persisting bad summaries on auth failures.
- Prompt assembly: `src/assembler.ts` performs budgeted assembly, summary XML rendering, fresh-tail protection, optional prompt-aware eviction, large tool output stubbing, and tool-use/tool-result sanitation.
- Retrieval: `src/retrieval.ts` plus `src/tools/lcm-*.ts` implement grep, describe, direct expansion, delegated query expansion, grant checks, and recursion guards.
- Verification and operations: `src/integrity.ts`, `src/transaction-mutex.ts`, `src/plugin/lcm-command.ts`, and doctor modules implement health checks, backups, rotate commands, summary repair, and cleaner scans.

The database schema is central. It stores `conversations`, `messages`, `message_parts`, `summaries`, `summary_messages`, `summary_parents`, `context_items`, `large_files`, `conversation_bootstrap_state`, compaction telemetry, and migration state. Optional FTS5 tables index messages and summaries; when FTS5 is unavailable, the plugin keeps working through slower LIKE-based search.

## Design Choices

The strongest design choice is treating summaries as replaceable indexes over immutable raw history. The active prompt can be lossy, but the store remains lossless enough for later expansion.

The summary DAG is more useful than a rolling summary. Leaf summaries cite raw message ranges, condensed summaries cite child summaries, and expansion can walk back down the graph. This gives the agent compact context while preserving auditability.

The plugin uses explicit recall affordances instead of assuming the model will infer missing detail from summaries. The injected policy says exact commands, SHAs, paths, timestamps, config values, and causal chains require expansion.

It also keeps the model boundary host-owned. Summary and expansion calls go through OpenClaw `runtime.llm.complete`; explicit model overrides require OpenClaw policy allowlists. The plugin does not directly read provider credentials.

Finally, compaction is conservative around prompt-cache stability. Deferred compaction debt and cache-aware delay avoid changing the prompt prefix immediately after every threshold crossing.

## Strengths

- End-to-end context-control implementation, not just a summarization recipe.
- Durable raw-history storage with summary lineage and active-context indirection.
- Good recovery story: bootstrap checkpointing, anchor matching, import caps, append-only fast paths, and session-key rollover handling.
- Coding-agent-aware assembly, including rich message parts, reasoning blocks, tool calls, tool results, synthetic missing results, and orphan cleanup.
- Retrieval is designed for exactness: grep finds candidates, describe inspects one ID, expand recovers source ranges, and delegated expansion handles broader questions.
- Strong safety controls around expansion: grants have TTLs, conversation scopes, summary scopes, depth caps, token caps, revocation, recursion limits, and one active delegated expansion per origin.
- Practical operations surface: `/lossless status`, `/lossless backup`, `/lossless rotate`, `/lossless doctor`, `/lossless doctor apply`, and `/lossless doctor clean`.
- Test coverage targets real failure modes: migration drift, FTS unavailability, auth failures, circuit breakers, transcript repair, session queues, bootstrap floods, expansion grants, delegation recursion, rotate safety, and model-policy denial.

## Weaknesses

- Direct reuse is limited by tight OpenClaw coupling. The plugin depends on OpenClaw context-engine hooks, session stores, runtime LLM APIs, command plumbing, and transcript shape.
- Operational complexity is high: SQLite migrations, WAL behavior, optional FTS5 support, runtime LLM policy, background compaction, transcript rewrite, backup paths, and auto-rotation all need owner attention.
- Active summaries are still lossy. Raw history is retained, but if the agent trusts a weak summary instead of expanding, it can still act on incomplete context.
- Deterministic truncation is a safe fallback for continuity, but it is not a high-quality compression strategy. Doctor tooling detects some fallback and truncation markers, which is useful but also proves the fallback path is expected in production.
- Expansion grants and recursion state are process-local. That is acceptable for short delegated subagent runs, but a multi-process or distributed lab would need persistent or host-mediated grant state.
- Optional FTS5 creates portability friction. The fallback preserves behavior, but search quality, ranking, and snippets are weaker without the Node SQLite FTS5 build.
- The delegated expansion path relies on a subagent returning structured JSON. The code handles parse and policy errors, but the control surface is much larger than direct retrieval.

## Ideas To Steal

- Store raw history durably, then make the prompt a controlled view over that store.
- Represent compacted history as a DAG with source IDs, timestamps, descendant counts, source token counts, and parent links.
- Put summary IDs in the prompt so recall tools have stable handles.
- Preserve a fresh raw tail even when it exceeds budget; evict older context first.
- Treat exact values in summaries as hints until expanded from source.
- Give the main agent search and describe tools, but require scoped delegated expansion for broad recovery tasks.
- Use grants with TTL, token budget, depth, conversation, and summary constraints for recall subagents.
- Reconcile transcripts from checkpoints and anchors; skip unsafe persistence if reconciliation cannot prove continuity.
- Defer prompt-mutating compaction when cache stability matters.
- Externalize large file and tool payloads into addressable records with compact prompt references.
- Sanitize tool-call/result pairing before assembled history reaches the model.
- Serialize per-session work and use database savepoints for nested transactional sections.

## Do Not Copy

- Do not copy the whole OpenClaw plugin surface into a different agent harness. Extract the store, assembly, compaction, and recall patterns instead.
- Do not make LLM summaries the only recovery path. The valuable property is raw-history retention plus expansion.
- Do not use process-local grants if expansion can cross processes, hosts, or long-lived sessions.
- Do not add transcript rewriting or auto-rotation without backups, dry-run style diagnostics, and clear skip conditions.
- Do not rely on FTS5-only retrieval unless the target runtime controls its SQLite build.
- Do not treat deterministic truncation as a normal compression outcome. It should remain a degraded fallback that health checks can surface.
- Do not expose low-level expansion directly to the main agent without scope and recursion controls.

## Fit For Agentic Coding Lab

This is a high-fit pattern source for the context-control category. Agentic Coding Lab should not adopt it as-is unless the lab standardizes on OpenClaw, but it should copy several design invariants:

- A durable conversation store is separate from the active prompt.
- Every compacted prompt item has an expansion path.
- Context assembly is deterministic, budget-aware, and testable.
- Retrieval tools are part of the context protocol, not an afterthought.
- Summary quality, transcript continuity, and tool-pair validity are verified continuously.

The best lab translation would be a harness-neutral context engine contract: ingest transcript events, maintain a summary DAG, assemble a prompt view, expose recall tools, and verify invariants after compaction.

## Reviewed Paths

- `README.md`: plugin purpose, install flow, commands, configuration, session semantics, and recall tool overview.
- `docs/architecture.md`, `docs/configuration.md`, `docs/agent-tools.md`, `docs/fts5.md`: architecture, LCM lifecycle, config defaults, runtime LLM policy, FTS behavior, and operations.
- `skills/lossless-claw/SKILL.md`, `skills/lossless-claw/references/architecture.md`, `skills/lossless-claw/references/config.md`, `skills/lossless-claw/references/diagnostics.md`, `skills/lossless-claw/references/recall-tools.md`, `skills/lossless-claw/references/session-lifecycle.md`: agent-facing operational guidance.
- `package.json`, `openclaw.plugin.json`, `index.ts`: package metadata, plugin manifest, tool contract, context-engine kind, config surface, and entry point.
- `src/plugin/index.ts`, `src/plugin/shared-init.ts`, `src/plugin/lcm-command.ts`, `src/plugin/lcm-doctor-shared.ts`, `src/plugin/lcm-doctor-cleaners.ts`, `src/plugin/lcm-doctor-apply.ts`: registration, singleton DB ownership, prompt policy injection, slash commands, doctor diagnostics, cleanup, and repair.
- `src/engine.ts`, `src/compaction.ts`, `src/summarize.ts`, `src/assembler.ts`, `src/retrieval.ts`, `src/large-files.ts`, `src/integrity.ts`, `src/transcript-repair.ts`, `src/transaction-mutex.ts`: core runtime, compaction, assembly, retrieval, large payload handling, verification, and concurrency controls.
- `src/db/config.ts`, `src/db/connection.ts`, `src/db/migration.ts`, `src/store/conversation-store.ts`, `src/store/summary-store.ts`: configuration, SQLite connection policy, schema, migrations, storage, FTS fallback, and active context persistence.
- `src/tools/lcm-grep-tool.ts`, `src/tools/lcm-describe-tool.ts`, `src/tools/lcm-expand-tool.ts`, `src/tools/lcm-expand-query-tool.ts`, `src/expansion-auth.ts`, `src/expansion-policy.ts`, `src/tools/lcm-expansion-recursion-guard.ts`: recall tool behavior, grant enforcement, delegated expansion, and routing policy.
- `test/*.test.ts`: representative coverage for config, manifest drift, runtime LLM integration, migrations, engine lifecycle, assembler tool blocks, retrieval tools, expansion grants, delegated expansion, circuit breakers, large files, transcript repair, session queues, bootstrap flood prevention, doctor commands, and rotate safety.

## Excluded Paths

- `dist/`: not present in the reviewed checkout; package output is generated by the build.
- `package-lock.json`: dependency lockfile, useful for reproducible install but not for design review.
- `tui/**` and `docs/tui.md`: optional Go TUI and admin workflows. They are operationally relevant but not on the core OpenClaw context-engine execution path.
- `scripts/stub-tier-*.mjs`, `scripts/lcm-blob-migrate.mjs`: release or migration helper scripts; source runtime and tests gave the execution-path evidence needed here.
- `audit/**`, `specs/**`, `architecture/stub-tier-stratification.md`: historical audit, planning, and design artifacts. Reviewed implementation and tests instead of treating specs as ground truth.
- `RELEASING.md`, `CHANGELOG.md`, `LICENSE`, `README_zh.md`, `Dockerfile`, `doctor-contract-api.*`: release, legal, translation, container, and compatibility-support files outside the core context-control path.
- Generated, vendor, binary, and UI-only assets: no vendored dependency tree or binary runtime artifacts were part of the reviewed source tree; optional UI/admin paths were excluded as listed above.
