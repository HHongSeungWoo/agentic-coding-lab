# AVIDS2/memorix
- URL: https://github.com/AVIDS2/memorix
- Category: memory
- Stars snapshot: 456 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: dd399ec24f89facd5b59922b9ad833a53afbc7c2
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope reference for a local-first cross-agent memory and MCP control plane. Agentic Coding Lab should steal its typed memory schema, project binding, source-aware retrieval, session handoff, git evidence layer, and MCP tool profile ideas, but avoid copying the whole platform surface or its unauthenticated HTTP and plaintext local storage assumptions.

## Why It Matters
Memorix is not just another vector-memory wrapper. It implements a full coding-agent memory layer with stdio MCP, Streamable HTTP MCP, CLI commands, hook capture, git-derived memory, sessions, team coordination, mini-skills, and workspace/rules synchronization across Cursor, Claude Code, Codex, Windsurf, Gemini CLI, GitHub Copilot, Kiro, OpenCode, Antigravity, and Trae.

For Agentic Coding Lab, the useful part is the execution discipline: memories are typed, project-scoped, source-tagged, compacted for retrieval, and connected to commits, sessions, and handoffs. That makes it a high-value reference for cross-agent memory design rather than a simple store/search example.

## What It Is
Memorix is an Apache-2.0 TypeScript package and CLI. Its control plane exposes MCP tools over stdio (`memorix serve`) or HTTP (`memorix serve-http` / background mode), stores canonical memory in local SQLite, indexes retrieval in Orama, and optionally uses external LLM and embedding providers for extraction, compression, reranking, and vector search.

The core memory model has three main layers:

- Observation memory for what happened and how.
- Reasoning memory for why decisions, trade-offs, and conclusions were made.
- Git memory for commit-derived facts and repository evidence.

It also includes an optional Agent Team subsystem with durable agents, messages, tasks, dependencies, advisory file locks, roles, polling watermarks, and handoff notifications.

## Research Themes
- Token efficiency: Uses progressive disclosure through compact search, timeline, and detail calls; caps output with `maxTokens`; offers search tiers; suppresses command-log noise; optionally compresses narratives with an LLM; and reduces MCP surface with `lite`, `team`, and `full` tool profiles.
- Context control: Defaults search to the current project, requires explicit `projectRoot` for HTTP session binding, expands project aliases, uses session-layer context instead of dumping all memory, and separates L1 search summaries from L3 detail evidence.
- Sub-agent / multi-agent: Provides opt-in Agent Team tools for join, poll, task claim, message, handoff, and advisory locks, backed by SQLite rather than process memory.
- Domain-specific workflow: First-class coding-agent hooks, Git Memory, rules/workspace sync, mini-skill promotion, session start/end, handoff, and orchestration commands target software-engineering workflows directly.
- Error prevention: Includes project attribution checks, fail-closed git project detection for explicit binding, secret redaction on write/read, hook significance filters, git noise filters, retention/archive logic, localhost CORS defaults, and broad tests for store/search/session/team paths.
- Self-learning / memory: Formation pipeline extracts facts, resolves duplicates or evolution, evaluates value, tags core/contextual/ephemeral memory, supports consolidation, and promotes stable observations into mini-skills.
- Popular skills: Does not ship a generic skill marketplace. Its relevant pattern is promoting project observations into local mini-skills with provenance snapshots and injecting them during session start.

## Core Execution Path
Manual memory write starts in `memorix_store`. The server binds the request to a project, sanitizes content, optionally runs the formation pipeline, applies optional LLM compression, writes through `storeObservation`, updates SQLite, indexes Orama, records graph relations, and may launch embedding generation in the background.

Hook capture flows through `src/hooks/handler.ts`: normalize agent-specific payload, classify event, apply policy/significance filters, build an observation, store it with `sourceDetail: "hook"`, and never break the calling agent if persistence fails. The hook path intentionally treats file modifications and commands as stronger signals than reads or search results, with cooldowns and noise suppression.

Git Memory flows through `memorix ingest commit` and `src/git/extractor.ts`: read git metadata and diffs, infer commit type/entity/concepts, apply merge/trivial/generated-file filters, and store commit-derived observations with commit hashes and file stats. Retrieval can later surface git evidence beside observations and reasoning memories.

Search starts in `memorix_search`, which is project-scoped by default. Orama runs BM25 or optional hybrid/vector search, applies status/source/project filters, adds intent-aware boosts, post-filters project IDs for safety, and formats compact results. Users then call timeline or detail for deeper evidence. `compactDetail` can expand observations, reasoning, git evidence, cited commits, related entities, and mini-skill provenance.

Session context starts with `memorix_session_start(projectRoot=...)`. The server binds to a git project, optionally joins the team subsystem, creates or rolls over a session, and returns layered context: routing hints, recent handoff, high-value memories, session history, mini-skills, and evidence hints. `memorix_session_end` stores a sanitized handoff summary for the next agent.

## Architecture
The architecture is a local control plane around a shared project memory database:

- Control plane: `src/server.ts` exposes MCP tools; `src/cli/commands/serve.ts` handles stdio; `src/cli/commands/serve-http.ts` handles Streamable HTTP MCP plus dashboard API.
- Storage: `src/store/sqlite-store.ts` and `src/store/sqlite-db.ts` provide canonical local SQLite with WAL, migrations, atomic transactions, generation counters, observations, sessions, team tables, graph tables, and mini-skills.
- Indexing: `src/store/orama-store.ts` keeps an in-memory Orama index hydrated from SQLite, with optional embeddings and heavy-tier LLM reranking.
- Memory core: `src/memory/observations.ts` owns write/update/resolve paths, sanitization, enrichment, topic-key upserts, Orama indexing, and asynchronous embeddings.
- Formation: `src/memory/formation/*` implements extract, resolve, and evaluate stages, with deterministic rules and optional LLM assistance.
- Retrieval: `src/compact/engine.ts` implements compact search, timeline, and detail formatting as a three-level retrieval ladder.
- Project identity: `src/project/detector.ts` and `src/project/aliases.ts` derive canonical project IDs from git roots/remotes and map aliases for moved or differently opened repositories.
- Integrations: `src/hooks/*`, `src/workspace/mcp-adapters/*`, git ingestion commands, example MCP configs, and workspace sync commands bridge coding agents and IDEs.

Current code uses a flat local data directory, typically `~/.memorix/data/memorix.db`, with `projectId` columns and alias expansion for separation. Some older docs still describe per-project data directories and JSON state, so the code is the more reliable source.

## Design Choices
- Structured observations are preferred over opaque text chunks. The schema stores entity, type, title, narrative, facts, files, concepts, project ID, session ID, status, source, source detail, value category, commit links, related entities, creator agent, and write generation.
- Source-aware retrieval treats explicit memory, hook memory, git memory, and reasoning memory differently. This helps answer "what changed" from commits and "why" from reasoning.
- Topic keys give stable upsert targets for evolving facts, preventing duplicate append-only memory when an agent updates the same project fact.
- Formation is split into deterministic stages with injected dependencies, making it testable and usable in shadow or active mode.
- LLMs and embeddings are optional. The rules path still works when no provider key is present, and generated vectors are backfilled asynchronously.
- Retrieval is progressive. Search returns compact refs, timeline gives temporal slices, and detail expands evidence only when requested.
- MCP tool profiles constrain surface area. The default stdio profile is much smaller than the full audit/workspace/team/dashboard surface.
- Project binding is conservative. HTTP sessions are expected to pass `projectRoot`; stdio uses root notifications and git detection; explicit binding fails if no git project can be found.
- Team coordination is opt-in. Session start does not join the team unless requested, which keeps single-agent memory cheaper and quieter.

## Strengths
- End-to-end implementation covers capture, storage, retrieval, session recovery, handoff, team coordination, git evidence, and coding-agent integration.
- SQLite plus atomic transactions are a practical choice for local multi-agent durability. The store includes busy timeouts, WAL, foreign keys, migrations, and generation-based freshness checks.
- The observation schema carries provenance and lifecycle fields that are useful for trust decisions, retention, and conflict handling.
- Compact retrieval and typed detail refs are strong patterns for keeping context budgets under control.
- The formation pipeline has deterministic fallbacks, value tagging, duplicate/evolution handling, metrics, and tests.
- Git Memory gives repository-grounded evidence instead of relying only on conversational summaries.
- Hooks are defensive: they normalize many agent formats, skip reads and low-signal events, filter retrieved memory echoes, and avoid breaking the host agent.
- Session start builds layered context rather than dumping raw database contents.
- Tests cover memory formation, server integration, secret filtering, project detection, retention, team store operations, hook normalization/significance, workspace adapters, and storage concurrency.

## Weaknesses
- The product surface is broad. Memory, git, dashboard, orchestration, team, workspace sync, rules sync, mini-skills, hooks, and multiple transports all live in one package, which increases maintenance and review cost.
- Documentation has drift. Older design/module docs still describe JSON and per-project data directories while current code uses SQLite as the canonical flat local database.
- Local privacy is not the same as hard security. The SQLite database is plaintext, and there is no built-in encryption, access control, or per-project secret policy beyond redaction.
- HTTP mode has no authentication. It defaults to localhost and restrictive CORS, but Docker or `0.0.0.0` exposure would make the MCP/dashboard API risky.
- Optional LLM and embedding providers can send raw memory content to external APIs. The config supports this, but a stricter enterprise design would need explicit consent, redaction guarantees, and audit logs.
- Formation value scoring tags memory as core/contextual/ephemeral, but active server writes can still store low-value new memories unless the resolve stage discards them. Retention later handles decay, so the write-time quality gate is softer than the docs imply.
- Git ingestion uses shell command construction around the requested ref. A hostile `--ref` value could be dangerous if untrusted input reaches the CLI.
- Hook auto-capture still risks storing noisy or sensitive command/file events. The secret filter catches common tokens and assignments, not every possible secret format.
- Orama is an in-memory index rebuilt from SQLite. That is fine for a local tool, but it is not a distributed or strongly consistent search architecture.

## Ideas To Steal
- Use a typed memory record with `source`, `sourceDetail`, `valueCategory`, `status`, `sessionId`, `relatedCommits`, `relatedEntities`, and `writeGeneration`.
- Make project binding explicit at session start and default all search to the bound project.
- Provide a three-step retrieval ladder: compact search refs, timeline slices, and detailed evidence expansion.
- Separate observation, reasoning, and git evidence instead of mixing every memory into one undifferentiated vector namespace.
- Add stable topic keys for facts that evolve over time.
- Keep formation as a staged pipeline with deterministic rules, optional LLM help, stage metrics, and shadow mode.
- Use MCP tool profiles so a coding agent sees only the tools needed for its current mode.
- Treat handoff as both durable memory and a team message, with watermarks for polling agents.
- Store locally in SQLite, index in an in-memory search layer, and post-filter project IDs even when the search layer supports filtering.
- Add write-time and read-time secret redaction plus an attribution guard for likely wrong-project writes.

## Do Not Copy
- Do not copy the full platform surface into Agentic Coding Lab. A smaller memory/MCP subset would be easier to verify and operate.
- Do not expose an unauthenticated HTTP MCP/dashboard endpoint beyond loopback.
- Do not build git commands by interpolating user-provided refs into shell strings.
- Do not rely on plaintext local SQLite as the only protection for sensitive organization memory.
- Do not let hook auto-capture become the default source of durable truth without stronger review, sampling, or policy controls.
- Do not send raw codebase memory to LLM or embedding providers without explicit configuration, redaction, and auditability.
- Do not let docs describe one persistence model while code implements another.

## Fit For Agentic Coding Lab
Fit is high as a design reference and conditional as a dependency. Memorix demonstrates many of the patterns Agentic Coding Lab needs: cross-agent memory over MCP, project-safe retrieval, compact context recovery, git-backed evidence, session handoff, and opt-in multi-agent coordination.

The best adoption path is not wholesale integration. Agentic Coding Lab should extract the patterns into a narrower memory service: typed records, project binding, progressive retrieval, topic-key updates, git evidence links, session summaries, and a small MCP profile. Team tasks, dashboard UI, workspace migration, and orchestration should remain separate unless the lab specifically needs them.

## Reviewed Paths
- `/tmp/myagents-research/avids2-memorix/README.md`
- `/tmp/myagents-research/avids2-memorix/docs/ARCHITECTURE.md`
- `/tmp/myagents-research/avids2-memorix/docs/MEMORY_FORMATION_PIPELINE.md`
- `/tmp/myagents-research/avids2-memorix/docs/API_REFERENCE.md`
- `/tmp/myagents-research/avids2-memorix/docs/GIT_MEMORY.md`
- `/tmp/myagents-research/avids2-memorix/docs/CONFIGURATION.md`
- `/tmp/myagents-research/avids2-memorix/docs/AGENT_OPERATOR_PLAYBOOK.md`
- `/tmp/myagents-research/avids2-memorix/docs/DESIGN_DECISIONS.md`
- `/tmp/myagents-research/avids2-memorix/docs/MODULES.md`
- `/tmp/myagents-research/avids2-memorix/docs/PERFORMANCE.md`
- `/tmp/myagents-research/avids2-memorix/docs/KNOWN_ISSUES_AND_ROADMAP.md`
- `/tmp/myagents-research/avids2-memorix/src/server.ts`
- `/tmp/myagents-research/avids2-memorix/src/server/tool-profile.ts`
- `/tmp/myagents-research/avids2-memorix/src/cli/commands/serve.ts`
- `/tmp/myagents-research/avids2-memorix/src/cli/commands/serve-http.ts`
- `/tmp/myagents-research/avids2-memorix/src/cli/commands/ingest-commit.ts`
- `/tmp/myagents-research/avids2-memorix/src/index.ts`
- `/tmp/myagents-research/avids2-memorix/src/sdk.ts`
- `/tmp/myagents-research/avids2-memorix/src/types.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/observations.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/session.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/retention.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/disclosure-policy.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/secret-filter.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/attribution-guard.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/formation/index.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/formation/extract.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/formation/resolve.ts`
- `/tmp/myagents-research/avids2-memorix/src/memory/formation/evaluate.ts`
- `/tmp/myagents-research/avids2-memorix/src/store/sqlite-db.ts`
- `/tmp/myagents-research/avids2-memorix/src/store/sqlite-store.ts`
- `/tmp/myagents-research/avids2-memorix/src/store/obs-store.ts`
- `/tmp/myagents-research/avids2-memorix/src/store/persistence.ts`
- `/tmp/myagents-research/avids2-memorix/src/store/orama-store.ts`
- `/tmp/myagents-research/avids2-memorix/src/git/extractor.ts`
- `/tmp/myagents-research/avids2-memorix/src/git/noise-filter.ts`
- `/tmp/myagents-research/avids2-memorix/src/hooks/handler.ts`
- `/tmp/myagents-research/avids2-memorix/src/hooks/normalizer.ts`
- `/tmp/myagents-research/avids2-memorix/src/hooks/significance-filter.ts`
- `/tmp/myagents-research/avids2-memorix/src/hooks/pattern-detector.ts`
- `/tmp/myagents-research/avids2-memorix/src/team/team-store.ts`
- `/tmp/myagents-research/avids2-memorix/src/team/tasks.ts`
- `/tmp/myagents-research/avids2-memorix/src/team/messages.ts`
- `/tmp/myagents-research/avids2-memorix/src/team/file-locks.ts`
- `/tmp/myagents-research/avids2-memorix/src/compact/engine.ts`
- `/tmp/myagents-research/avids2-memorix/src/llm/provider.ts`
- `/tmp/myagents-research/avids2-memorix/src/llm/quality.ts`
- `/tmp/myagents-research/avids2-memorix/src/embedding/provider.ts`
- `/tmp/myagents-research/avids2-memorix/src/embedding/api-provider.ts`
- `/tmp/myagents-research/avids2-memorix/examples/cursor-mcp.json`
- `/tmp/myagents-research/avids2-memorix/examples/claude-desktop-config.json`
- `/tmp/myagents-research/avids2-memorix/examples/windsurf-mcp.json`
- `/tmp/myagents-research/avids2-memorix/memorix.example.yml`
- `/tmp/myagents-research/avids2-memorix/.env.example`
- `/tmp/myagents-research/avids2-memorix/tests/memory/formation/pipeline.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/integration/server.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/store/concurrency-atomicity.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/memory/secret-filter.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/project/detector.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/hooks/normalizer.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/hooks/significance-filter.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/team/team-store.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/team/tasks.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/team/messages.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/team/poll.test.ts`
- `/tmp/myagents-research/avids2-memorix/tests/workspace/mcp-adapters.test.ts`

## Excluded Paths
- `/tmp/myagents-research/avids2-memorix/.git/`: VCS internals; only git commands were used to record commit metadata.
- `/tmp/myagents-research/avids2-memorix/node_modules/`: Vendor dependencies were not present in the clone and are not part of the reviewed source.
- `/tmp/myagents-research/avids2-memorix/dist/`: Build output was not present and would be generated from reviewed TypeScript sources.
- `/tmp/myagents-research/avids2-memorix/package-lock.json`: Generated dependency resolution lockfile; excluded except for package context.
- `/tmp/myagents-research/avids2-memorix/assets/*.png`: Binary screenshots/logos; excluded because they do not define memory execution behavior.
- `/tmp/myagents-research/avids2-memorix/src/dashboard/static/*`: Dashboard presentation assets; excluded as UI-only after reviewing the HTTP/dashboard API surface in `serve-http.ts`.
- `/tmp/myagents-research/avids2-memorix/src/cli/tui/*`: Terminal UI presentation; excluded because the task focuses on memory/MCP execution paths, not UI rendering.
- `/tmp/myagents-research/avids2-memorix/articles/*` and `/tmp/myagents-research/avids2-memorix/README.zh-CN.md`: Marketing/localized narrative content; excluded because README, docs, and code covered the execution path.
- `/tmp/myagents-research/avids2-memorix/.github/workflows/*`, `/tmp/myagents-research/avids2-memorix/Dockerfile`, `/tmp/myagents-research/avids2-memorix/docker-compose.yml`, and `/tmp/myagents-research/avids2-memorix/.dockerignore`: Packaging/CI files; excluded from deep review except for the HTTP exposure implications noted above.
- `/tmp/myagents-research/avids2-memorix/.opencode/plugins/memorix.js`, `/tmp/myagents-research/avids2-memorix/.github/hooks/memorix.json`, `/tmp/myagents-research/avids2-memorix/.trae/rules/*`, and `/tmp/myagents-research/avids2-memorix/.windsurf/workflows/*`: Client configuration samples; excluded from deep review after verifying the broader integration matrix and examples.
