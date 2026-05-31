# varunreddy/SkillMesh

- URL: https://github.com/varunreddy/SkillMesh
- Category: tool-use
- Stars snapshot: 5 (GitHub REST API, captured 2026-05-31; existing index row also records 5 from 2026-05-29)
- Reviewed commit: 113a880a40a6e1eb5d65f36e54df2f2414a58ab3
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Directly relevant runtime skill-routing prototype. It has a real registry loader, BM25 retrieval, optional dense/Chroma backends, Codex/Claude context emitters, and MCP tools that expose only top-k cards. Its best idea is the query-time "retrieve small context, then act" boundary. Do not copy its scale claims uncritically: current bundled catalog is 135 cards, benchmark docs are 10-task/proxy-heavy, execution gating is mostly prompt-level, and 10K-skill behavior is not demonstrated.

## Why It Matters

SkillMesh targets the exact failure mode behind runtime-skill-routing: agents should not see every skill or tool description every turn. The repo treats skills as retrievable cards with compact metadata plus full instruction files, then emits only top-k relevant cards into the agent context. This is closer to the user's "10,000 skills but no context blow-up" target than marketplace/install repos, because retrieval happens at task time and the agent is expected to continue from the selected cards.

For Agentic Coding Lab, the repo is useful as a small executable sketch of a `search_skills`/`read_skill_context` layer: structured registry, route command, provider-specific context renderers, MCP server, and a Codex skill wrapper. It is less useful as evidence that the architecture scales: the implemented and tested catalog size is in the hundreds, not tens of thousands.

## What It Is

SkillMesh is a Python package named `skillmesh` with a registry-driven tool/skill card model. Each card has fields such as `id`, `title`, `domain`, `description`, `tags`, `tool_hints`, `aliases`, `dependencies`, `input_contract`, `invocation`, `risk_level`, `maturity`, `metadata`, and loaded `instruction_text`.

The CLI supports:

- `skillmesh retrieve`: return top-k structured hits as JSON.
- `skillmesh emit`: render top-k hits as Codex Markdown or Claude XML context.
- `skillmesh index`: build a Chroma collection from a registry.
- `skillmesh roles`: list/install role bundles into a smaller target registry.

The MCP server exposes:

- `route_with_skillmesh(query, top_k, ...)`: provider-formatted routed context.
- `retrieve_skillmesh_cards(query, top_k, ...)`: structured hit payload.
- role list/install helpers.

The repo also ships a Codex-installable skill under `skills/skillmesh` whose `SKILL.md` tells the agent to run `scripts/route.sh`/`route.py` and continue with only the returned top-k cards.

## Research Themes

- Token efficiency: Strong conceptually. `emit` truncates each retrieved instruction to `--instruction-chars` with default 700, caps `top_k` at 20, and keeps non-matching cards out of prompt. Bench docs report roughly 73-93% token reduction versus all-card baselines on small 10-task runs.
- Context control: Strong but incomplete. The active context is a selected set of cards, not a global skill list. There is no multi-turn context lifecycle, eviction policy, activation telemetry, or automatic re-route loop when task state changes.
- Sub-agent / multi-agent: Limited. Role cards orchestrate dependency sets such as data analyst or DevOps engineer, but there is no sub-agent scheduler or isolated worker context.
- Domain-specific workflow: Strong as examples. The catalog has domain cards for visualization, ML, stats, cloud, security, APIs, data, BI, systems, and role orchestrators. Instruction files include "when to use", execution behavior, decision trees, anti-patterns, output contracts, and composability hints.
- Error prevention: Moderate. Registry schema validation, duplicate ID checks, path traversal protection for instruction files, risk/maturity metadata, quality checks, constraints, and tests reduce catalog errors. Runtime prevention is weaker because retrieved instructions are advisory.
- Self-learning / memory: Weak. There is no feedback loop from successful or failed activations back into retrieval weights, skill metadata, pruning, or fine-tuning.
- Popular skills: Not a popularity system. It offers role bundles and domain registries, but no usage analytics, community ranking, or learned popularity priors.

## Core Execution Path

1. A registry path is resolved from an explicit flag, `SKILLMESH_REGISTRY`, repo-local `examples/registry/tools.json`, or bundled `src/skill_registry_rag/data/tools.compiled.json`.
2. `load_registry()` reads JSON/YAML, optionally validates `schema.json`, normalizes entries, rejects duplicate IDs, checks instruction paths stay inside the registry root, and loads either `instruction_text` or the referenced Markdown file.
3. `SkillRetriever(cards, use_dense, backend)` selects an in-memory backend or Chroma backend. CLI defaults to `backend="chroma"`, while wrappers often use `auto`.
4. The backend composes a searchable document from card metadata plus the first 2000 characters of instruction text.
5. Retrieval scores every card with BM25. Optional dense retrieval is available through sentence-transformers for in-memory mode, or Chroma for Chroma mode.
6. The top-k hits are returned as `RetrievalHit` objects with score, sparse score, and optional dense score. `top_k` is clamped to at most 20.
7. `retrieve` emits JSON including invocation schemas. `emit` sends the hits through `render_codex_context()` or `render_claude_context()`, which include IDs, metadata, score, and trimmed instruction text.
8. In MCP mode, `route_with_skillmesh()` and `retrieve_skillmesh_cards()` expose the same path as callable tools and cache the retriever by registry path, mtime, backend, and dense flag.

## Architecture

The core architecture is:

- `models.py`: dataclasses for `ToolCard` and `RetrievalHit`.
- `registry.py`: JSON/YAML loader, schema validation, field normalization, OpenAI-style function schema normalization, instruction file loading.
- `retriever.py`: facade that chooses a retrieval backend and delegates indexing/query.
- `backends/memory.py`: in-process BM25 with optional sentence-transformers dense vectors and RRF fusion when dense is present.
- `backends/chroma.py`: ChromaDB-backed dense candidate retrieval plus BM25 sparse scoring, fused by weighted sum with defaults sparse 0.8 and dense 0.2.
- `adapters/codex.py` and `adapters/claude.py`: provider-specific top-k context renderers.
- `cli.py`: command surface for retrieve, emit, Chroma index, and role registry operations.
- `mcp_server.py`: FastMCP tools for routed context, structured retrieval, and role installs.
- `roles.py`: role bundle listing/installing, dependency extraction from metadata or role Markdown, target registry writes, and instruction file copying.
- `skills/skillmesh`: a host skill wrapper that lets Codex call the router.

The repo distinguishes catalog/registry from runtime exposure. It can use the full catalog for retrieval while exposing only the selected cards to the agent.

## Design Choices

- Structured skill cards instead of free-form README lists. Routing uses IDs, titles, domains, tags, examples, aliases, dependencies, contracts, constraints, maturity, risk level, metadata, and a slice of instructions.
- Retrieval-gated context rather than always-active skills. The agent sees a selected context block rather than every skill.
- Provider adapters are separated from retrieval. The same hit list can be rendered for Codex Markdown, Claude XML, or raw JSON.
- OpenAI-style `invocation` schemas are generated or normalized for each card, which points toward actual tool calling even though execution is not implemented.
- Optional dense retrieval is dependency-gated. The base package only requires `numpy`, `PyYAML`, `rank-bm25`, and `jsonschema`; Chroma and sentence-transformers live in extras.
- Role bundles are a second-stage narrowing mechanism. A role plus dependency cards can be installed into a smaller registry, then routed again inside that subset.
- The MCP server caches retrievers across calls. The CLI rebuilds each invocation, so MCP is the more plausible long-running runtime integration.

## Strengths

- The repo implements a real runtime top-k path rather than only a marketplace or installer.
- BM25-only mode is simple, local, deterministic, and easy to debug.
- The card schema has useful routing hooks beyond long natural-language descriptions: aliases, examples, tags, dependencies, constraints, risk level, maturity, and input/output contracts.
- Context emission is bounded by both top-k and per-card instruction character limits.
- MCP tools make the router callable by an agent at runtime instead of requiring humans to run a separate command.
- Role bundles are a useful pattern for project-scoped enabled skill sets: install a small dependency closure, then retrieve within it.
- Tests cover registry loading, known retrieval examples, adapters, CLI aliases, MCP payloads, role install behavior, and backend protocol behavior.
- Path traversal detection prevents a registry entry from reading arbitrary files outside its registry root.

## Weaknesses

- Scale is not proven. The current `examples/registry/tools.json` contains 135 cards and 11 role cards. Docs discuss 154 cards and plans for thousands, but no 10K benchmark or stress test is present.
- The README says BM25 plus dense index and RRF fusion, but the default practical behavior is more nuanced: dense is off unless requested, Chroma mode with dense off is BM25-only, and Chroma dense fusion is weighted sparse+dense scoring rather than RRF.
- `skillmesh index` is not a full offline index lifecycle. The normal retrieve path loads cards and calls backend `index(cards)`; ChromaBackend deletes/recreates the collection during indexing. MCP caching reduces repeated work, but CLI routing is still rebuild-heavy.
- Execution gating is mostly context gating. It limits which instructions/schemas the model sees, but it does not enforce tool permissions, sandbox policy, risk filters, or allowed dependency constraints at execution time.
- Risk, maturity, constraints, and quality checks are emitted as metadata but are not used as hard filters in retrieval or execution.
- Benchmarks are small and partly self-referential. The documented human eval sheets are seeded from `quality_proxy`, and the benchmark has only 10 tasks.
- One registry parity test is skipped as obsolete. That weakens confidence that every instruction file and registry entry stay synchronized.
- Generated artifacts such as `dist/` and `src/skillmesh.egg-info/` are committed, adding noise to review and maintenance.
- Local verification in this environment could not run upstream tests because `pytest`, `numpy`, and package dependencies were not installed.

## Ideas To Steal

- Use a compact machine-readable skill index as the retrieval source, not full `SKILL.md` text in the system prompt.
- Compose retrieval documents from short metadata fields plus a bounded instruction prefix. For SKILL.md routing, index `name`, `description`, `when_to_use`, negative triggers, tags, file globs, allowed tools, risks, examples, and dependency hints.
- Expose two runtime operations: `retrieve_skill_cards(query, top_k)` for structured hits and `emit_skill_context(query, provider, top_k)` for provider-ready context.
- Cap both selected count and per-skill text size. A practical first policy is top-k 3-7, hard max 20, and a small per-skill instruction budget before loading deeper resources.
- Keep provider rendering separate from retrieval. The same shortlist should feed Codex, Claude, MCP, or a local CLI.
- Treat role/project bundles as a deterministic pre-filter before semantic routing. A project can install or enable only relevant skill families, then retrieval selects within that smaller pool.
- Store `invocation`/tool schema metadata beside each skill, even if execution is not immediate. It provides a bridge from "selected instruction" to "callable capability".
- Add benchmark artifacts that compare all-skills prompt versus top-k prompt on token cost, latency, top-1/top-5 match, and human quality.

## Do Not Copy

- Do not claim 10K-scale performance from this implementation. It needs actual large-catalog retrieval benchmarks, cold/warm latency measurements, memory use, and quality curves.
- Do not rely on description-only routing. SkillMesh's richer fields are good, but its examples still depend heavily on natural-language metadata and instruction prefixes.
- Do not make routing purely advisory. For high-risk skills, the router should enforce permission checks, risk filters, allowed tools, and execution constraints before a skill can run.
- Do not rebuild the full vector index on each CLI request in a production runtime. Use incremental indexing, content hashes, persistent collections, and warm retriever caches.
- Do not let documentation drift from implementation. README/benchmark cardinalities and RRF wording should match actual backend behavior.
- Do not treat seeded proxy ratings as publication-grade human eval.
- Do not install role dependency closures without provenance, lockfiles, and integrity metadata if skills can come from external sources.

## Fit For Agentic Coding Lab

Fit is high as a runtime-router reference and medium as a production design. The repo demonstrates the shape we likely want: a small always-available router, a large external skill registry, task-time top-k retrieval, provider-specific context rendering, and MCP/CLI integration.

The main missing pieces for Agentic Coding Lab are the parts needed for very large skill libraries: hierarchical pre-filters, embeddings or hybrid search over 10K+ skills, stable persistent indexes, activation telemetry, duplicate/collision handling, trust/provenance metadata, hard permission gates, and automatic re-routing when the task shifts.

Recommended adaptation: implement a `skills.index.json` or SQLite registry with deterministic filters first (project, language, file globs, enabled packs, risk level, host compatibility), then BM25/vector retrieval, then a reranker over a short candidate set, then lazy loading of `SKILL.md` and referenced resources only for selected skills.

## Reviewed Paths

- `README.md`: project goals, routing flow, CLI/MCP/Codex setup, registry counts, benchmark claims.
- `pyproject.toml`: package metadata, core dependencies, optional `dense`, `mcp`, `chroma`, and `dev` extras.
- `src/skill_registry_rag/models.py`: card and hit data model.
- `src/skill_registry_rag/registry.py`: registry parsing, schema validation, path safety, invocation normalization, instruction loading.
- `src/skill_registry_rag/retriever.py`: backend selection and top-level retrieval API.
- `src/skill_registry_rag/backends/memory.py`: BM25, optional sentence-transformers dense scoring, RRF fusion, top-k clamp.
- `src/skill_registry_rag/backends/chroma.py`: Chroma persistence, metadata storage, BM25 plus dense weighted scoring, batch upsert behavior.
- `src/skill_registry_rag/adapters/codex.py` and `src/skill_registry_rag/adapters/claude.py`: bounded provider context rendering.
- `src/skill_registry_rag/cli.py`: user-facing routing, emitting, indexing, and role commands.
- `src/skill_registry_rag/mcp_server.py`: MCP runtime integration and retriever caching.
- `src/skill_registry_rag/roles.py`: role bundle dependency resolution and install flow.
- `src/skill_registry_rag/_resolve.py` and `src/skill_registry_rag/data/__init__.py`: registry resolution and bundled registry fallback.
- `examples/registry/schema.json`, `examples/registry/tools.json`, `examples/registry/tools.yaml`, `examples/registry/*.registry.yaml`, `examples/registry/instructions/*.md`, `examples/registry/roles/*.md`: card schema, full catalog, domain subsets, and instruction corpus.
- `skills/skillmesh/SKILL.md`, `skills/skillmesh/scripts/route.py`, `skills/skillmesh/scripts/route.sh`, `skills/skillmesh/scripts/roles.py`, `skills/skillmesh/scripts/roles.sh`: Codex skill wrapper and helper scripts.
- `docs/integrations/codex.md`, `docs/integrations/claude-code.md`, `docs/integrations/claude-desktop.md`: host integration instructions.
- `docs/plans/2026-02-28-v2-design.md`: planned architecture and scale goals; compared against current code.
- `docs/benchmarks/*.md`, `docs/benchmarks/*.csv`, `scripts/benchmark_human_eval.py`: token/latency/quality proxy benchmark artifacts and rating workflow.
- `tests/test_registry.py`, `tests/test_retriever.py`, `tests/test_backends.py`, `tests/test_adapters.py`, `tests/test_cli.py`, `tests/test_mcp_server.py`, `tests/test_roles.py`, `tests/test_benchmark_human_eval.py`: implementation coverage and known gaps.
- `.github/workflows/ci.yml`: declared lint/test workflow across Python 3.10-3.12 with dev/mcp/dense/chroma extras.

## Excluded Paths

- `dist/*.tar.gz` and `dist/*.whl`: generated package artifacts, not source design.
- `src/skillmesh.egg-info/*`: generated packaging metadata duplicated from source/README.
- `.github/workflows/publish.yml`: release automation, not relevant to runtime skill routing.
- `LICENSE` and most of `CONTRIBUTING.md`: licensing/contribution process only; skimmed but not central to routing behavior.
- Full line-by-line review of every individual instruction card under `examples/registry/instructions/`: sampled enough to confirm card structure and metadata usage; individual domain content quality is secondary to runtime routing architecture.
