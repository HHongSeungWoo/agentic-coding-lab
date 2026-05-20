# agiresearch/A-mem

- URL: https://github.com/agiresearch/A-mem
- Category: memory
- Stars snapshot: 1,018 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: ceffb860f0712bbae97b184d440df62bc910ca8d
- Reviewed at: 2026-05-19T23:23:08+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful small reference for Zettelkasten-style memory notes, LLM-directed linking, and Chroma-backed semantic retrieval, but the repo is closer to a research prototype SDK than an operational agent memory system. Best ideas are structured note metadata, link-aware recall, and explicit evolution prompts. Do not copy the implementation wholesale: persistence is not wired into the main memory system, automatic note construction is mostly claimed rather than executed, linked retrieval is fragile, and there are no real privacy, scoping, auth, or evaluation controls in this package.

## Why It Matters

`agiresearch/A-mem` is a compact implementation of the A-MEM idea: represent each agent memory as a note with content, timestamp, context, keywords, tags, and links, then use an LLM to decide whether new notes should connect to or evolve nearby notes.

For Agentic Coding Lab, the repo matters because it shows a lightweight alternative to heavier memory services. Instead of building a full knowledge graph, task ledger, or trace-learning service, A-Mem tries to make each memory self-describing and lets retrieval pull both semantic hits and related linked memories. That pattern is relevant to coding-agent memories like repo conventions, repeated failures, user preferences, architectural decisions, and "when this happens, do that" lessons.

The practical value is limited by code maturity. The README and framework diagram describe note construction, link generation, memory evolution, and retrieval, but the actual package implements only a thin subset of that flow.

## What It Is

A-Mem is a Python package named `agentic-memory`. The public runtime surface is `AgenticMemorySystem`, backed by `MemoryNote`, `ChromaRetriever`, `PersistentChromaRetriever`, `CopiedChromaRetriever`, and `LLMController`.

The default memory system keeps an in-process `self.memories` dictionary and an ephemeral ChromaDB collection. It can add, read, update, delete, and search memory notes. It can also call OpenAI or Ollama through a small LLM controller to decide whether a new memory should strengthen links or update neighbor metadata.

The repository is intentionally small: one README, one example, three package modules, and tests. There is no server, MCP layer, hook integration, auth layer, durable agent-session ingestion path, or benchmark implementation in this repo. The README points users to `WujiangXu/AgenticMemory` for reproducing paper results.

## Research Themes

- Token efficiency: Moderate idea value, weak implementation. A-Mem stores compact note attributes and retrieves top-k note snippets rather than replaying full conversations. There is no explicit token budget, truncation policy, context pack builder, or prompt-size guard.
- Context control: Weak. Notes have tags, category, context, timestamps, and links, but there is no user/project/agent/run scope, no metadata filter API, no namespace isolation, and no policy that prevents cross-session or cross-agent mixing.
- Sub-agent / multi-agent: Low. `PersistentChromaRetriever` is described as useful for sharing memory across agents, and `CopiedChromaRetriever` can clone a collection into a temporary isolated copy, but `AgenticMemorySystem` does not use these retrievers or expose agent identities.
- Domain-specific workflow: Moderate. Callers can provide tags, category, context, keywords, and timestamps, and the evolution prompt can specialize how links and tags are updated. There are no coding-agent adapters, repo scanners, transcript normalizers, or workflow-specific schemas.
- Error prevention: Low. Some methods catch LLM/Chroma errors and return safe defaults, and persistent collection creation refuses accidental overwrite unless `extend=True`. There is no validation for malformed LLM link IDs, no secret scanning, no update audit log, no deterministic ingest contract, and tests do not isolate OpenAI-dependent paths.
- Self-learning / memory: Strong concept, partial implementation. The core idea is automatic memory evolution through LLM decisions over nearest neighbors, but the actual path has ID-mapping and stale-index issues that make learned links and neighbor updates unreliable.
- Popular skills: Relevant concepts include Zettelkasten note memory, LLM metadata extraction, linked recall, local Ollama memory, Chroma persistence, and temporary collection cloning. There are no packaged Codex/Claude skills or MCP tools.

## Core Execution Path

The main path starts with `AgenticMemorySystem.__init__`. It creates an in-memory `self.memories` dictionary, instantiates a temporary `ChromaRetriever`, tries to reset its client, creates a fresh `ChromaRetriever(collection_name="memories")`, and constructs an `LLMController` for OpenAI or Ollama. The default OpenAI path requires `OPENAI_API_KEY` or an explicit `api_key`.

`add_note(content, time=None, **kwargs)` creates a `MemoryNote`. If `time` is supplied, it maps to the note timestamp. The method then calls `process_memory(note)`, stores the returned note in `self.memories`, serializes all metadata fields into Chroma metadata, and adds the note content to Chroma.

`process_memory(note)` is the evolution path. The first memory bypasses evolution. For later memories, it calls `find_related_memories(note.content, k=5)`, formats nearest neighbors into a plain text block, and sends the new memory plus neighbor text to an LLM with a JSON-schema response format. The LLM can return `should_evolve`, `actions`, `suggested_connections`, `tags_to_update`, `new_context_neighborhood`, and `new_tags_neighborhood`.

If the action is `strengthen`, the code appends `suggested_connections` to the new note's `links` and replaces its tags. If the action is `update_neighbor`, the code updates neighbor tags and context in `self.memories`. These neighbor changes are not immediately written back to Chroma; they only reach Chroma if `consolidate_memories()` later re-adds all memory documents.

`search_agentic(query, k=5)` embeds the query through Chroma, returns top-k hits with metadata, then tries to append linked memories from each result. In practice, linked memories are often truncated away because the method already has `k` vector results and returns `memories[:k]`.

`read(memory_id)` returns the in-memory note. `update(memory_id, **kwargs)` mutates fields, deletes the old Chroma document, and re-adds the new metadata. `delete(memory_id)` removes the Chroma document and the in-memory note. `consolidate_memories()` creates a new Chroma retriever and re-adds all notes; it is an index rebuild, not reflective summarization.

The claimed automatic metadata generation path is `analyze_content(content)`, which asks the LLM for keywords, context, and tags. I did not find it called from `add_note` or `process_memory`, so default note construction does not actually generate those fields unless callers use `analyze_content` themselves or pass metadata explicitly.

## Architecture

The core data object is `MemoryNote`. It holds `content`, UUID `id`, `keywords`, `links`, `retrieval_count`, `timestamp`, `last_accessed`, `context`, `evolution_history`, `category`, and `tags`. Defaults are simple: generated UUID, current minute timestamp, `General` context, `Uncategorized` category, empty tags, empty keywords, empty links, zero retrieval count, and empty evolution history.

Runtime storage is split between Python memory and ChromaDB. `self.memories` is the authoritative object store for reads, updates, links, and deletes. Chroma stores note content plus serialized metadata for semantic search. Metadata lists and dictionaries are JSON-encoded on write and converted back with `ast.literal_eval` on search.

Retrieval is mostly Chroma semantic search. `ChromaRetriever` uses `chromadb.Client(Settings(allow_reset=True))` and `SentenceTransformerEmbeddingFunction`. The imported BM25, tokenizer, cosine similarity, transformer model, and pickle modules in `memory_system.py` are not part of the active retrieval path.

Persistence exists as retriever classes, not as the main system architecture. `PersistentChromaRetriever` uses `chromadb.PersistentClient` with a default `~/.chromadb` directory and has an `extend` guard to avoid silently reusing an existing collection. `CopiedChromaRetriever` clones an existing persistent collection into a temporary Chroma database and cleans it up at exit. `AgenticMemorySystem` does not accept a retriever parameter or directory, so these persistence classes are not wired into the default agent memory lifecycle.

The LLM boundary is small. `OpenAIController` uses the OpenAI chat completions API with a system instruction requiring JSON. `OllamaController` calls LiteLLM with `ollama_chat/<model>`. Both are only used for `analyze_content` when manually called and for memory evolution after at least one memory exists.

## Design Choices

A-Mem chooses note-level memory over raw transcript storage. Each memory is supposed to be an enriched note rather than a raw session chunk. That keeps retrieval compact, but it means memory quality depends heavily on note construction and metadata correctness.

The main "agentic" choice is to delegate link and neighbor-update decisions to an LLM. The evolution prompt asks the model whether to strengthen connections or update neighbor context/tags after seeing the new note and several nearest neighbors.

The repo keeps retrieval simple. It does not build a graph database or relation store; links are just memory IDs stored on each note. Semantic search finds candidate notes, and linked notes are appended as neighbors when possible.

The default system is intentionally ephemeral. This makes examples easy to run and tests easier to reset, but it contradicts the README's stronger persistent-memory positioning unless callers manually use lower-level persistent retrievers.

OpenAI and Ollama are the only LLM backends. This is a pragmatic API surface, but the default OpenAI path sends memory content and neighbor content outside the process unless a local Ollama backend is selected.

## Strengths

The codebase is small enough to audit. The complete memory system fits in a few modules, making the core data model and control flow easy to understand.

The note schema is a useful shape for coding-agent memory. Content, context, keywords, tags, category, timestamps, links, access counters, and evolution history are all reasonable fields for durable lessons and project conventions.

The evolution prompt captures a useful distinction: a new memory can either strengthen a connection or update nearby memories. For Agentic Coding Lab, that maps well to "link this failed test to the fix" and "revise older guidance after a new decision."

The retriever classes include two practical isolation patterns. `PersistentChromaRetriever` avoids accidental collection overwrite by default, and `CopiedChromaRetriever` can fork a shared memory collection into a temporary working copy for an agent run.

The local Ollama example is directionally useful for privacy-sensitive setups. It shows the intended path for avoiding external LLM calls, even though broader privacy controls are missing.

## Weaknesses

Automatic note construction is not actually in the default add path. `analyze_content()` can generate keywords, context, and tags, but `add_note()` never calls it. If callers add plain content, notes usually keep empty keywords/tags and `General` context.

The evolution link path is fragile. `find_related_memories()` formats neighbors as `memory index:0`, `memory index:1`, and so on, not real memory IDs. The LLM is asked for `neighbor_memory_ids`, but it is not given those IDs. Links returned as rank numbers will not resolve in `self.memories`.

Neighbor updates can target the wrong memories. `find_related_memories()` returns rank indices from the Chroma result list, while `process_memory()` applies those indices to `list(self.memories.values())`, which is insertion order rather than the actual retrieved neighbor IDs.

Neighbor metadata updates are stale in Chroma. When evolution updates an existing memory's tags or context, it mutates the in-memory object but does not update the Chroma document until a later `consolidate_memories()` call. With the default `evo_threshold=100`, retrieval metadata can remain stale for many writes.

Linked recall is mostly ineffective when Chroma returns a full top-k set. `search_agentic()` appends linked memories after vector hits, then returns only `memories[:k]`, so appended neighbors are usually dropped.

Persistence is not integrated. The main memory system resets and uses an ephemeral Chroma client; data lives in `self.memories` and is lost when the process ends. Persistent retrievers exist but are not reachable through `AgenticMemorySystem`.

The tests are weak for the core agentic behavior. `tests/test_memory_system.py` instantiates the OpenAI controller directly, so it requires an API key unless the environment is already configured. The tests do not mock LLM evolution decisions enough to validate link correctness, neighbor update targeting, or Chroma staleness.

Safety and privacy controls are minimal. There is no auth, no tenant/user/project scope, no secret or PII redaction, no retention policy, no audit log, no consent flow, and no protection against sending sensitive note and neighbor content to OpenAI.

The README overstates the implementation. It claims comprehensive note generation, persistent memory storage, hybrid retrieval, continuous evolution, and empirical results, but this repo contains no benchmark harness and implements a simpler Chroma-only memory SDK.

## Ideas To Steal

Use a structured note schema for agent memory. A small, typed note with content, context, keywords, tags, timestamps, and links is easier to review and edit than opaque vector chunks.

Make memory evolution explicit. A coding-agent memory system should distinguish "add a new note", "link this note to an older one", and "revise older metadata because new evidence changed the interpretation."

Keep links simple at first. ID-addressed edges between memory notes can provide enough graph behavior for practical recall without adopting a full graph database.

Borrow temporary memory cloning for agent runs. A shared durable memory collection plus per-run copied working memory could let agents experiment with retrieved context without corrupting the source store.

Use local LLM backends for private memory refinement. The Ollama path is a useful default direction for repo memories that may include code, logs, and user-specific preferences.

Represent linked memories as recall expansion, not prompt stuffing. Retrieve semantic top-k first, then add a bounded number of linked notes with clear `is_neighbor` markers and source IDs.

## Do Not Copy

Do not rely on LLM-generated link IDs unless the prompt includes stable real memory IDs and the code validates that returned IDs exist.

Do not update in-memory metadata without updating the retrieval index or marking the index stale. Memory systems need a clear consistency contract.

Do not call the active path "hybrid retrieval" unless there is a real second candidate source such as BM25, keyword search, graph expansion, or metadata filtering.

Do not make external LLM calls over raw memory content by default. Coding-agent memory can include secrets, proprietary code, incident details, and user preferences.

Do not treat persistence helper classes as product persistence. Wire persistence through the main API, document storage paths, and test restart behavior.

Do not copy tests that require real API keys for basic unit coverage. Mock the LLM controller and Chroma embedding boundary for deterministic local verification.

Do not use a global collection name like `memories` without user/project/repo/run namespacing.

## Fit For Agentic Coding Lab

Fit is moderate to high as a design source, low as a dependency. The repo is in scope for memory research because it directly implements note storage, retrieval, update, deletion, and evolution. It is not mature enough to adopt as the lab's memory substrate.

The best Agentic Coding Lab pattern is a corrected A-Mem-style note graph: durable repo-scoped memory notes, explicit source/provenance fields, validated links, bounded link expansion, local-first LLM metadata refinement, and deterministic tests around evolution decisions.

For coding agents, the note schema should be tightened: `repo_id`, `branch_or_worktree`, `task_id`, `source_path`, `source_event`, `privacy_class`, `confidence`, `supersedes`, and `valid_until` would matter more than broad category strings. Evolution should update links and tags through auditable operations rather than silent LLM mutation.

This repo should be used as a cautionary example too. Memory architecture diagrams can look complete while the execution path misses key pieces. For future Agentic Coding Lab artifacts, every claimed memory operation should have a test that exercises storage, retrieval, link expansion, update consistency, and restart behavior.

## Reviewed Paths

- `/tmp/myagents-research/agiresearch-a-mem/README.md`: positioning, paper link, claimed memory lifecycle, quickstart, API examples, best practices, and citation.
- `/tmp/myagents-research/agiresearch-a-mem/pyproject.toml`: package metadata, dependency set, pytest configuration, and Python package scope.
- `/tmp/myagents-research/agiresearch-a-mem/requirements.txt`: runtime dependency drift from `pyproject.toml`, including Ollama and transformers.
- `/tmp/myagents-research/agiresearch-a-mem/LICENSE`: MIT license and warranty posture.
- `/tmp/myagents-research/agiresearch-a-mem/agentic_memory/memory_system.py`: `MemoryNote`, `AgenticMemorySystem`, add/read/update/delete/search, note analysis, evolution prompt, consolidation, and active retrieval behavior.
- `/tmp/myagents-research/agiresearch-a-mem/agentic_memory/retrievers.py`: Chroma storage, metadata serialization, persistent retriever, copied temporary retriever, and collection overwrite guard.
- `/tmp/myagents-research/agiresearch-a-mem/agentic_memory/llm_controller.py`: OpenAI and Ollama controller behavior, API key handling, JSON response formatting, and LiteLLM boundary.
- `/tmp/myagents-research/agiresearch-a-mem/agentic_memory/__init__.py`: empty package initializer.
- `/tmp/myagents-research/agiresearch-a-mem/examples/sovereign_memory.py`: local Ollama example and privacy-oriented usage surface.
- `/tmp/myagents-research/agiresearch-a-mem/tests/conftest.py`: Chroma fixtures, temporary persistent DB setup, and reset behavior.
- `/tmp/myagents-research/agiresearch-a-mem/tests/test_memory_system.py`: memory CRUD, metadata, relationships, evolution, search, and consolidation coverage.
- `/tmp/myagents-research/agiresearch-a-mem/tests/test_retriever.py`: Chroma add/delete/search, metadata conversion, persistent collection behavior, and default directory behavior.
- `/tmp/myagents-research/agiresearch-a-mem/tests/test_utils.py`: unused mock LLM controller helper.
- `/tmp/myagents-research/agiresearch-a-mem/Figure/framework.jpg`: reviewed as architecture diagram evidence for note construction, link generation, memory evolution, and retrieval claims.

## Excluded Paths

- `/tmp/myagents-research/agiresearch-a-mem/.git/`: VCS internals; exact reviewed commit is recorded separately.
- `/tmp/myagents-research/agiresearch-a-mem/Figure/intro-a.jpg` and `/tmp/myagents-research/agiresearch-a-mem/Figure/intro-b.jpg`: presentation images comparing memory concepts; not implementation logic.
- Remaining binary image data under `/tmp/myagents-research/agiresearch-a-mem/Figure/`: excluded after reviewing the framework image because binary assets do not define execution behavior.
- Python bytecode caches, local virtual environments, Chroma runtime databases, and test cache directories if generated locally: generated artifacts, not source architecture.
- Upstream paper reproduction code in `WujiangXu/AgenticMemory`: explicitly referenced by the README as a separate repository and outside this assigned repo review.
