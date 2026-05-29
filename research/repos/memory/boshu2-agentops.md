# boshu2/agentops

- URL: https://github.com/boshu2/agentops
- Category: memory
- Stars snapshot: 371 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 4107bbed1c00fee246de9a1da75001ae3b4da9a4
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong design reference for coding-agent operational memory and validation loops, but better mined for patterns than adopted as a dependency. The useful core is the file-backed memory ledger with citations, feedback, promotion, and gates; the risky parts are surface-area sprawl, hookless-versus-hook doc drift, and insufficiently uniform secret hygiene across transcript-forging paths.

## Why It Matters

AgentOps is directly relevant to a coding-agent lab because it treats memory as an operational control loop, not just recall. The repo combines local durable state, retrieval, session closeout, promotion rules, feedback scoring, validation gates, and runtime-specific plugin/skill surfaces around day-to-day coding-agent work. Its strongest contribution is the idea that every session should leave reviewable artifacts that future sessions can cite, reuse, and demote when they stop helping.

The project is also useful as a cautionary case. It has multiple generations of architecture in the tree: the current 3.0 direction is hookless and pull-based, while older docs, skills, env vars, and plugin shims still describe hook-oriented behavior. That makes it a good source of design primitives, but a poor model to copy wholesale without pruning the interfaces.

## What It Is

AgentOps is a local operational layer for coding agents such as Claude Code, Codex, Cursor, and OpenCode. It installs skills, plugin metadata, and a Go CLI named `ao`. The system stores working memory and operational evidence in repo-local `.agents/` files plus optional global memory, then uses commands such as `ao lookup`, `ao search`, `ao forge`, `ao flywheel close-loop`, `ao feedback-loop`, `ao maturity`, `ao compile`, `ao session bootstrap`, and `ao rpi phased` to assemble context, close sessions, score memories, and enforce validation.

The current north-star docs describe a hookless loop: agents explicitly pull dense context, do bounded work, validate, forge session output, and promote learnings into a corpus. Optional hooks and runtime shims still exist, but they are no longer the preferred default. The repo ships both Claude and Codex plugin manifests, skill catalogs, generated CLI docs, schemas, RPI orchestration code, and local memory examples.

## Research Themes

- Token efficiency: Context is pulled just in time through `ao lookup`, `ao search`, `ao inject`, and fixed-slot startup packets rather than pushed constantly. Retrieval supports token budgets, simple decay, utility weighting, source filters, section locators, bead boosts, and skill-level context declarations. RPI phases and worker handoffs try to compress state into disk artifacts instead of carrying everything in resident context.
- Context control: The primary control plane is the `.agents/` filesystem corpus plus root documents such as `AGENTS.md`, `MEMORY.md`, `GOALS.md`, and schema-gated JSON/Markdown artifacts. Skill frontmatter can declare context windows and section filters, while RPI commands write phase results, ledgers, state, and checkpoints that later sessions can inspect.
- Sub-agent / multi-agent: The repo supports council-style review, crank/swarm work, RPI parallel execution, team specs, worker-output schemas, quarantine for invalid worker results, and a "fresh context per phase or worker, lead-only commit" doctrine. The strongest pattern is using disk-backed artifacts and worktree isolation as the coordination medium.
- Domain-specific workflow: The workflow is tuned for coding agents using BDD acceptance, TDD slices, DDD/hexagonal boundaries, beads, pre-mortems, vibe checks, postmortems, and closeout rituals. The memory system is inseparable from this software-factory vocabulary.
- Error prevention: Validation appears at several layers: schemas, CI checks, phase-result gates, flywheel gates, RPI ledger verification, council review, vibe/pre-mortem commands, release readiness artifacts, and skill checks. The docs repeatedly reject self-grading as sufficient proof and prefer fresh-agent or CI-backed validation.
- Self-learning / memory: The flywheel stages are work, forge, pool, promote, learnings, and inject. Citations record which artifacts were retrieved, referenced, or applied. Feedback updates utility scores, maturity jobs age or archive stale items, and promotion rules convert repeated observations into learnings, patterns, skills, templates, or validation gates.
- Popular skills: The most relevant skill surfaces are `using-agentops`, `inject`, `forge`, `flywheel`, `research`, `council`, `validate`, `vibe`, `goals`, `push`, `rpi`, `implement`, `retro`, and the Codex-specific skill catalog exposed through `.codex-plugin/plugin.json`.

## Core Execution Path

A normal 3.0-style run starts with an agent reading root guidance and running `ao session bootstrap` or an equivalent plugin/bootstrap shim. The agent then retrieves local context through `ao lookup`, `ao search`, `ao corpus inject`, or the deprecated `ao inject` path. Retrieval reads local and optional global learnings, patterns, recent sessions, findings, and predecessor handoffs, scores them by lexical match, freshness, utility, maturity, and source boosts, and can record citation events for later feedback.

During work, the agent follows a bounded loop: shape BDD intent, slice vertically, implement with tests, run validation, record evidence, and keep phase state on disk. For larger jobs, `ao rpi phased` runs discovery, implementation, and validation as separate runtime sessions with persisted state under `.agents/rpi/`, optional isolated worktrees, heartbeat files, per-phase result artifacts, and gates for pre-mortem and vibe reports. Parallel/team execution uses schemas and quarantine files to make invalid worker outputs inspectable rather than silently accepted.

At closeout, `ao forge transcript` parses Claude or Codex JSONL, extracts decisions, failures, solutions, learnings, and references, and writes session/memory artifacts plus pending knowledge. `ao flywheel close-loop` ingests pending items into the knowledge pool, scores specificity, actionability, novelty, context, and confidence, promotes qualifying items, records citation feedback, updates store indexes, and applies maturity transitions. `ao feedback-loop` applies reward signals to cited artifacts, while `ao maturity`, `ao compile`, `ao memory sync`, and notebook commands prune, compile, and surface the corpus for later sessions.

## Architecture

The outer architecture has four practical layers. The skill/plugin layer tells agents how to operate, supplies Codex and Claude plugin metadata, and exposes startup prompts or commands. The CLI layer is the Go `ao` binary with commands for retrieval, forging, RPI, evaluation, gates, memory maintenance, search, corpus capture, and runtime lifecycle shims. The storage layer is file-backed Markdown and JSONL in `.agents/`, with schemas for handoffs, memory packets, findings, eval runs, release readiness, worker output, team specs, and session quality. The orchestration layer includes RPI phased/loop execution, ledger verification, worker quarantine, optional hook adapters, and substrate-facing runtime modes.

Internally, the Go code leans toward ports-and-adapters structure in newer areas: domain types, command adapters, storage adapters, runtime adapters, parser/extractor packages, safety checks, and lifecycle orchestration. The search path is mostly lexical and local-file based. The LLM-assisted forge path is optional; tier-zero extraction is regex/keyword based, while tier-one chunking can redact and summarize transcripts before writing durable session notes.

## Design Choices

AgentOps chooses local-first durability over a hosted memory service. Most state is plain Markdown or JSONL, which keeps the corpus inspectable, grep-friendly, and compatible with different agent runtimes. This also makes repository hygiene important because the same artifacts can contain sensitive operational details.

The current design chooses hookless context pull as the default. Earlier hook bundles caused too much noise and resident context, so 3.0 prefers explicit `ao` calls and dense just-in-time packets. The repo still keeps optional hook and lifecycle shims for runtimes that support them, which gives migration flexibility but creates documentation drift.

The memory model is citation-centered. Retrieval is not just "show me context"; it can log that a learning was retrieved or applied, and later feedback adjusts its utility. Promotion is staged through pending items, a pool, learnings, patterns, skills, templates, and gates. This gives the system a way to distinguish one-off observations from operational constraints.

The validation model treats agent output as untrusted until independently checked. The docs prefer CI, fresh-agent review, phase gates, acceptance scenarios, and stored evidence over self-reported completion. RPI also writes a hash-chained ledger and phase state so loop progress can be audited after interruptions.

## Strengths

AgentOps has a unusually complete model of operational memory for coding agents. It connects retrieval, citations, feedback, promotion, maturity, and closeout instead of leaving memory as a bag of notes. The local-file approach makes the mechanism inspectable and easy to adapt without depending on a service.

The system is explicit about context budgets and compaction resilience. Fixed-slot startup packets, token limits, phase summaries, handoff files, and disk-backed state are all practical responses to long coding sessions losing conversational memory.

The validation posture is strong. Pre-mortems, vibe checks, council review, CI gates, phase-result checks, RPI verification, and "no self-grade" doctrine all push the system toward evidence-backed completion.

The plugin and skill surfaces are broad enough to study runtime integration patterns across Codex and Claude. The repo shows how a memory workflow can be distributed through skills, generated docs, plugin manifests, command wrappers, and root instructions.

The RPI implementation is valuable as a reference for long-running agent work. It includes phase isolation, lease locks, heartbeat/state files, worktree management, supervisor loops, hash-chained ledgers, and explicit cleanup/cancel paths.

## Weaknesses

The surface area is much larger than the core idea. A new adopter must navigate skills, generated CLI docs, older architecture docs, hook docs, RPI subsystems, Codex shims, Claude plugin files, evals, memory maintenance, and multiple closeout paths before finding the minimal loop.

There is real hookless-versus-hook drift. The 3.0 docs say default install is zero hooks and explicit commands, but other docs, skills, env vars, and the Codex shim still describe hook/session-end behavior. That ambiguity matters for safety because lifecycle hooks can mutate local state at moments the operator may not expect.

Some "read" surfaces are not purely read-only. `ao inject` is deprecated but still records citations by default, and `--apply-decay` can mutate learning frontmatter. The inject skill describes the path as read-only, so callers could underestimate side effects.

Secret handling is uneven across transcript paths. Tier-one LLM forge redacts secrets and home paths before chunking, but tier-zero transcript parsing and extraction appear to operate on raw transcript content before writing session or pending-knowledge artifacts. A memory system should apply redaction before every durable write, not only before optional summarization.

The default scoring and extraction are pragmatic but shallow. Search is lexical, extraction is largely keyword/regex based in the non-LLM path, and utility depends on citation/feedback hygiene. Without disciplined feedback and curation, the corpus can become noisy or reinforce stale local conventions.

The repo says repo-root `.agents/` should not be tracked because it may contain sensitive or noisy operational state, yet `.gitignore` intentionally allowlists some `.agents` paths and `MEMORY.md` can be synced into the repo root. That can work for this project, but it is not a safe default for all teams.

## Ideas To Steal

Use a file-backed memory ledger where every retrieved or applied memory can earn citations and feedback. This is more actionable than dumping notes into a vector store because it creates a visible trail from context to outcome.

Adopt the promotion ratchet: one observation goes to handoff, repeated observations become learnings, behavior-changing learnings become skills or templates, and must-not-regress lessons become validation gates. This gives memory a path from anecdote to enforcement.

Separate session closeout into forge, pool, promote, feedback, maturity, and compile stages. Each stage can be tested, audited, retried, or skipped explicitly instead of hiding all learning behind a single post-run script.

Use skill-level context declarations and fixed retrieval slots. A coding agent should be able to ask for the kind of context a task needs, with token budgets and section filters, instead of always reading the same monolithic memory block.

Copy the RPI idea of phase state and ledger artifacts for long jobs. Discovery, implementation, and validation should leave small machine-readable result files and an auditable progress ledger so interrupted work can resume cleanly.

Quarantine invalid worker outputs with raw output, reason, schema, terminal state, attempts, and timestamp. This is a useful safety pattern for multi-agent work because it preserves failure evidence without letting malformed data enter the main corpus.

## Do Not Copy

Do not copy both a hookless doctrine and hook-heavy docs without a strict compatibility boundary. A lab implementation should have one authoritative lifecycle path and label optional adapters as optional.

Do not call retrieval read-only if it records citations, updates decay, or mutates frontmatter. Split pure lookup from feedback-producing lookup, or make side effects explicit in the command name and output.

Do not store raw transcript snippets before redaction. Redaction should happen at the parser boundary before extraction, pending-knowledge writes, session notes, and search indexing.

Do not adopt the entire command and skill surface before proving the core loop. Start with lookup, citation logging, forge, promotion, feedback, and maturity. Add RPI, councils, and plugin shims only after the memory loop has clear behavior.

Do not track broad `.agents/` state or sync root memory by default in projects with sensitive code, customer data, or private operational context. Keep local memory private unless artifacts are explicitly scrubbed and selected for version control.

Do not rely on simple keyword extraction or lexical scoring for high-trust memory. Use it as a cheap baseline, then add evidence, citations, holdout tests, and human or independent-agent review for memories that become constraints.

## Fit For Agentic Coding Lab

Fit is high as a design source and conditional as a direct tool. The repo contains many of the pieces an agentic coding lab needs: local operational memory, citations, feedback loops, session closeout, validation gates, multi-agent state, plugin surfaces, and cross-session persistence. The best path is to borrow the smallest coherent loop and reimplement it with stricter safety defaults.

For this lab, the most valuable pieces are the citation-backed memory ledger, the promotion ratchet, the explicit closeout pipeline, and the evidence-first validation posture. The less suitable pieces are the full CLI breadth, mixed hook history, mutable retrieval surfaces, and project-specific workflow vocabulary that would be hard to impose on another repo unchanged.

## Reviewed Paths

- `README.md`: High-level product framing, 3.0 hookless stance, memory/validation/flywheel layers, local state model, and runtime neutrality.
- `AGENTS.md`, `AGENTS-RUNTIME.md`, `AGENTS-WORKFLOW.md`, `MEMORY.md`: Root operating instructions, runtime safety, workflow gates, and examples of persistent project memory.
- `docs/3.0.md`, `docs/how-it-works.md`, `docs/knowledge-flywheel.md`, `docs/context-lifecycle.md`: Current loop model, hookless migration, context compiler, flywheel stages, and cross-session memory lifecycle.
- `docs/ARCHITECTURE.md`, `docs/SCHEMAS.md`, `docs/ENV-VARS.md`, `docs/architecture/operating-loop.md`, `docs/architecture/canonical-loop-model.md`, `docs/architecture/ports-and-adapters.md`: Architecture claims, schema catalog, env-var surface, operating loop, and port/adapter framing.
- `docs/cli/*.md`: Generated command docs for lookup/search/inject, forge, flywheel, feedback-loop, maturity, codex lifecycle, session bootstrap/close, corpus, compile, RPI, eval, gates, doctor, skills, findings, and harvest.
- `cli/cmd/ao/inject.go`, `cli/cmd/ao/inject_context.go`, `cli/cmd/ao/inject_bead.go`, `cli/cmd/ao/lookup*.go`, `cli/cmd/ao/search*.go`: Context retrieval, scoring inputs, citation recording, bead boosts, and skill-context declarations.
- `cli/internal/search/*.go`: Learning, pattern, session, predecessor, index, and retrieval scoring types and implementations.
- `cli/cmd/ao/forge.go`, `cli/internal/parser/*.go`, `cli/internal/llm/*.go`: Transcript parsing, extraction, optional redaction/chunking, session writing, and forge paths.
- `cli/cmd/ao/flywheel*.go`, `cli/cmd/ao/feedback*.go`, `cli/cmd/ao/maturity*.go`, `cli/internal/lifecycle/*.go`: Close-loop orchestration, feedback application, citation handling, memory promotion, and maturity transitions.
- `cli/cmd/ao/codex*.go`, `.codex/agentops-codex`, `.codex-plugin/plugin.json`, `.claude-plugin/plugin.json`: Codex lifecycle shims, plugin manifests, startup/stop behavior, and runtime integration surface.
- `cli/cmd/ao/session_*.go`, `cli/cmd/ao/rpi_*.go`, `cli/internal/rpi/*.go`, `cli/internal/safety/*.go`, `cli/internal/agentworker/*.go`: Session bootstrap/closeout, phased RPI, loop state, ledgers, sandbox/team validation, and worker quarantine.
- `skills/using-agentops/SKILL.md`, `skills/inject/SKILL.md`, `skills/forge/SKILL.md`, `skills/flywheel/SKILL.md`, `skills-codex/**`: Representative skill surfaces for memory injection, forging, flywheel operation, and runtime-specific guidance.

## Excluded Paths

Packaging, release, and distribution files such as Homebrew, GoReleaser, Dependabot, changelog, and license metadata were not reviewed in depth because they do not affect the memory or validation model.

Static UI assets, generated watch pages, MkDocs presentation files, and non-operational documentation styling were excluded except where they linked to core architecture or CLI behavior.

Test fixtures, historical `.agents/nightly` artifacts, and generated corpus outputs were sampled only when they clarified schemas or state shape. They were not exhaustively reviewed because the target was the operational design, not fixture completeness.

The full eval corpus and every skill variant were not exhaustively read. Representative eval, skill, plugin, and command surfaces were reviewed to understand memory, feedback, verification, hook, and plugin boundaries.

Git internals and vendored/cache artifacts were excluded. The reviewed commit, source files, generated CLI docs, schemas, and runtime guidance were sufficient to evaluate the candidate.
