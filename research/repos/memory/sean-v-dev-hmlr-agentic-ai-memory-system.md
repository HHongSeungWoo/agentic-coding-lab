# Sean-V-Dev/HMLR-Agentic-AI-Memory-System

- URL: https://github.com/Sean-V-Dev/HMLR-Agentic-AI-Memory-System
- Category: memory
- Stars snapshot: 381 (GitHub web page, captured 2026-05-20)
- Reviewed commit: 7a0a6393d2bbc759b7f0ab8fb297a34992b0991b
- Reviewed at: 2026-05-20 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope design source for agent memory, especially active topical "bridge blocks", background profile extraction, fact-first indexing, manual consolidation into long-term chunks, and dossier-style causal fact aggregation. Do not adopt directly as infrastructure without hardening: memory writes are live-LLM dependent, long-term consolidation is manual, secrets are intentionally extracted and stored, scope/privacy controls are weak, several integration/docs paths drift from code, and retrieval often fails open.

## Why It Matters

HMLR is one of the more concrete public repos for "living memory" in a conversational agent. Instead of treating memory as a single vector store, it separates hot topical context, durable facts, strict user constraints, long-term chunk retrieval, and dossier-level fact chains. The hard tests focus on exactly the failures a coding agent memory system must survive: aliases, renamed entities, superseded policies, buried constraints, cross-topic invariants, and stale-but-important facts.

For Agentic Coding Lab, the useful idea is not the exact package. The useful idea is the layered lifecycle: keep an active work buffer while a task is happening, extract hard facts as evidence, consolidate at boundaries, then retrieve through both semantic chunks and structured fact dossiers. That maps naturally to coding sessions, where a future agent must remember repo conventions, failing commands, user decisions, architectural constraints, and issue history without dumping every prior transcript into context.

## What It Is

HMLR is a Python package named `hmlr`, published as version `0.1.2` in packaging metadata, with a public `HMLRClient` API, an interactive `main.py`, LangGraph node wrappers, docs, examples, and pytest-style integration tests. The implementation is centered on SQLite plus local sentence-transformer embeddings and external LLM calls.

The package stores current conversations in bridge blocks, extracts facts into `fact_store`, stores stable user constraints in a JSON profile, and later converts bridge blocks into long-term `gardened_memory` chunks and dossiers through `hmlr/run_gardener.py`. The default model path is optimized around `gpt-4.1-mini`; docs repeatedly warn that other models are not validated.

The repo is alpha-quality research infrastructure rather than a polished production dependency. It contains useful executable architecture, but also version drift, generated debug logs, live API assumptions, and several stale or brittle integration paths.

## Research Themes

- Token efficiency: Moderate. The design avoids always loading all history by routing to a bridge block, searching gardened chunks, and using dossiers. Actual prompt assembly still includes full current bridge-block turns, all facts from retrieved dossiers, and only warns when over budget rather than enforcing truncation.
- Context control: Strong conceptually. HMLR separates system prompt, immutable user profile, current topic, exact facts, dossiers, relevant memories, and current message. It lacks robust tenant/project/agent scope, privacy labels, authority levels, and deletion controls.
- Sub-agent / multi-agent: Limited. The Scribe is a background worker and LangGraph integration exists, but there is no multi-agent shared-memory protocol, lock model, conflict resolution, or ownership metadata.
- Domain-specific workflow: Conditional. Tests are governance and personal-memory scenarios, not coding workflows. The same patterns can represent coding constraints such as "never use package X", renamed services, active incident facts, and repo-specific command rules.
- Error prevention: Mixed. The adversarial tests are valuable, and exceptions are logged. Several retrieval and routing paths fail open by defaulting to last active topic, returning all candidates, or creating new dossiers after malformed JSON.
- Self-learning / memory: Strong. The system writes profile constraints, fact rows, bridge-block metadata, gardened chunks, dossier facts, dossier summaries, and provenance. Learning is LLM-driven and not strongly validated.
- Popular skills: Bridge-block topic routing, Scribe profile extraction, FactScrubber hard-fact extraction, ManualGardener consolidation, DossierGovernor multi-vector voting, one-hop causal hydration, and two-key retrieval filtering are the reusable patterns.

## Core Execution Path

The public path starts with `HMLRClient(api_key=..., db_path=...)`. The client calls `ComponentFactory.create_all_components()`, which wires SQLite `Storage`, a stateless `SlidingWindow`, `ConversationManager`, `EmbeddingStorage`, `LatticeCrawler`, `TheGovernor`, `ContextHydrator`, `UserProfileManager`, `Scribe`, `ChunkEngine`, `FactScrubber`, and dossier components.

`HMLRClient.chat()` delegates to `ConversationEngine.process_user_message()`. The engine sets the session, starts `Scribe.run_scribe_agent(user_query)` as a background task, and enters `_handle_chat()`.

`_handle_chat()` creates a `turn_YYYYMMDD_HHMMSS` id, chunks the user query into sentence and paragraph chunks, starts `FactScrubber.extract_and_save()` in parallel, and calls `TheGovernor.govern(query, day_id)`. The governor concurrently runs bridge-block routing, vector retrieval plus LLM filtering, exact fact lookup, and dossier retrieval if available.

Bridge-block routing loads active or paused block metadata, including recent facts, and asks an LLM whether to continue, resume, or create a topic. Retrieval searches `gardened_memory` chunk embeddings only, then asks an LLM to filter candidates with both embedding similarity and original content. Fact lookup searches exact query words in `fact_store`. Dossier retrieval searches fact-level dossier embeddings and returns full dossiers ranked by hit count and max similarity.

After parallel retrieval, `_causal_hydration()` adds one-hop provenance context: facts pull in source turns, dossier facts pull in source turns, and retrieved turns pull in their facts. The engine then executes the routing decision by pausing/resuming/creating bridge blocks in `daily_ledger`.

Once routing has a block id, the engine awaits the fact-extraction task and links extracted facts to the block. Linkage is based on timestamp-like ids, so it depends on turn and chunk timestamps aligning closely. `ContextHydrator.hydrate_bridge_block()` loads the user profile, current block turns, facts, dossiers, retrieved memories, and metadata-update instructions into a final prompt. The LLM response is parsed for optional bridge-block metadata JSON, then the turn is persisted to `ledger_turns`, `metadata_staging`, active sliding-window state, and embeddings for the user query.

Long-term memory is a separate boundary step. `hmlr/run_gardener.py` constructs `ManualGardener`, lists active blocks, and processes a selected block. The gardener loads a bridge block, reads facts from `fact_store`, classifies facts into global tags or section rules, saves turn chunks into `gardened_memory`, creates embeddings for those chunks, groups all facts semantically, routes fact packets through `DossierGovernor`, and archives the original bridge block.

`DossierGovernor` uses multi-vector voting: every incoming fact searches existing dossier facts, dossiers with repeated hits rise, and an LLM decides append vs create. Append/create writes `dossier_facts`, fact embeddings, summaries, search summaries, and provenance. The prompt rules explicitly prioritize identity and transitive relationships such as renames and aliases.

LangGraph integration offers two nodes. `hmlr_chat_node` runs the full conversation engine and waits for background Scribe work. `hmlr_memory_node` is intended to retrieve context before a caller-owned LLM node, but the reviewed code formats `MemoryCandidate` objects as dicts, so it can fail when memories are returned.

## Architecture

The storage core is SQLite. Important tables include `days`, `day_sessions`, `metadata_staging`, `daily_ledger`, `ledger_turns`, `fact_store`, `embeddings`, `gardened_memory`, `dossiers`, `dossier_facts`, `dossier_provenance`, `block_metadata`, and dossier embedding tables. The schema uses WAL and a simple retry helper for SQLite busy/lock errors.

The hot memory layer is bridge blocks. A block has metadata such as topic label, summary, keywords, open loops, decisions, status, and normalized turns in `ledger_turns`. Active and paused blocks are the current routing pool.

The cold memory layer is gardened chunks plus dossiers. Gardened memory stores immutable sentence and paragraph chunks from processed bridge blocks. Dossiers store aggregations of facts, summaries, search summaries, and provenance.

The profile layer is a JSON file, defaulting to `hmlr/config/user_profile_lite.json` unless `USER_PROFILE_PATH` is set. `Scribe` writes long-term constraints, identity facts, and preferences. `ContextHydrator` always loads the profile and labels constraints as immutable.

The retrieval layer has four channels: bridge-block metadata routing, semantic search over gardened chunks, exact fact lookup, and dossier fact embedding search. An LLM governor filters and routes the results before the final prompt.

The model layer uses a single `ExternalAPIClient` configured by `API_PROVIDER`. Code supports OpenAI, Gemini, xAI, and Anthropic branches, but the main model compatibility docs say only `gpt-4.1-mini` has been validated. Embeddings use sentence-transformers through `EmbeddingStorage`; current code defaults to `BAAI/bge-small-en-v1.5` and 384 dimensions, while some docs still describe larger 1024-dimensional defaults.

The integration layer exposes direct Python API, CLI-like interactive `main.py`, manual gardener runner, LangGraph nodes, and examples. There is no MCP server or cross-process memory service.

## Design Choices

HMLR treats active conversation memory as a topic-bounded write buffer. This avoids immediate fragmentation into tiny facts and gives the LLM verbatim local context for the current topic.

The system distinguishes user constraints from ordinary memory. Stable constraints go into a profile lane that is always injected, which is the right shape for coding-agent rules that must survive topic switches.

Hard facts are extracted as rows before long-term consolidation. This gives the gardener and router structured evidence instead of relying only on embeddings.

Long-term memory is intentionally boundary-driven. The gardener is the consolidation phase: chunk, tag, embed, group, route to dossiers, then archive the active block. This is a strong pattern for "end of task" coding memory.

Dossiers are used to preserve causal chains. The write-side prompts explicitly handle aliases, renames, and transitive identity links, which is more useful for long-running coding systems than plain semantic similarity.

The repo chooses LLM judgment at multiple control points: fact extraction, topic routing, candidate filtering, metadata update, fact classification, fact grouping, dossier routing, and dossier summary generation. This maximizes semantic flexibility but makes reproducibility, validation, and safety harder.

The implementation favors graceful degradation. Missing API clients disable governor/scribe/fact scrubber; retrieval parse failures return last-active topic or all candidates; vector init failure can fall back. That keeps demos alive, but for safety-critical memory it can include irrelevant or stale context without a strong signal.

## Strengths

The memory lanes are explicit and inspectable. Bridge blocks, facts, gardened chunks, dossiers, and profile constraints are different stores with different update timing.

The tests target realistic memory failures. Hydra-style alias/policy tests and vegetarian constraint tests are directly relevant to long-running coding agents that must handle renamed systems, superseded decisions, and immutable user rules.

The dossier design is valuable. Multi-vector voting over facts plus LLM append/create routing is a practical way to grow durable topic files without relying on a single vague query embedding.

One-hop causal hydration is a useful retrieval safeguard. Pulling source turns for facts and facts for retrieved turns gives the final model evidence, not just a matched sentence.

The profile path is simple and powerful. A compact JSON profile injected before normal memory is a useful way to enforce durable constraints without retrieving them by chance.

The system is local-first for storage. SQLite and local embeddings are easier to audit and operate than a hosted vector database for private coding work.

The README and tests document benchmark intent clearly enough to reproduce the important flows when API keys and models are available.

## Weaknesses

Long-term consolidation is manual. Unless `run_gardener.py` is run, active bridge-block content does not become searchable gardened memory or dossiers. The README notes future automation, but the reviewed path still depends on explicit gardening.

The verification story depends on live LLM behavior. Main tests need real API keys and model outputs, making them expensive, slow, and nondeterministic. There are few small deterministic tests around routing, storage migrations, prompt parsing, or malformed LLM JSON.

Privacy controls are weak. `FactScrubber` explicitly extracts secrets, credentials, API keys, and passwords; storage is plaintext SQLite/JSON; there is no redaction gate, encryption, retention policy, consent model, per-memory delete flow, or project/user/agent scoping. Dossier `permissions` default to full access and are not enforced in the reviewed read path.

The default profile file is package data and currently contains a vegetarian constraint from tests or examples. A library should not ship mutable user state in the package tree as its default durable memory location.

Several paths show integration drift. Package metadata says `0.1.2` while `hmlr/__init__.py` says `0.1.0`; docs mention LangChain modules and examples not present in the checkout; quick-reference docs show embedding defaults that differ from code; `DossierRetriever.format_for_context()` references a `score` key not returned by retrieval; `hmlr_memory_node` treats `MemoryCandidate` objects as dicts.

Token budgeting is incomplete. `ContextHydrator` estimates tokens and logs over-budget warnings, but it does not enforce a hard budget for bridge-block turns, facts, dossiers, or retrieved memories.

Retrieval can fail open. Returning all candidates after filter parse failure and defaulting to last active block after routing parse failure can create confident answers from irrelevant memory.

Fact-to-block linkage is brittle. Facts are linked after routing by matching chunk ids with a timestamp derived from `turn_id`; if chunk timestamp generation crosses a second boundary or ids change, facts can remain unlinked.

The manual gardener saves section rules and global tags, but the context use of these tags is shallow. Tags can appear inside retrieved chunk dicts, yet there is no clear policy engine that enforces tag authority or section-rule scope during generation.

The repo includes checked-in debug prompt logs. They are useful for inspection but indicate prior debug outputs can linger in source control.

## Ideas To Steal

Use bridge blocks as active coding-task memory. Keep the current investigation, decisions, commands, files, and open loops together until the task ends, then consolidate.

Run a gardener at task boundaries. On test pass, PR review, or user stop, extract durable facts, verified commands, decisions, failures, and conventions into long-term memory instead of learning every turn equally.

Create dossiers for stable coding entities. Examples: a repository, service, package, issue, migration, flaky test, product area, or recurring error. Use fact packets and multi-vector voting to decide whether new facts append to an existing dossier.

Preserve alias and supersession chains. Coding agents need to remember that an old module was renamed, a command replaced another command, an ADR superseded a prior decision, or a feature flag changed meaning.

Separate strict constraints from episodic memory. User or repo rules such as "never run destructive migrations", "use pnpm", or "do not edit generated files" should live in a high-priority profile/policy lane, not rely on vector recall.

Use one-hop causal hydration. If retrieval finds a fact, load its source evidence. If retrieval finds a source turn, load the facts extracted from it. This improves answerability and auditability.

Keep memory sections explicit in prompts. HMLR's labeled sections make it clear what is profile, current topic, known fact, dossier, past memory, and current input. Coding agents should use similar boundaries and authority labels.

Build adversarial memory evals. Copy the style of Hydra and vegetarian tests into coding scenarios: renamed packages, conflicting build commands, stale README instructions, superseded user decisions, and distractor logs.

## Do Not Copy

Do not store secrets as normal memory facts. A coding-agent memory system should redact or reject credentials before embedding, fact extraction, or dossier creation.

Do not rely on a manual long-term consolidation step in production. Boundary learning should run automatically and report failures clearly.

Do not let LLM parse failures silently widen retrieval. Memory systems should prefer explicit degraded mode over injecting all candidates or continuing the wrong topic.

Do not ship mutable user profile state inside package source. Store profiles under explicit user/project roots with permissions, scope, and reset/delete commands.

Do not use live LLM integration tests as the only verification. Add deterministic unit tests with fixed LLM outputs for every parser, storage write, routing decision, and retrieval edge case.

Do not let dossier summaries become authority without provenance. Generated summaries should be indexes over source facts, not replacements for evidence.

Do not copy the current LangGraph memory-only node without fixing object/dict handling and context formatting.

Do not assume token budgets are enforced because they are configured. Add hard packing rules and tests that prove over-budget dossiers or bridge blocks are trimmed predictably.

## Fit For Agentic Coding Lab

Fit is high as a design source and conditional as a dependency. HMLR directly addresses long-term agent memory, cross-session recall, user constraints, and temporal/causal reasoning. Its architecture gives Agentic Coding Lab several patterns worth adapting.

The best adaptation is a safer, coding-specific version of the lifecycle. During a task, keep a bridge block with current files, commands, errors, decisions, and open questions. At completion, run a gardener that extracts only approved durable memories: repo conventions, verified fixes, command results, architectural decisions, failed approaches, and user constraints. Route those facts into scoped dossiers with source links and timestamps.

The direct package is not ready for use inside a coding agent that handles private repositories. Before adoption, it would need scoped storage, redaction, retention, delete/export paths, deterministic tests, non-live mocked LLM paths, automatic gardening, stricter context packing, provenance-aware prompt authority, and fixed LangGraph/retriever drift.

## Reviewed Paths

- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/README.md`: project claims, architecture diagram, benchmark scenarios, quickstart, and manual gardener note.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/docs/quickstart.md`: client API usage, persistence examples, and best practices.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/docs/configuration.md`: context budgets, bridge-block sizing, retrieval settings, and model caveats.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/docs/installation.md`: dependencies, API key setup, telemetry extra, and database permissions.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/docs/langgraph_integration_design.md`: intended LangGraph memory-node and full-chat-node architecture.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/docs/model_compatibility.md`: model validation warning and expected failure modes.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/docs/MULTI_PROVIDER_GUIDE.md` and `docs/MODEL_CONFIG_QUICK_REFERENCE.md`: provider/model configuration docs and drift evidence.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/pyproject.toml`, `setup.py`, `requirements.txt`, and `requirements-core.txt`: package metadata, optional extras, versioning, and dependency surface.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/main.py`: interactive console entrypoint.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/__init__.py` and `hmlr/client.py`: exported package API and client facade.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/core/component_factory.py`: component wiring, health status, and dependency injection.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/core/conversation_engine.py`: main chat execution path, parallel fact extraction/retrieval, routing, hydration, persistence, and error handling.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/core/config.py`, `model_config.py`, `external_api_client.py`, `prompts.py`, `background_tasks.py`, and `exceptions.py`: environment config, model selection, API boundary, prompt authority, background task handling, and failure classes.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/storage.py`, `persistence/schema.py`, `persistence/ledger_store.py`, and `persistence/dossier_store.py`: SQLite schema, bridge-block persistence, fact storage, dossier storage, provenance, and connection handling.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/models.py`, `conversation_manager.py`, `sliding_window.py`, and `id_generator.py`: memory data models, stateless recent-history view, day/session handling, and id generation.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/chunking/chunk_engine.py` and `chunking/chunk_storage.py`: sentence/paragraph chunking, lexical filters, and chunk storage/search support.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/fact_scrubber.py`: hard-fact extraction, fallback heuristics, provenance linking, and secret/category handling.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/embeddings/embedding_manager.py`: sentence-transformer loading, embedding storage, and gardened-memory vector search.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/retrieval/lattice.py`: `TheGovernor`, bridge-block routing, vector retrieval, two-key filtering, exact fact lookup, dossier retrieval, and causal hydration.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/retrieval/crawler.py`, `context_hydrator.py`, `hmlr_hydrator.py`, and `dossier_retriever.py`: gardened chunk search, final prompt assembly, legacy hydrator behavior, and read-side dossier retrieval.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/dossier_storage.py`: fact-level and dossier-level embedding storage/search.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/synthesis/scribe.py`, `user_profile_manager.py`, `dossier_governor.py`, `dossier_storage.py`, and `synthesis_engine.py`: profile learning, profile persistence, dossier routing/synthesis, and older synthesis scaffolding.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/memory/gardener/manual_gardener.py` and `hmlr/run_gardener.py`: bridge-block consolidation, chunk embedding, tag classification, semantic fact grouping, dossier routing, and archive behavior.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/integrations/langgraph/nodes.py`, `client.py`, `state.py`, and `__init__.py`: LangGraph integration surface, singleton engine cache, state schema, and health behavior.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/hmlr/config/user_profile_lite.json` and `tests/config/user_profile_lite.json`: default/test profile storage shape and package-data concern.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/examples/simple_agent.py`: intended LangGraph agent usage and full-chat vs memory-only modes.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/tests/test_13_hydra_dossier_e2e.py` and `tests/test_13_query_only.py`: long-term dossier Hydra benchmark ingestion, gardening, and query-only harness.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/tests/test_phase_11_9_e_7b_vegetarian_conflict.py`: Scribe/profile constraint extraction and enforcement test.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/tests/test_fact_scrubber_day15.py`, `tests/verify_storage_path.py`, and `tests/RAG_engine_tests/README.md`: fact extraction stress input, storage path check, and embedding model comparison rationale.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/.github/copilot-instructions.md`: project-local coding instructions and design posture.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/.agent/workflows/langgraph-setup.md`: LangGraph setup workflow and integration expectations.

## Excluded Paths

- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/.git/`: VCS internals; exact reviewed commit is recorded separately.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/.vscode/`: editor settings only; not part of memory execution or agent integration behavior.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/.env.example` and `.env.template`: environment examples for API keys and local configuration; reviewed indirectly through docs and config code, not needed for execution-path analysis.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/debug_llm_flow.txt` and `tests/debug_llm_flow.txt`: generated debug prompt/output logs. I sampled the root log to classify it as generated evidence, then excluded it from architectural analysis.
- `/tmp/myagents-research/sean-v-dev-hmlr-agentic-ai-memory-system/.gitignore`, `MANIFEST.in`, `LICENSE`, and `pytest.ini`: repository hygiene and metadata. They were not central to memory architecture beyond package inclusion already reviewed through `pyproject.toml` and setup files.
- Python bytecode caches, virtual environments, local SQLite databases, model weights, generated test output Markdown, and runtime embedding indexes if created locally: generated/runtime artifacts, not source design.
- No vendored third-party source, binary model files, or UI-only application implementation were present in the reviewed checkout.
