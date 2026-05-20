# caspianmoon/memoripy

- URL: https://github.com/caspianmoon/memoripy
- Category: memory
- Stars snapshot: 691 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: ffa11daf41f2b96b1c028fa9853d7812948a8bd8
- Reviewed at: 2026-05-19 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Small, readable in-scope memory layer with useful primitives for short-term interaction storage, concept extraction, decay/reinforcement scoring, concept-graph activation, and KMeans semantic clusters. Treat it as a lightweight design sketch rather than production memory infrastructure: long-term memory is promoted but not retrieved as a distinct layer, semantic clusters are only built during initialization, storage is plaintext, tests are absent, and privacy/safety controls are not implemented.

## Why It Matters

`caspianmoon/memoripy` is a compact example of an agent memory loop that is easy to audit end to end. It shows how a Python app can store prompt/output pairs, attach embeddings and LLM-extracted concepts, retrieve relevant prior interactions, and feed both recent and retrieved context into a later response.

For Agentic Coding Lab, its value is not breadth. The repo is useful because the full memory model fits in a few files and makes tradeoffs visible: direct embedding similarity plus concept activation, local JSON or in-memory persistence, DynamoDB as an optional remote store, and simple promotion rules from short-term to long-term memory. That makes it a good contrast to heavier memory services.

## What It Is

Memoripy is a Python package exposing `MemoryManager`, `MemoryStore`, storage adapters, and model adapters for OpenAI, Azure OpenAI, OpenRouter-compatible chat completions, and Ollama. The primary app path is shown in examples rather than the stale `memoripy/main.py`.

The runtime stores interactions as dictionaries with `id`, `prompt`, `output`, `embedding`, `timestamp`, `access_count`, `concepts`, and `decay_factor`. Short-term memory is the active retrieval set. Long-term memory is a list of frequently accessed interactions persisted by storage adapters, but it is not searched through its own retrieval path.

## Research Themes

- Token efficiency: Moderate. Retrieval returns only a small context window of recent interactions and top retrieved memories. There is no tokenizer-aware budget, deduplication, summarization, compression, or context packing.
- Context control: Basic. Callers can exclude the last N interactions from semantic retrieval and can choose the response `context_window`. There is no project/user/agent/run scope in JSON or in-memory storage; DynamoDB has a `set_id` partition that can separate memory sets.
- Sub-agent / multi-agent: Weak. DynamoDB `set_id` can represent a user or memory set, but there is no multi-agent ownership model, conflict handling, locking, or authority metadata.
- Domain-specific workflow: Weak. Concepts are generic LLM-extracted strings, and examples are chat-oriented. There are no coding-specific schemas for files, commands, failures, decisions, tests, or repository conventions.
- Error prevention: Limited. Interfaces are small and embedding dimension is normalized by padding or truncation, but there are no tests, validation harnesses, redaction checks, scope guards, or deterministic quality checks. The packaged `memoripy/main.py` is stale relative to the current `MemoryManager` constructor.
- Self-learning / memory: Core fit. The package stores interactions, reinforces retrieved memories via access counts, decays non-relevant memories, promotes frequently used records to long-term memory, builds a concept graph, and clusters embeddings into semantic groups.
- Popular skills: No reusable coding-agent skills or MCP tools are included. The transferable artifact is the memory algorithm skeleton, not an installed agent workflow.

## Core Execution Path

The live example path constructs model adapters, chooses a storage adapter, creates `MemoryManager(chat_model, embedding_model, storage=...)`, loads recent history, retrieves relevant interactions for a new prompt, generates a response, extracts concepts from prompt plus response, embeds the combined text, and stores the new interaction.

`MemoryManager.__init__()` asks the embedding model for its dimension, creates a `MemoryStore`, selects `InMemoryStorage` when no storage is supplied, and calls `initialize_memory()`. Initialization loads short-term and long-term history from storage, standardizes short-term embeddings to the current dimension, adds short-term records to the active store, extends the long-term list, and then calls `cluster_interactions()`.

`add_interaction()` generates a UUID and timestamp, stores prompt/output/embedding/concepts with `access_count=1` and `decay_factor=1.0`, adds the record to `MemoryStore`, and immediately persists the entire store through the selected adapter.

`retrieve_relevant_interactions()` embeds the query, asks the chat model to extract query concepts, and delegates to `MemoryStore.retrieve()`. Retrieval scans active short-term memory, computes cosine similarity against normalized embeddings, applies exponential time decay, multiplies by a logarithmic reinforcement factor, increments access count for matches above the threshold, decays non-matches, runs two-step spreading activation over the concept graph, adds activation scores to matched interactions, sorts by total score, and appends up to five interactions from the nearest semantic cluster.

`generate_response()` concatenates the last few interactions and top retrievals as plain text, then sends a fixed system message and one human message to the chat model. There is no role-preserving transcript reconstruction, token budget, provenance marker, or safety filtering before injection.

## Architecture

The package has four layers.

`MemoryManager` is the application facade. It owns the chat model, embedding model, storage adapter, and `MemoryStore`. It also performs concept extraction, embedding generation, history loading, history saving, retrieval, and response generation.

`MemoryStore` is the in-process memory engine. It keeps short-term records, long-term records, embedding arrays, timestamps, access counters, concept sets, a NetworkX concept graph, FAISS `IndexFlatL2`, and KMeans cluster assignments. The FAISS index is populated but the reviewed retrieval implementation uses `sklearn.metrics.pairwise.cosine_similarity` over the embedding list rather than FAISS search.

Storage adapters implement `load_history()` and `save_memory_to_history()`. `InMemoryStorage` keeps a process-local dictionary. `JSONStorage` persists plaintext JSON with short-term records including embeddings and concepts. `DynamoStorage` uses PynamoDB with one item per `set_id`, containing lists of short-term and long-term memory map attributes.

Model adapters implement abstract `ChatModel` and `EmbeddingModel` interfaces. OpenAI and Azure embedding adapters support `text-embedding-3-small` with a hard-coded 1536 dimension. Ollama embedding initialization performs a live embedding call to discover dimension. Chat adapters use LangChain chat clients and a JSON output parser around the `ConceptExtractionResponse` schema.

## Design Choices

The repo stores whole prompt/output pairs as memory units. It does not extract durable facts separately from raw interactions. This keeps implementation small, but makes retrieval output bulky and privacy-sensitive.

The active memory set is short-term memory. Long-term promotion happens when access count exceeds 10, but promoted records stay in short-term memory and long-term memory has no separate retrieval algorithm. In practice, long-term memory is more of a persisted label than a colder searchable tier.

Retrieval uses a transparent scoring formula. Similarity is multiplied by decay and reinforcement, then concept spreading activation is added. This is easy to reason about and tune, but it is heuristic and uncalibrated.

Concepts are extracted by the same chat-model interface used for responses. This avoids a second extraction dependency but turns memory writes and queries into LLM calls, with no fallback parser beyond LangChain's JSON parser.

Semantic clustering is batch-oriented. KMeans runs during initialization when at least two embeddings exist and populates `semantic_memory`. New interactions added after initialization do not update clusters unless the process restarts or code calls clustering again.

Storage writes the complete memory state after each added interaction. This is simple and acceptable for small local histories, but it lacks append-only logs, transactions for JSON, incremental writes, retention controls, and migration/version metadata.

## Strengths

The core is small enough to review completely. `MemoryManager`, `MemoryStore`, model adapters, and storage adapters expose the whole execution path without hidden service dependencies.

The scoring model is explicit. Decay, reinforcement, semantic similarity, concept graph activation, and cluster recall are visible in one retrieval function.

The storage abstraction is minimal and portable. In-memory, JSON, and DynamoDB adapters all follow the same two-method interface, which is easy to replace with a project-local SQLite or Markdown-backed store.

The concept graph is a useful lightweight pattern. Co-occurring concepts become weighted edges, and query concepts can activate neighboring concepts for ranking. This is cheaper than a full knowledge graph and easier to inspect.

The examples show the intended loop clearly: retrieve before response, generate, extract concepts from prompt plus answer, embed, and store. That maps directly to agent session memory.

## Weaknesses

Long-term memory is underdeveloped. Promotion copies frequently retrieved short-term records into `long_term_memory`, but retrieval only searches short-term embeddings and semantic clusters built from short-term embeddings. Loaded long-term records are not re-embedded, clustered, or searched as their own tier.

Semantic clustering can go stale. `cluster_interactions()` runs during initialization, not after each added interaction. Newly stored records participate in direct similarity retrieval, but not cluster retrieval until a later recluster.

The FAISS index is not used for the reviewed search path. Embeddings are added to `IndexFlatL2`, but retrieval loops through embeddings with sklearn cosine similarity. That keeps behavior simple but misses FAISS's scaling purpose.

There are no tests in the repository. I found examples and compile-valid Python, but no unit tests for storage round trips, retrieval ranking, long-term promotion, concept parsing, DynamoDB schemas, or stale cluster behavior.

The packaged `memoripy/main.py` appears stale. It imports local modules without package-relative imports and passes keyword arguments such as `api_key`, `chat_model`, and `embedding_model` to `MemoryManager`, but the current constructor expects concrete `ChatModel` and `EmbeddingModel` objects.

Privacy and safety controls are absent. JSON and DynamoDB storage persist raw prompts, raw outputs, embeddings, concepts, timestamps, and access counters. There is no redaction, consent gate, retention policy, encryption, per-memory delete API, secret detection, or scope enforcement beyond optional DynamoDB `set_id` separation.

Dependency and packaging hygiene is uneven. `setup.py` pins a broad dependency tree, README says Apache 2.0 while the classifier says MIT, and DynamoDB support imports PynamoDB and dotenv but `__init__.py` does not export `DynamoStorage`.

## Ideas To Steal

Use a simple two-method storage interface for memory backends. `load_history()` and `save_memory_to_history(memory_store)` are enough for early prototypes and make swapping persistence easy.

Keep transparent decay and reinforcement fields on each memory. `access_count`, `timestamp`, and `decay_factor` are cheap metadata that can support later memory lifecycle policies.

Build a lightweight concept graph from extracted concepts. For coding agents, concepts could be normalized package names, files, commands, test names, failures, and decisions, then used as a ranking signal beside embeddings.

Separate "recent context" from "retrieved context" at prompt assembly time. Even this simple example shows why last interactions and semantically recalled interactions should be handled as distinct sources.

Make embedding dimension part of initialization and normalize old records on load. This is useful when memory survives model changes, although production systems should prefer explicit migrations over silent padding/truncation.

Use examples as executable lifecycle documentation. The examples are repetitive, but they make the intended memory flow clear across providers and storage backends.

## Do Not Copy

Do not treat promoted long-term memory as actually retrievable unless the long-term tier has its own index, concepts, retention policy, and recall path.

Do not persist raw prompts and outputs by default for coding agents. Add redaction, memory classes, user/repo/agent/run scope, retention, and delete paths before storing real work sessions.

Do not silently pad or truncate embeddings in a production memory store. Record embedding model and dimension per memory, then migrate or rebuild indexes deliberately.

Do not rely on LLM-extracted concept strings without normalization. Coding memory needs stable identifiers for files, symbols, commands, packages, issues, and tests.

Do not copy the stale `memoripy/main.py` entrypoint as current usage. The examples using concrete model adapter objects match the current constructor.

Do not use KMeans clusters as a continuously updated semantic memory without an incremental update or scheduled reclustering strategy.

## Fit For Agentic Coding Lab

Fit is moderate as a memory pattern reference and weak as a dependency. Memoripy is small, readable, and directly about short-term plus long-term memory, so it belongs in the `memory` category. It is most useful as a prototype baseline for explaining memory mechanics.

Agentic Coding Lab should borrow the compact lifecycle and explicit metadata fields, then replace the weak parts. A coding-agent version should store scoped memory records with source provenance, type, confidence, retention policy, redaction state, and embedding metadata. Retrieval should combine recent session state, scoped vector search, exact symbol/command matching, and verified project facts. Long-term promotion should move memories into a real durable tier, not just duplicate them into a list.

The practical adaptation is a small local memory module: capture selected agent-session events, extract normalized coding concepts, store redacted records in SQLite or Markdown-backed notes, retrieve with strict repo/user scope, and expose why each memory was recalled. Memoripy provides the skeleton for that loop but not the governance needed for private coding work.

## Reviewed Paths

- `/tmp/myagents-research/caspianmoon-memoripy/README.md`: feature claims, quickstart lifecycle, dependency overview, and storage/model positioning.
- `/tmp/myagents-research/caspianmoon-memoripy/setup.py` and `/tmp/myagents-research/caspianmoon-memoripy/requirements.txt`: packaging metadata, dependency surface, and model/storage support evidence.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/__init__.py`: exported package API.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/model.py`: abstract chat and embedding model contracts.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/implemented_models.py`: OpenAI, Azure OpenAI, Ollama, OpenRouter, and generic chat-completions adapters plus concept extraction prompts.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/memory_manager.py`: facade for initialization, embedding, concept extraction, retrieval, response generation, and memory writes.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/memory_store.py`: short-term/long-term memory structures, decay/reinforcement scoring, concept graph, semantic clustering, and retrieval algorithm.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/storage.py`, `/tmp/myagents-research/caspianmoon-memoripy/memoripy/in_memory_storage.py`, and `/tmp/myagents-research/caspianmoon-memoripy/memoripy/json_storage.py`: storage interface, process-local persistence, and plaintext JSON schema.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/dynamo_storage.py`: DynamoDB schema, `set_id` partitioning, environment configuration, and save/load behavior.
- `/tmp/myagents-research/caspianmoon-memoripy/memoripy/main.py`: reviewed as stale entrypoint evidence, not as the recommended execution path.
- `/tmp/myagents-research/caspianmoon-memoripy/examples/README.md`, `examples/openai_example.py`, `examples/azure_example.py`, `examples/openrouter.py`, and `examples/chatcompletions.py`: supported provider examples and intended usage loop.
- `/tmp/myagents-research/caspianmoon-memoripy/examples/dynamo/README.md`, `examples/dynamo/dynamo_example.py`, `examples/dynamo/compose.yaml`, `examples/dynamo/local.env`, and `examples/dynamo/aws.env`: DynamoDB storage example, local/AWS environment shape, and deployment helper.
- `/tmp/myagents-research/caspianmoon-memoripy/.gitignore` and `/tmp/myagents-research/caspianmoon-memoripy/LICENSE`: repository hygiene, ignored generated files, and license text.

## Excluded Paths

- `/tmp/myagents-research/caspianmoon-memoripy/.git/`: VCS internals; exact reviewed commit is captured separately.
- `/tmp/myagents-research/caspianmoon-memoripy/examples/dynamo/data/`: placeholder local DynamoDB data directory containing only `.gitkeep`; no memory logic to review.
- `/tmp/myagents-research/caspianmoon-memoripy/**/__pycache__/`: generated Python bytecode from local compile verification; excluded as generated output.
- No vendored third-party source, binary model files, generated SDKs, or UI-only application paths were present in the reviewed checkout. Dependency pins and example deployment files were reviewed only for architecture and safety implications.
