# zhangfengcdt/memoir

- URL: https://github.com/zhangfengcdt/memoir
- Category: memory
- Stars snapshot: 554 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: a897a3f4db37b46bce456ccf76ab27986e0caf8c
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for branch-aware, taxonomy-structured memory for coding agents. The strongest ideas are semantic paths, Git-like branches, path-first recall, per-code-branch memory isolation, and lifecycle hooks for Codex/Claude Code. Do not adopt wholesale without tightening schema consistency, MCP/SDK adapter tests, secret handling, and historical-version semantics.

## Why It Matters

Memoir is directly relevant to the Agentic Coding Lab memory track because it treats agent memory as versioned project state instead of a flat prompt file or opaque vector store. The repo combines a Python CLI and SDK, a ProllyTree-backed store, branch and merge services, taxonomy-aware recall, watch-indexed vector search, and first-party Codex/Claude Code plugins.

The most reusable pattern is the agent-facing contract: use semantic keys such as `preferences.coding.style`, keep memories branch-scoped with the code branch, inject only a compact key inventory at session start, and let the agent fetch exact facts on demand. That is a better fit for coding agents than dumping all memory into every prompt.

## What It Is

Memoir is a Python package named `memoir-ai` with CLI commands (`memoir`), an MCP stdio command (`memoir-mcp`), a service layer, a Python SDK, a LangGraph store adapter, a local UI/TUI, and bundled Codex and Claude Code plugins. The durable store is a Git repository containing ProllyTree data; new stores default to the ProllyTree File backend and persist a `.git/memoir-backend` lock.

Memory writes can follow two paths. The main CLI/service path stores one value per taxonomy key with fields such as `content`, `confidence`, `timestamp`, and `related_keys`. The older SDK/LangMem-oriented manager stores aggregated `memories[]` at each semantic path. The search and memento code handles both shapes, but the split is an important design caveat.

## Research Themes

- Token efficiency: Semantic keys, `summarize --depth 3`, batched `get`, path-provided `remember -p`, prompt-cache markers, and SessionStart key inventories reduce repeated prompt bulk. The Codex `memory-recall` skill deliberately avoids `memoir recall` and uses two fast CLI calls for ordinary stores.
- Context control: Namespaces separate `default`, `codebase:onboard`, `project:onboard`, `taxonomy:v1`, `watch`, and metrics. Recall excludes metrics by default, branch routing restores the checked-out branch, and onboarding snapshots are injected as compact maps rather than full files.
- Sub-agent / multi-agent: Memory branches auto-match code branches, `MEMOIR_BRANCH` and `--branch` provide per-call routing, `sync-branch` promotes default-namespace keys, and heartbeat files warn about concurrent sessions. This is branch isolation for multiple agent sessions, not a full multi-agent coordinator.
- Domain-specific workflow: The richest integration target is coding agents. Codex and Claude Code hooks provide SessionStart context, UserPromptSubmit recall nudges, Stop auto-capture, code-change metrics, manual remember/status/UI skills, and repo onboarding snapshots.
- Error prevention: Store creation refuses to initialize inside unrelated Git repos with commits, backend locks prevent backend drift, Git GC hardening protects ProllyTree nodes, read commands reject missing branches, Stop capture defaults to silence, and manual writes bypass nested package LLM calls.
- Self-learning / memory: LLM classification, dynamic taxonomy loading, profile/timeline/location mementos, automatic Stop capture, manual `memoir-remember`, watch-based document ingestion, and branch promotion provide a credible memory lifecycle.
- Popular skills: `memory-recall`, `memoir-remember`, `memoir-onboard`, `memoir-status`, and `memoir-ui` are reusable skill shapes for agent memory systems.

## Core Execution Path

Store bootstrap starts in `StoreService.create_store`: create or reuse a dedicated directory, initialize Git if needed, harden GC config, write the backend lock, create `data/`, and make an initial commit when there are staged changes. `ProllyTreeStore` later opens only paths that look like Memoir stores and wraps ProllyTree operations with cwd locking because the Rust binding resolves the enclosing Git repo through cwd.

Manual memory writes enter through `memoir remember`. If `-p/--path` is provided, `MemoryService.remember` skips Memoir's classifier, writes the content to each supplied key, records sibling `related_keys`, appends `[update]` on repeat path writes, and supports `--replace` for caller-owned read-merge-write flows. Without `-p`, it initializes taxonomy and LLM components, classifies to one or two paths, optionally extracts timeline/location events, stores values, and returns commit metadata.

Recall has two surfaces. `memoir recall` uses `IntelligentSearchEngine`: it scans paths in a namespace, asks an LLM to choose paths in `single` mode, or performs a staged L1/L2/key pick in `tiered` mode. The Codex/Claude memory-recall skill uses the lower-level primitives instead: summarize keys, pick relevant exact keys in the parent agent, and batch `get`, avoiding a second model call inside Memoir.

Agent auto-capture is plugin-driven. Codex Stop parses the JSONL transcript, asks nested `codex exec` for `path<TAB>fact` lines using the store's cached taxonomy snippet, validates path format, and writes each fact with `memoir remember -p`. Claude Code follows the same lifecycle pattern with its own transcript parser and hook surfaces.

Branch operations go through `BranchService`. It lists ProllyTree branches, creates and checks out branches, runs native ProllyTree merges, and provides `promote_branch` for safe additive sync of `default` namespace keys from a source branch into a target branch. Per-call `routed_to` temporarily switches branches and restores the original branch, so agents can read or write another branch without leaving the store in that state.

## Architecture

The core layers are clear: Click CLI commands, service objects, ProllyTree storage, taxonomy/classifier/search components, memento managers, integrations, and plugins. The service layer is the practical center because CLI, UI handlers, SDK, MCP, and tests all lean on `MemoryService`, `StoreService`, `BranchService`, `SearchService`, `WatchService`, and `CryptoService`.

Storage uses ProllyTree through `VersionedKvStore` for key/value memory and `NamespacedKvStore` text indexes for watch vector search. Keys are namespaced by prefixing tuple namespaces into strings such as `default:preferences.coding.style`. Versioning is branch and commit based, but direct historical value lookup by commit is not implemented; history APIs can show key commit metadata and branch snapshots can be checked out.

The taxonomy system stores built-in and custom Markdown taxonomies in the store under `taxonomy:v1`. Classifiers and search engines prefer store-loaded taxonomy paths, descriptions, and examples, then fall back to hardcoded presets. This makes taxonomy part of the durable memory state rather than only package code.

The agent plugins are an architecture layer of their own. `session-start.sh` creates stores, loads custom taxonomy once, auto-matches memory branch to code branch, injects compact status/key/onboard context, and caches taxonomy prompt snippets for Stop capture. `user-prompt-submit.sh` nudges recall on substantive prompts. `stop.sh` records metrics, code-change summaries, and durable facts.

## Design Choices

The best design choice is path-first memory. Human-readable hierarchical keys are inspectable, cheap to summarize, and naturally composable with branch history. This lets the agent ask "which keys exist?" before spending context on values.

The second strong choice is read/write asymmetry. Reads can be automatic through recall skills and SessionStart hints, while manual writes are explicit through `memoir-remember` or Stop capture. The Codex skill explicitly refuses unpathed `memoir remember`, which avoids hidden package-level LLM calls and lets Codex classify into paths itself.

Branch matching is a practical coding-agent choice. A memory branch named after the code branch prevents feature-branch facts from leaking into `main`, while `sync-branch` gives the user a promotion step. The design also handles non-git folders by locking to `main` and switching onboarding from `codebase:onboard` to `project:onboard`.

The repo chooses defensive local storage over convenience defaults. There is no hidden global store connection, non-Memoir Git repos are rejected, backend selection is locked per store, and GC settings are hardened. These are the kinds of small operational choices that prevent memory systems from silently corrupting a user's project.

The weakest design choice is allowing multiple memory schemas to coexist. CLI `remember -p` writes scalar blobs, the SDK manager writes aggregated memories, mementos write structured aggregate entries, and watch writes raw file summaries/chunks. The adapters mostly account for this, but schema drift raises the cost of reliable retrieval, UI rendering, and future migrations.

## Strengths

- Branch-aware memory is implemented across CLI, services, plugins, and docs rather than only described in the README.
- The Codex and Claude Code integrations are unusually concrete: lifecycle hooks, recall skills, onboarding snapshots, manual remember/status/UI skills, transcript parsing, and prompt harness tests are all present.
- Path-first recall is a strong token-efficiency pattern for coding agents. `summarize` plus batched `get` gives the model agency over retrieval without invoking another LLM inside the memory service.
- Store safety gets real engineering attention: strict store detection, backend locks, cwd locking, File backend default, Git GC hardening, and guardrails against initializing unrelated repositories.
- The taxonomy loader makes custom taxonomies durable and store-scoped, which is useful for project-specific agent memory.
- `promote_branch` is safer than a raw merge for agent memories because it only adds or updates `default` namespace keys and never deletes target-only keys.
- Watch/vector search is isolated to ingested files, so ad-hoc remembered facts and document chunks do not get conflated accidentally.

## Weaknesses

- Some Git-like claims are ahead of implementation. Branching, commits, merge, blame metadata, and proofs exist, but direct historical content retrieval by commit returns no content, and `time_travel` mostly delegates to branch checkout.
- Memory schema consistency is not solved. The service path, SDK manager path, mementos, watch ingestion, and taxonomy storage use different value shapes, so every reader needs defensive parsing.
- MCP and SDK adapters show drift from the service API. For example, `memoir_checkout` and `BranchManager.checkout` pass an unsupported `create` keyword, MCP checkout returns nonexistent `branch`/`commit`/`created` fields, and MCP recall attempts to JSON-serialize dataclass objects directly.
- The LLM classifier accepts newly invented top-level categories and can truncate over-deep paths. That is flexible, but it weakens taxonomy consistency unless callers enforce stricter policy.
- There is no strong built-in secret/redaction story. Stop capture has conservative prompt rules and manual remember warns against secrets in skill text, but storage remains plaintext and best-effort model extraction can still preserve sensitive facts.
- Search scalability is mixed. Single-mode LLM recall sends the discovered path inventory and samples to the model, while `ProllyTreeStore.search` iterates an in-memory key registry. The caller-driven skill is better for common stores, but the package search API still carries linear inventory costs.
- Test coverage is broad but uneven. There are useful tests for branch merges, backend safety, tiered search, path writes, Codex hooks, and prompt harnesses, but many service tests are smoke tests that assert "does not crash" and skip real LLM-dependent semantics.

## Ideas To Steal

- Use human-readable semantic paths as the memory API, and make exact-key `get` the fast path for agents.
- Inject a compact key inventory at session start, then let the agent fetch only the values it needs.
- Keep read and write surfaces asymmetric: automatic recall is cheap and safe; durable writes need explicit capture paths, conservative extraction, or an end-of-turn hook.
- Match memory branches to code branches and provide a safe promotion command that copies only selected namespaces.
- Cache taxonomy prompt snippets from the store so auto-capture classifies against the user's current taxonomy without re-reading taxonomy on every turn.
- Provide path-provided writes that bypass package-level LLM calls, especially inside an agent plugin where the host model can choose the taxonomy path.
- Harden local stores as project data: backend lock, dedicated directory detection, no hidden global default, and Git GC protection.
- Treat onboarding snapshots as a separate namespace from user memories so codebase maps do not pollute preference recall.

## Do Not Copy

- Do not advertise full time travel unless historical value retrieval is implemented and tested end to end.
- Do not expose MCP or SDK adapters without contract tests that instantiate the adapter and call every advertised tool/method.
- Do not mix multiple value schemas unless the schema boundary is explicit and migration/version metadata is part of each stored value.
- Do not rely on prompt text alone to prevent secret capture. Add deterministic redaction, allow/deny policies, and user-visible deletion workflows.
- Do not treat a branch warning as concurrency control. Shared stores still need a stronger locking or writer-serialization story for concurrent agent sessions.
- Do not make LLM-invented taxonomy paths the default in regulated or high-consistency domains without an approval or registry step.
- Do not let vector-indexed document chunks and user preference memories share a retrieval surface without clear namespace and provenance controls.

## Fit For Agentic Coding Lab

Fit: high. Memoir is one of the most relevant memory repos for coding-agent support because it ties memory to branches, keys, lifecycle hooks, and agent skills. It is especially useful as a pattern library for a lab-local memory substrate: semantic paths, branch-aware isolation, summarize/get recall, session-start context, end-of-turn capture, and codebase onboarding are all directly reusable.

The best lab artifact would not be a direct fork. It should be a narrower implementation that preserves the contracts while tightening schemas, redaction, verification, and adapter tests. Memoir is a strong research candidate because it exposes both the right product shape and the practical failure modes that appear when memory becomes persistent agent infrastructure.

## Reviewed Paths

- `/tmp/myagents-research/zhangfengcdt-memoir/README.md`, `pyproject.toml`, and `src/memoir/__init__.py` for package scope, version, dependencies, console entry points, license, and advertised memory model.
- `/tmp/myagents-research/zhangfengcdt-memoir/docs/architecture.md`, `docs/basic_usage.md`, `docs/cli.md`, `docs/theory/search.md`, and `docs/theory/memento.md` for documented architecture, retrieval modes, branch routing, mementos, and usage contracts.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/store/prolly_adapter.py`, `store/backend.py`, `store/git_safety.py`, and `store/cwd_locked.py` for storage initialization, backend resolution, key/value APIs, aggregation, Git hardening, and cwd locking.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/services/memory_service.py`, `store_service.py`, `branch_service.py`, `search_service.py`, `watch_service.py`, `vector_service.py`, `crypto_service.py`, `models.py`, and `base.py` for service contracts and execution paths.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/classifier/intelligent.py`, `search/intelligent.py`, `taxonomy/loader.py`, `taxonomy/markdown_source.py`, `taxonomy/registry.py`, and built-in taxonomy data for classification, dynamic taxonomy loading, and recall behavior.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/core/memory.py` and `src/memoir/memento/{profile,timeline,location}.py` for SDK-style aggregation, memento storage, snapshots, and historical API limits.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/cli/main.py`, `cli/commands/memory.py`, `cli/commands/branch.py`, `cli/commands/search.py`, `cli/commands/taxonomy.py`, and `cli/commands/crypto.py` for user and agent command surfaces.
- `/tmp/myagents-research/zhangfengcdt-memoir/plugins/codex/**`, especially `hooks/session-start.sh`, `hooks/user-prompt-submit.sh`, `hooks/stop.sh`, `hooks/common.sh`, `skills/memory-recall/SKILL.md`, `skills/memoir-remember/SKILL.md`, and prompt harness cases for Codex integration.
- `/tmp/myagents-research/zhangfengcdt-memoir/plugins/claude-code/**` and `docs/claude_code.md` for Claude Code lifecycle parity, slash commands, hook behavior, and onboarding contracts.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/integration/langgraph/memory_store.py`, `src/memoir/sdk/client.py`, and `src/memoir/mcp/server.py` for LangGraph, SDK, and MCP adapter behavior.
- `/tmp/myagents-research/zhangfengcdt-memoir/tests/**` selected coverage for memory service path writes, branch merge/promotion, Git safety, backend resolution, tiered search, watch/vector behavior, crypto service, UI schemas, Codex plugin scripts, and prompt harnesses.

## Excluded Paths

- `/tmp/myagents-research/zhangfengcdt-memoir/.git/**` was excluded as VCS metadata.
- `/tmp/myagents-research/zhangfengcdt-memoir/src/memoir/ui/webapp/**` was excluded from deep review because it is a React UI surface; only backend schemas/handlers were skimmed for memory data shape.
- `/tmp/myagents-research/zhangfengcdt-memoir/docs/_static/**`, `static/**`, screenshots, GIFs, and logos were excluded as documentation/media assets.
- `/tmp/myagents-research/zhangfengcdt-memoir/uv.lock`, webapp lockfiles, package-lock files, build outputs, caches, and generated distribution artifacts were excluded as dependency/build metadata.
- `/tmp/myagents-research/zhangfengcdt-memoir/benchmarks/**` and benchmark data JSON files were excluded from deep review because the task focus was architecture and execution paths, not benchmark validity.
- `/tmp/myagents-research/zhangfengcdt-memoir/scripts/pypi-smoke/**`, `scripts/cc-smoke/**`, release scripts, and Docker smoke wrappers were excluded except for awareness that packaging smoke tests exist.
- `/tmp/myagents-research/zhangfengcdt-memoir/docs/examples/**` was skimmed for branch/memory scenarios but not treated as implementation evidence.
