# gastownhall/beads

- URL: https://github.com/gastownhall/beads
- Category: agent-support-systems
- Stars snapshot: 23,537 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: da73b7511ccac8069a53fcb7a8963e8c9c9433a6
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong fit as a persistent work-context system for coding agents. Beads is most useful as a reference for durable task graph state, resumable notes, deterministic ready-work retrieval, agent-safe claiming, memory injection, and compaction recovery. It is less useful as a general semantic memory system because long-term memories are flat key/value records and retrieval is mostly structured SQL or substring search.

## Why It Matters

Coding agents lose context across sessions, compaction, crashes, and parallel work. Beads directly targets that failure mode by replacing ad hoc task files and chat-local plans with a Dolt-backed issue graph that agents can query and update. The important pattern is not only "issues in a database"; it is the combination of ready-work discovery, dependency semantics, atomic claims, notes-as-resume-state, persistent project memories, and startup/compaction hooks that rehydrate a coding agent with the current work frontier.

For this research category, Beads is a concrete memory-upgrade design: durable work context is stored outside the model context window, retrieval is command-driven and deterministic, compaction is treated as an explicit lifecycle event, and cross-agent coordination is part of the core workflow rather than an afterthought.

## What It Is

Beads is a Go CLI named `bd`, plus setup hooks, a plugin skill, and an MCP server. The backing store is Dolt, so the issue database is SQL-addressable and versioned. A project gets a `.beads/` directory with metadata, config, and either embedded Dolt storage or a connection to a Dolt SQL server.

The main user model is:

- `bd prime` prints agent instructions, ready-work guidance, and persistent memories.
- `bd ready` retrieves unblocked work.
- `bd show <id>` loads full durable context for one issue.
- `bd update <id> --claim` atomically claims work.
- `bd update <id> --append-notes ...` records handoff context.
- `bd close <id>` completes the work item.
- `bd remember`, `bd memories`, `bd recall`, and `bd forget` manage persistent project memories.

Beads also ships Codex and Claude hook installation paths, MCP tools for clients that prefer tool calls, examples for compaction workflows, and a Beads skill that teaches agents when to use `bd` instead of short-lived local task lists.

## Research Themes

- Token efficiency: The CLI path deliberately favors `bd prime` and compact command output over exposing large MCP schemas. The MCP integration also has lazy tool discovery, minimal issue models, field projections, and automatic result compaction when list-like responses exceed a threshold.
- Context control: Work context is split into structured fields: description, design, acceptance criteria, notes, labels, dependencies, comments, events, metadata, status, priority, assignee, and compaction fields. Agents retrieve the ready frontier first, then load details only for selected work.
- Sub-agent / multi-agent: The storage layer supports embedded single-writer mode and Dolt server mode for concurrent writers. The command layer has atomic claim operations, assignees, dependency-aware ready queues, worktree/context binding, routes, federation concepts, and local-only wisps/molecules for private execution traces.
- Domain-specific workflow: Beads is tuned for coding projects. Its skill resources describe session start, side-quest handling, compaction recovery, dependency planning, and resumable notes patterns such as COMPLETED, IN PROGRESS, BLOCKERS, KEY DECISIONS, and NEXT.
- Error prevention: The system validates issue status/type/metadata, records events on writes, computes content hashes, uses parameterized SQL for config and issue operations, blocks writes in read-only mode, detects sandbox limitations, warns about sensitive data, and has tests around memory, prime output, hooks, context routing, and MCP compaction.
- Self-learning / memory: `bd remember` stores durable key/value memories in the config table under `kv.memory.*`; `bd prime` injects them into the agent context. Issue notes and comments act as episodic work memory. There is no semantic memory index or embedding retrieval in the reviewed path.
- Popular skills: The strongest reusable skill patterns are `bd prime` as source of truth, `bd ready` for work selection, `bd show` for full context, `bd update --claim` for coordination, `bd update --append-notes` for handoff memory, `bd remember` for project knowledge, and `bd compact` for old closed work.

## Core Execution Path

Initialization creates the `.beads/` project store, metadata, config, optional AGENTS instructions, and client-specific integration files. README guidance asks agents to run `bd prime` first, avoid markdown task lists for project work, use `bd ready` to select work, claim before changing state, update notes while working, and close when done.

Creation flows through the Cobra command in `cmd/bd/create.go` into shared issue operations. `PrepareIssueForInsert` normalizes timestamps, validates fields, validates metadata, computes a content hash, generates a collision-resistant hash ID, and writes the issue, dependencies, labels, comments, and event rows in a transaction. Dolt-backed stores then add and commit the changed tables.

Retrieval starts with `bd ready`. The Dolt query layer builds a `WorkFilter`, excludes closed, in-progress, blocked, deferred, pinned, ephemeral, and internal workflow items unless requested, computes blocked IDs from dependency semantics, and sorts by priority and age. `bd show` loads the rich issue record with dependencies, dependents, labels, comments, and durable fields. `bd search` supports ID/title matching plus optional description, notes, status, and metadata filters.

Claiming is a central coordination primitive. `ClaimIssueInTx` only claims an open unassigned issue or an issue already assigned to the same actor. It sets assignee, status, started timestamp, and event history in one transaction. `ClaimReadyIssue` computes readiness and claims in the same storage transaction, reducing race windows for multiple agents.

Memory uses the config table rather than a dedicated memory table. `bd remember` stores `kv.memory.<key>` values, `bd memories` lists or substring-searches keys and values, `bd recall` loads one memory, and `bd forget` deletes it. `bd prime` reads these memories, sorts them, and injects them into startup context; `bd prime --memories-only` is used by compaction-related hooks.

Compaction is explicit. `bd admin compact --analyze` identifies old closed issues for review. `--apply --id --summary` lets an agent or operator provide a summary. The active apply path replaces description/design/notes/acceptance content with a compact summary, updates compaction metadata, and adds a comment with byte-savings information. Legacy automatic AI compaction exists, but Tier 2 automatic compaction is not implemented in the reviewed command path.

Codex hooks use `bd prime` on session start, run a memories-only check before compaction, write a refresh marker after compaction, and inject full prime output once on the next prompt. Claude setup also installs startup prime behavior. The key design is that compaction recovery is not left to the model; the toolchain tries to re-inject durable project context after the context window changes.

## Architecture

The architecture has four relevant layers:

- CLI layer: `cmd/bd` contains commands for create, ready, show, update, close, search, memory, prime, context, setup, compact, and hook handling.
- Storage layer: `internal/storage` defines interfaces for issue CRUD, dependency queries, annotations, config metadata, local metadata, version control, remotes, federation, bulk operations, compaction, and advanced queries.
- SQL operation layer: `internal/storage/issueops` centralizes common transactional logic for create, update, close, claim, config metadata, and compaction operations so Dolt and embedded Dolt stores share behavior.
- Integration layer: Codex/Claude setup files, the Beads skill, and `integrations/beads-mcp` expose the same durable context model to different agent hosts.

The persistent model is issue-graph first. Core tables include `issues`, `dependencies`, `comments`, `events`, `config`, `local_metadata`, `compaction_snapshots`, and `interactions`. Issue rows carry durable task context fields, workflow state, metadata, compaction state, and specialized flags for ephemeral, pinned, gate, molecule, work, and source-tracking behavior.

Dolt gives Beads versioned SQL history, branches, remotes, and optional server-mode concurrency. Embedded mode is simpler and local, but is effectively single-writer. Server mode is intended for multiple agents or orchestrators. Federation and route concepts extend this toward cross-repository or peer workflows, but the persistent coding-agent context loop works without adopting all of that surface area.

The MCP server wraps the CLI/storage behavior with context routing. It uses explicit `workspace_root`, persistent module-level workspace context, environment fallback, a connection pool keyed by canonical workspace, and ContextVars for request-scoped workspace. It deliberately returns minimal models and compacted list results to keep tool responses small.

## Design Choices

Beads chooses a structured issue graph over markdown plans. This makes readiness, dependency blocking, claims, status transitions, filtering, and audit history machine-queryable. The cost is that agents must use the CLI discipline consistently.

It treats `bd prime` as a generated source of truth instead of maintaining many static client instruction files. The Beads skill points to `bd prime` so agent guidance can evolve with the command implementation and project config.

It stores project memories as config key/value records. That keeps the memory feature cheap, auditable, and easy to inject into `bd prime`, while intentionally avoiding a heavier semantic memory stack.

It makes "ready work" a retrieval primitive. The dependency types matter: blocking dependencies affect readiness; related and discovered-from links preserve context without blocking the queue. That is a strong pattern for coding agents because not every relationship should change scheduling.

It separates private local traces from durable shared work through ephemeral/wisp concepts and local-only workflow artifacts. Architecture docs state wisps are never exported or synced and should be squashed into permanent digests when needed.

It makes compaction operator/agent-reviewable. The best current path is analyze first, then apply a summary. This matches coding-agent risk better than blind automatic summarization because old issue detail may contain subtle implementation rationale.

It excludes memories from export by default. Export requires `--include-memories` or `--all`, which is a sensible privacy default for agent memory.

## Strengths

The strongest idea is the durable ready frontier. Agents do not need to infer what to do from chat history; they can ask the database for unblocked work and then load one item deeply.

The notes and skill guidance are practical for resumability. The reviewed docs explicitly frame notes as the material a fresh agent needs after weeks away or after context compaction.

Atomic claim handling is a real multi-agent coordination primitive. It is much stronger than convention-only ownership in markdown files.

The prime and hook flow connects persistent state to model context at the right moments: session start, compaction, and post-compaction prompt submission.

The MCP design shows good token discipline. Lazy discovery, minimal models, explicit `show` for detail, and threshold-based compaction are patterns worth copying even without adopting Beads.

The security documentation is unusually candid for an agent tool. It states that issue data and memories can contain sensitive context, that there is no encryption at rest or built-in access control, that tracker tokens may be plaintext, and that Dolt telemetry must be disabled separately.

The codebase has targeted tests for the reviewed memory/context paths: memory CRUD and search, prime memory injection, Codex hooks, MCP result compaction, and context binding.

## Weaknesses

The system is large for the core need. Dolt modes, hooks, MCP, routes, federation, molecules, gates, wisps, integrations, setup files, and generated docs create a broad operational surface. A smaller research lab may want the patterns without the full stack.

The memory feature is simple key/value storage with substring search. That is reliable for a small project memory set, but it is not enough for large or ambiguous long-term memory unless paired with tagging, review workflows, or semantic retrieval.

Memories and issue content are plaintext in local project storage. Export excludes memories by default, but the underlying data still needs repository hygiene, permissions, and user discipline. There is no reviewed built-in encryption-at-rest or access-control layer for ordinary issue data.

Compaction is potentially lossy. The active apply path replaces rich fields with a summary and records metadata/comment history. Dolt history may help recovery, and a snapshot table exists in the schema, but the reviewed command path should be treated as destructive unless restore workflow is proven for the deployment.

Some docs lag code. MCP context docs still discuss older `set_context`/`where_am_i` concepts, while the current server exposes a unified `context` tool. Compaction examples also emphasize legacy automatic AI compaction more than the newer analyze/apply review loop.

Concurrency around embedded storage has sharp edges. Tests for memory/prime acknowledge one-writer-at-a-time behavior and a known Dolt engine shutdown race workaround in memory tests. Server mode is the safer fit for many agents.

## Ideas To Steal

Use a durable task graph as the primary work memory, not a sidecar. Agents should be able to ask for ready work, inspect one item, claim it, record notes, and close it.

Make "prime" a generated command. A single source that emits current project instructions, ready workflow, and memories is easier to keep correct than duplicated client docs.

Treat compaction as a lifecycle event. Add pre-compact memory checks and post-compact rehydration so the agent gets durable context back after the host compresses conversation history.

Keep list retrieval cheap and detail retrieval explicit. Minimal rows for `ready`/`list`, full detail for `show`, and result compaction for large responses are directly reusable in agent tools.

Use dependency semantics to separate scheduling from context. `blocks` should change readiness; `related` and `discovered-from` should preserve knowledge without freezing work.

Make ownership atomic. A compare-and-set claim operation prevents duplicate work better than agent etiquette.

Exclude sensitive memories from export by default, and force explicit opt-in for memory export.

Document resumability patterns directly in the tool skill: completed work, current state, blockers, decisions, and next steps.

## Do Not Copy

Do not copy the entire terminology surface unless users need it. Wisps, molecules, gates, routes, formulas, rigs, and federation create a lot of cognitive load around the excellent core work-memory pattern.

Do not rely on flat key/value memory as the only retrieval mechanism once memory count grows. Add tags, lifecycle review, provenance, or semantic retrieval if the use case requires broad long-term recall.

Do not make destructive compaction automatic by default. Require review, preserve originals, and verify restore/audit behavior before deleting rich work context.

Do not store secrets in agent memories or issue bodies without a stronger security model. Beads documents this risk clearly; an adaptation should enforce it with redaction or secret scanning if possible.

Do not expose large MCP schemas or verbose list payloads to coding agents by default. The CLI-first and compact-projection approach is a better fit for token-constrained work.

Do not adopt client-specific hook files without a generator or drift-control strategy. The value is in the hook lifecycle, not in hand-maintaining many integration formats.

## Fit For Agentic Coding Lab

Beads is in scope and high value for an agentic coding lab. The best adaptation is a lighter persistent work-context layer inspired by Beads: durable issues, dependency-aware ready retrieval, atomic claims, resumable notes, memory injection at session start, and compaction recovery. The Dolt backend is powerful when audit history, branches, remotes, and multi-writer server mode matter, but the lab should decide whether that operational cost is justified.

For this repository's research goals, Beads is a stronger candidate for "persistent work context" than for "general agent memory." It shows how to make work state durable, queryable, and safe across compaction. Its memory command is intentionally modest, so a memory-upgrade design should pair Beads-style task state with richer memory retrieval if the desired outcome is long-horizon knowledge accumulation.

## Reviewed Paths

- `/tmp/myagents-research/gastownhall-beads/README.md`: project overview, agent workflow, storage modes, setup expectations, memory commands, and compaction positioning.
- `/tmp/myagents-research/gastownhall-beads/SECURITY.md`: privacy, secret-handling, telemetry, permissions, export, and no-access-control caveats.
- `/tmp/myagents-research/gastownhall-beads/docs/ARCHITECTURE.md`: CLI/storage/Dolt architecture, issue model, dependency semantics, storage layout, and local-only wisps/molecules.
- `/tmp/myagents-research/gastownhall-beads/docs/DOLT.md`: embedded versus server mode, versioned SQL, history, backup/restore, remotes, and federation notes.
- `/tmp/myagents-research/gastownhall-beads/docs/ADVANCED.md`: advanced configuration and workflow surface relevant to context control.
- `/tmp/myagents-research/gastownhall-beads/docs/CODEX_INTEGRATION.md`: Codex setup and hook behavior.
- `/tmp/myagents-research/gastownhall-beads/docs/COLLISION_MATH.md`: ID collision rationale for hash IDs.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/create.go`: issue creation flags and input surface.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/ready.go`: ready-work command behavior, filters, JSON output, and claim option.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/show.go`: detailed context retrieval.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/search.go`: structured and text search behavior.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/update.go`: durable field updates, notes appends, metadata, claim behavior, and status transitions.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/memory.go`: remember, memories, recall, and forget implementation.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/kv.go`: user key/value validation and config prefix behavior.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/prime.go`: startup context generation, memory injection, MCP-aware output, hook JSON, and memories-only mode.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/codex_hook.go`: Codex SessionStart, PreCompact, PostCompact, and UserPromptSubmit hook flow.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/context.go`: context command surface and workspace identity behavior.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/context_cmd.go`: context rebinding and selected command behavior.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/compact.go`: analyze/apply/auto/Dolt-GC compaction command path.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/direct_mode.go`: direct backend mode setup.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/sandbox_unix.go`: sandbox detection path.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/errors.go`: read-only write blocking.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/setup/codex.go`: Codex hooks, skills, and config installation.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/setup/claude.go`: Claude hook setup and legacy-hook cleanup.
- `/tmp/myagents-research/gastownhall-beads/internal/types/types.go`: issue fields, metadata, compaction fields, flags, and content hash inputs.
- `/tmp/myagents-research/gastownhall-beads/internal/idgen/hash.go`: issue ID hash generation.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/storage.go`: storage interfaces and durable backend capabilities.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/compaction.go`: compaction interface.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0001_create_issues.up.sql`: issue table schema and indexes.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0002_create_dependencies.up.sql`: dependency graph schema.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0004_create_comments.up.sql`: comments schema.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0005_create_events.up.sql`: event history schema.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0006_create_config.up.sql`: config table used for memories.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0010_create_compaction_snapshots.up.sql`: compaction snapshot schema.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/schema/migrations/0014_create_interactions.up.sql`: interaction logging schema.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/issueops/config_metadata.go`: config reads/writes used by memories.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/issueops/create.go`: transactional issue creation.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/issueops/update.go`: transactional update and event recording.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/issueops/close.go`: close behavior and close event recording.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/issueops/claim.go`: atomic claim logic.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/issueops/compaction.go`: compaction eligibility, candidates, and apply metadata.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/dolt/issues.go`: Dolt-backed issue transactions and commits.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/dolt/queries.go`: ready-work query and blocked-ID computation.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/dolt/compact.go`: Dolt compaction store methods.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/embeddeddolt/issues.go`: embedded issue operations.
- `/tmp/myagents-research/gastownhall-beads/internal/storage/embeddeddolt/store.go`: embedded store behavior.
- `/tmp/myagents-research/gastownhall-beads/internal/compact/compactor.go`: legacy AI compaction path and summarization guardrails.
- `/tmp/myagents-research/gastownhall-beads/internal/compact/git.go`: commit hash recording for compaction.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/README.md`: MCP purpose, token tradeoffs, and workspace-root pattern.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/CONTEXT_ENGINEERING.md`: lazy schemas, minimal models, and result compaction strategy.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/CONTEXT_MANAGEMENT.md`: context persistence design notes and drift versus current server.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/src/beads_mcp/server.py`: MCP tools, context routing, compaction thresholds, and response models.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/src/beads_mcp/tools.py`: workspace discovery, ContextVar use, and connection pooling.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/src/beads_mcp/bd_client.py`: CLI wrapper models and sanitization.
- `/tmp/myagents-research/gastownhall-beads/plugins/beads/skills/beads/SKILL.md`: agent workflow, `bd` versus TodoWrite choice, session protocol, and compaction recovery.
- `/tmp/myagents-research/gastownhall-beads/plugins/beads/skills/beads/adr/0001-bd-prime-as-source-of-truth.md`: source-of-truth design for generated guidance.
- `/tmp/myagents-research/gastownhall-beads/plugins/beads/skills/beads/resources/RESUMABILITY.md`: notes-as-handoff guidance.
- `/tmp/myagents-research/gastownhall-beads/plugins/beads/skills/beads/resources/PATTERNS.md`: knowledge work, side quests, multi-session resume, and compaction recovery patterns.
- `/tmp/myagents-research/gastownhall-beads/plugins/beads/skills/beads/resources/WORKFLOWS.md`: session workflows and notes structure.
- `/tmp/myagents-research/gastownhall-beads/examples/compaction/README.md`: manual, cron, and legacy automatic compaction examples.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/memory_embedded_test.go`: memory CRUD, search, and concurrency test notes.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/prime_embedded_test.go`: prime output, memory injection, memories-only mode, and concurrent prime behavior.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/codex_hook_test.go`: Codex hook lifecycle and refresh-marker tests.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/context_cmd_test.go`: context command behavior.
- `/tmp/myagents-research/gastownhall-beads/cmd/bd/context_binding_test.go`: backend identity and environment override behavior.
- `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/tests/test_mcp_compaction.py`: MCP list compaction thresholds, previews, and `show` hints.

## Excluded Paths

- `/tmp/myagents-research/gastownhall-beads/.git/`: Git internals, not source or documentation.
- `/tmp/myagents-research/gastownhall-beads/website/` and `/tmp/myagents-research/gastownhall-beads/website/versioned_docs/`: static documentation site and versioned duplicates; canonical docs were reviewed under `docs/`.
- `/tmp/myagents-research/gastownhall-beads/npm-package/`, `/tmp/myagents-research/gastownhall-beads/winget/`, and installer packaging files: distribution wrappers, not persistent work-context architecture.
- `/tmp/myagents-research/gastownhall-beads/.github/`, `/tmp/myagents-research/gastownhall-beads/release-gates/`, and most of `/tmp/myagents-research/gastownhall-beads/scripts/`: CI, release, and maintenance machinery; excluded except where examples directly informed compaction.
- `/tmp/myagents-research/gastownhall-beads/docs/staged-for-removal/`: noncanonical or retired notes that could misrepresent current behavior.
- `/tmp/myagents-research/gastownhall-beads/go.sum`, `/tmp/myagents-research/gastownhall-beads/flake.lock`, `/tmp/myagents-research/gastownhall-beads/website/bun.lock`, `/tmp/myagents-research/gastownhall-beads/website/package-lock.json`, and `/tmp/myagents-research/gastownhall-beads/integrations/beads-mcp/uv.lock`: generated dependency locks.
- `/tmp/myagents-research/gastownhall-beads/THIRD_PARTY_LICENSES`: license inventory, not architecture.
- `/tmp/myagents-research/gastownhall-beads/website/static/img/`, `/tmp/myagents-research/gastownhall-beads/.github/images/`, and `/tmp/myagents-research/gastownhall-beads/cmd/bd/winres/`: binary/static/UI assets.
- `/tmp/myagents-research/gastownhall-beads/internal/jira/`, `/tmp/myagents-research/gastownhall-beads/internal/linear/`, `/tmp/myagents-research/gastownhall-beads/internal/github/`, `/tmp/myagents-research/gastownhall-beads/internal/gitlab/`, `/tmp/myagents-research/gastownhall-beads/internal/ado/`, and `/tmp/myagents-research/gastownhall-beads/internal/notion/`: external tracker adapters; relevant security and sync concepts were covered through docs, but adapter details are not central to coding-agent persistent context.
- Advanced workflow command families for molecules, gates, formulas, routes, rigs, and wisps were sampled through architecture, schemas, and skill docs but not exhaustively reviewed because the assigned focus was persistent work context, retrieval, memory, compaction, privacy, and verification.
- Example agents outside compaction examples, such as bash-agent, python-agent, library-usage, kanban, and tracker demos: useful demonstrations but not core architecture for persistent coding-agent context.
- The full test suite was not exhaustively read. Representative memory, prime, Codex hook, context, and MCP compaction tests were reviewed, and compaction/storage test locations were identified for follow-up if adopting the design.
