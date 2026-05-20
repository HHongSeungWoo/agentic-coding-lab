# zmedelis/bosquet

- URL: https://github.com/zmedelis/bosquet
- Category: memory
- Stars snapshot: 371 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: ff475f86b5ed6c3362bc79e8aa53251897b870a2
- Reviewed at: 2026-05-20 (Asia/Seoul)
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful Clojure reference for prompt graph composition, chat composition, tool calls, simple RAG memory, Qdrant-backed embedding recall, tokenizer-bounded retrieval, and provider resilience. Treat it as a library of building-block patterns, not as a production agent memory system: memory is mostly caller-orchestrated, protocol integration is incomplete, Qdrant storage has weak lifecycle controls, privacy policy is minimal, and several agent/MCP paths are prototypes.

## Why It Matters

Bosquet sits at the intersection of prompt composition and memory. Most memory systems focus on storage and retrieval, then leave prompt assembly implicit. Bosquet makes prompt assembly explicit: Selmer templates define slots, Pathom resolves graph dependencies, chat tuples preserve generated assistant outputs, and retrieved memories can be injected into the same prompt data map as ordinary variables.

For Agentic Coding Lab, this is valuable because coding-agent memory should not be just a vector search result. The useful part is the execution contract around "which remembered facts become which prompt variables, in what order, under which token budget, and with which generated outputs tracked afterward." Bosquet shows a compact version of that contract, even though its memory layer is not mature enough to copy directly.

## What It Is

Bosquet is a Clojure library and CLI for LLM application tooling. The active runtime surface includes:

- prompt templating with Selmer;
- prompt graph composition through Pathom resolvers;
- linear chat generation with role tuples and named completions;
- OpenAI-shaped, Ollama, Claude, Cohere, Mistral, Perplexity, Groq, LM Studio, and LocalAI provider configuration;
- tool calling for OpenAI and Ollama using Clojure var metadata;
- MCP stdio client support that dynamically interns MCP tools into a namespace;
- short-term memory backed by a process-global atom and lexical cosine distance;
- long-term memory backed by provider embeddings plus Qdrant vector search;
- document parsing and text chunking helpers for RAG pipelines;
- retry, fallback, and circuit-breaker wrappers for LLM calls.

It is not a full agent memory platform. There is no built-in memory policy for coding sessions, no durable scoped memory schema, no review/delete/forget workflow above Qdrant deletion, no provenance-aware prompt packer, and no auth or tenant model.

## Research Themes

- Token efficiency: Good primitives, partial system. `bosquet.memory.retrieval/take-while-tokens` limits recalled objects using OpenAI token counting, and text splitting supports token chunks with overlap. Prompt graph generation tracks usage per generated variable. There is no global context budgeter that allocates tokens across system prompts, current request, retrieved memory, tool results, and history.
- Context control: Strong for prompt composition, weak for memory governance. Selmer plus Pathom can build deterministic prompt graphs and leave later generation slots unresolved. Memory recall can select payload fields with `:memory.retrieval/content`, but memories lack user, repo, branch, run, source, trust, privacy, and retention metadata.
- Sub-agent / multi-agent: Limited. `bosquet.agent.graph` can run graph-shaped agent workflows with interruptions and history, and the ReAct example has tool action parsing, but multi-agent ownership, shared memory, conflict control, and scoped writes are absent.
- Domain-specific workflow: Moderate. The framework is generic, but the prompt graph, document loading, chunking, dynamic few-shot retrieval, and verification examples map well to coding workflows such as extracting project facts, retrieving relevant examples, and composing evaluation prompts.
- Error prevention: Mixed. LLM calls have retry, fallback, and circuit-breaker support, and output coercion can parse JSON, EDN, lists, numbers, and booleans. Tool execution and MCP process spawning have little sandboxing, memory writes have no validation or redaction, and Qdrant operations lack robust error handling and tested deletion behavior.
- Self-learning / memory: Conditional. Bosquet has working remember/recall closures and a memory protocol sketch, but it does not learn from agent traces, extract durable facts, consolidate memories, resolve conflicts, decay stale facts, or update memories after task outcomes.
- Popular skills: Prompt graph composition, RAG memory, dynamic few-shot example selection, tokenizer-aware memory truncation, tool metadata extraction, MCP stdio wrapping, provider fallback, and local configuration with secrets files.

## Core Execution Path

The main generation path is `bosquet.llm.generator/generate`. It dispatches by input shape. A string prompt is converted into a prompt graph with one default generation slot. A vector of `[role content]` tuples runs chat mode. A map runs graph mode, where non-map nodes are templates and map nodes are LLM or function calls.

Graph generation starts by splitting templates from generator nodes. `prep-graph` joins vector templates and fills caller-supplied data. `generation-resolver` creates Pathom resolvers for each node. Template resolvers use ordered Selmer variable discovery to declare dependencies. LLM resolvers find templates that refer to a generation key, clear text after that slot, render the prompt, call the configured LLM, and store the result under `:bosquet/completions`. `complete-graph` then walks top-level templates and executes the corresponding chat sequence.

Chat generation loops through role tuples. User and system content is rendered against the accumulated context. Assistant tuples hold an LLM spec created by `llm`; Bosquet calls the provider chat function with prior processed messages, stores the generated text under the tuple's `:llm/var-name`, appends it to the conversation, and accumulates token usage.

The memory path is separate from `generate`. `simple-memory/->remember` appends observations to a global atom. `simple-memory/->cue-memory` filters that atom by Apache Commons Text cosine distance against a cue, then optionally applies object and token limits. `long-term-memory/->remember` embeds observations in batches, creates a Qdrant collection, and writes `{embedding, payload}` pairs. `long-term-memory/->cue-memory` embeds the cue, searches Qdrant, extracts payloads, then applies the same object/token limiting helper.

The main documented memory example is `notebook/memory_prosocial_dialog.clj`. It loads a HuggingFace dataset, stores examples in simple memory or Qdrant-backed long-term memory, recalls a few examples for a harmful user post, and injects the first retrieved item into a chat prompt containing rules of thumb and safety annotation reasons. The named-entity notebook uses simple memory for dynamic few-shot examples, then runs extraction and verification prompt stages.

Tool calling flows through provider adapters. `tool->function` converts Clojure vars and arg metadata into OpenAI-style function definitions. Provider results with `tool_calls` are parsed, matching vars are invoked locally, tool messages are appended, and the provider is called again without the tool key. MCP support can spawn stdio MCP servers, list tools, create Clojure wrapper functions from MCP schemas, and pass those vars into the same tool-calling path.

## Architecture

Bosquet has several small layers rather than one monolithic agent runtime.

`resources/env.edn` is the configuration root. It defines provider endpoints, default model parameters, provider function symbols, Qdrant defaults, and resilience defaults. `config.edn` and `secrets.edn` from the project root or `~/.bosquet` override those defaults. `bosquet.env` resolves model names to providers and can write config or secrets through the CLI.

`bosquet.llm.generator` is the prompt orchestration core. It owns prompt graph preparation, Pathom resolver registration, Selmer rendering, ChatML conversion, provider dispatch, output coercion, caching, usage aggregation, and resilience handoff.

`bosquet.memory.*` is a small memory package. `memory.clj` sketches a `Memory` protocol with remember, forget, free recall, sequential recall, cue recall, and volume. The active demo path mostly uses factory functions instead of protocol implementations. `simple_memory.clj` stores raw items in an atom. `long_term_memory.clj` delegates persistence to a `VectorDB` protocol and embeddings to configured provider functions. `retrieval.clj` contains recall keys, token counting, and tokenizer-bounded selection.

`bosquet.db.qdrant` is the only vector database implementation. It creates collections, writes points with UUIDs, performs vector search, and returns IDs, scores, and payloads. It uses global config for the Qdrant endpoint and collection-specific params for collection name and vector size.

`bosquet.nlp` and `bosquet.read` provide RAG input helpers. Text can be split by characters, OpenNLP sentences, or model tokens; documents can be parsed through Apache Tika into text and metadata.

`bosquet.agent` contains prototypes. `graph.clj` defines graph, node, and agent macros with history and interrupt support. `react.clj` contains a partially disabled ReAct loop. `wikipedia.clj` implements a simple external tool. These are useful examples but are not a hardened agent runtime.

## Design Choices

Prompt composition is data-first. Prompts are EDN maps, vectors, and strings, not imperative chains. That makes prompt graphs inspectable, reusable, and easy to test with fake providers.

Generation slots are explicit. A template such as `Question: {{question}} Answer: {{answer}}` declares where an LLM result belongs. Bosquet clears the slot before generating so the model sees only the upstream context, then fills completions back into downstream templates.

Memory is caller-composed rather than automatically injected. This avoids hidden retrieval behavior, but it means each application has to decide when to remember, when to recall, which fields become prompt variables, and how to handle empty or unsafe memories.

Simple memory intentionally favors development ergonomics. A global atom plus lexical distance is easy to inspect and test, but it is process-local, unscoped, and unsuitable for production memories.

Long-term memory stores full payloads beside embeddings. This keeps Qdrant search useful without a second document store, but it also means raw examples, user text, or sensitive project facts can be stored directly in the vector database.

The retrieval limit is recency-biased after candidate selection. Both simple and long-term memory call `retrieve-in-sequnce`, which takes the last objects and token-bounds them. For Qdrant, candidates are similarity-ranked before this step; for simple memory, candidates preserve atom order after lexical filtering. This is compact but can hide ranking evidence from prompt assembly.

Provider resilience is modeled at the LLM call boundary. A generation node can include `:llm/resilience` with primary and fallback provider specs. That is a useful boundary for production prompt composition, though memory writes and vector search do not receive the same resilience treatment.

## Strengths

The prompt graph execution path is concrete and testable. Tests use fake providers to verify chat composition, graph generation, slot filling, caching, and usage aggregation without live LLM calls.

Bosquet keeps generated outputs named. `:bosquet/completions` records each generation by key, and chat mode records a full `:bosquet/conversation`. That is a good pattern for later memory extraction because every generated artifact has an address.

The memory examples show practical RAG assembly rather than just vector search. Retrieved examples are converted into task-specific prompt variables, such as rules of thumb, demonstrations, or contexts.

Tokenizer-aware recall exists as a small reusable function. Even though it is not a full budgeter, it is the right primitive for preventing memory recall from overflowing the prompt.

The library supports local-first paths. Ollama can serve chat and embeddings, Qdrant can run locally, secrets can live in local EDN files, and MCP stdio tools can be local processes.

Provider resilience was added recently and is well covered by unit tests. Retry behavior, recoverable fallback, non-recoverable failures, and completion fallback have deterministic test coverage.

Tool metadata extraction is compact. Clojure var metadata becomes function schema, which is a simple way to keep tool definitions close to code.

## Weaknesses

Memory is not integrated into the main generation path. `available-memories` exists, but the real examples call recall functions manually and pass retrieved items as prompt data. There is no standard memory middleware around `generate`.

The `Memory` protocol is mostly a sketch. `simple_memory` and `long_term_memory` expose closure factories, while a `LongTermMemory` protocol implementation is commented out. The protocol path is therefore not the actual execution path.

`available-memories` logs and branches on the symbol `type`, not the configured memory system. Because `type` resolves to a core function, the branch is always truthy, and the "No memory specified" logging path is misleading. The no-memory test still passes because `handle-recall` falls back to the current messages.

Simple memory is global and unscoped. All remembered items share one atom, and tests call `forget` to reset it. There is no project/user/session namespace, concurrent write discipline, retention, or per-item deletion.

Qdrant storage has weak lifecycle controls. Collection creation is automatic, writes are async through core.async without a completion handle, deletion appears incorrectly wired, and there are no Qdrant tests for collection creation, write, search, delete, restart, or schema drift.

Retrieved memory lacks provenance. Qdrant search returns IDs and scores internally, but `long-term-memory/->cue-memory` maps results to payload only. Prompt assembly loses score, vector ID, collection, embedding model, and retrieval reason.

Privacy controls are minimal. `.gitignore` excludes `config.edn`, `secrets.edn`, data, models, and Qdrant storage, which is good repository hygiene. But memory payloads, embeddings, prompt cache entries, proxy logs, and provider requests have no redaction, consent, retention, encryption, or audit layer. `utils/log-call` logs request parameters except messages; observability docs encourage Mitproxy capture of full request and response data.

Tool and MCP execution trust boundaries are broad. Tool functions are invoked directly in-process, and MCP stdio configs can spawn arbitrary commands from config. There is no allow-list, permission prompt, timeout, output budget, or sandbox wrapper in the reviewed path.

Several examples are stale or prototype-grade. `notebook/examples/rag.clj` refers to `bosquet.system/get-memory`, which is absent. The ReAct loop in `react.clj` is mostly commented out after initial generation. Generated docs are WIP and largely mirror notebooks.

## Ideas To Steal

Represent prompt workflows as data graphs. Agentic Coding Lab memory prompts should declare dependencies such as `current task`, `retrieved decisions`, `similar failures`, `test evidence`, and `answer` as named nodes instead of one opaque string.

Keep memory injection explicit. Retrieval should produce a structured data map that prompt templates consume, so the system can test exactly which memories reached the model.

Preserve generated outputs by stable names. A memory extractor can later say "store the `:fix-summary` completion and link it to command `npm run test`" rather than scraping raw transcripts.

Use tokenizer-bounded recall as a primitive. A lab memory API should expose object limits and token limits, then return omitted-count metadata when budget removes memories.

Separate candidate retrieval from prompt packing. Qdrant should return candidates with score and provenance; a later packer should decide which candidates fit the current prompt budget.

Use local EDN or Markdown for declarative prompt packs. Bosquet's prompt palettes are simple, reviewable artifacts that fit well with skills, coding workflows, and repo-local templates.

Borrow provider fallback at the generation-node level. A coding workflow can mark cheap extraction prompts, important review prompts, and privacy-sensitive local prompts with different fallback policies.

Convert tool metadata from code declarations. Keeping descriptions and arg schemas on functions reduces drift between tool implementation and model-facing schema.

## Do Not Copy

Do not use a process-global memory atom for real coding-agent memory. Use explicit repo, user, task, branch, and run scope with durable storage and clear reset/delete behavior.

Do not drop retrieval provenance before prompt assembly. Memory items should carry ID, score, source, embedding model, timestamp, scope, and reason for recall.

Do not store raw prompts, tool outputs, datasets, or code snippets in vector storage without redaction and retention rules.

Do not spawn MCP stdio commands from config without an allow-list, timeout, resource limits, and user-visible trust boundary.

Do not let memory writes be fire-and-forget. Embedding and vector writes need completion, retry, failure reporting, and idempotent IDs.

Do not treat lexical cosine distance as semantic memory. It is acceptable for dev examples and dynamic few-shot demos, but coding memory needs exact path/symbol matching, BM25 or FTS, vector search, and metadata filters.

Do not tie memory token counting only to OpenAI models. A multi-provider agent should have a budget model per target provider or conservative fallback.

## Fit For Agentic Coding Lab

Fit is conditional but useful. Bosquet should not become the lab's memory backend, but it is a strong source for prompt-composition patterns around memory. Its best contribution is the explicit connection between retrieval output and named prompt slots.

For Agentic Coding Lab, the adaptation should be a small memory-aware prompt graph runner: retrieve scoped memory candidates, expose them as named template variables with provenance, build the prompt through a deterministic graph, call the model, record named completions, then run a separate reviewed memory-write step.

The memory layer should be rebuilt with coding-specific records: file paths, symbols, commands, failures, fixes, decisions, owner, task ID, branch/worktree, confidence, privacy class, source event, and expiry. Retrieval should combine exact filters, text search, vector search, and link expansion under one prompt budget.

Bosquet's cautionary lesson is also important. A repo can advertise "LLM memory handling" while the actual path is still manual RAG helper code. Future lab artifacts should make the real path obvious: capture, normalize, store, retrieve, pack, cite, update, forget, and test each step.

## Reviewed Paths

- `/tmp/myagents-research/zmedelis-bosquet/README.md`: project positioning, CLI usage, prompt graph examples, chat examples, and tool-calling examples.
- `/tmp/myagents-research/zmedelis-bosquet/deps.edn`, `bb.edn`, `tests.edn`, `.gitignore`, `config.edn.sample`, and `secrets.edn.sample`: dependency surface, build/test tasks, ignored local data/secrets, and local configuration shape.
- `/tmp/myagents-research/zmedelis-bosquet/resources/env.edn`: provider registry, Qdrant defaults, model-name routing, secrets/config includes, and resilience defaults.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/env.clj`, `src/bosquet/cli.clj`, and `src/bosquet/utils.clj`: config loading/writing, CLI key/default management, proxy setup, logging, JSON/EDN helpers, and circuit-breaker defaults.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/llm/generator.clj`: string, chat, and graph generation; Pathom resolvers; Selmer rendering; LLM dispatch; completions; usage; cache; and resilience handoff.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/template/read.clj` and `src/bosquet/template/selmer.clj`: prompt palette loading, data-slot detection, ordered variable parsing, missing-slot behavior, and generation-slot clearing.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/llm/openai.clj`, `oai_shaped_llm.clj`, `ollama.clj`, `claude.clj`, `cohere.clj`, `localai.clj`, `http.clj`, `resilience.clj`, `tools.clj`, `schema.clj`, `gen_data.clj`, and `openai_tokens.clj`: provider adapters, HTTP boundary, output coercion, usage accounting, tool calls, fallback, retry, and token counting.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/memory/memory.clj`, `simple_memory.clj`, `long_term_memory.clj`, `retrieval.clj`, and `encoding.clj`: protocol sketch, active remember/recall closures, Qdrant embedding storage path, recall keys, and token-bounded retrieval.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/db/vector_db.clj`, `qdrant.clj`, and `cache.clj`: vector database protocol, Qdrant collection/write/search implementation, and in-memory LLM result cache.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/nlp/splitter.clj`, `similarity.clj`, and `src/bosquet/read/document.clj`: token/character/sentence chunking, lexical similarity helpers, and Apache Tika document parsing.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/agent/graph.clj`, `react.clj`, `tool.clj`, `agent_mind_reader.clj`, and `wikipedia.clj`: graph-agent macros, interrupt/resume path, ReAct prototype, tool protocol, action parsing, and Wikipedia tool.
- `/tmp/myagents-research/zmedelis-bosquet/src/bosquet/mcp/client.clj`, `core.clj`, `stdio_transport.clj`, `tools.clj`, and `transport.clj`: stdio MCP process management, initialize/list/call/shutdown path, dynamic tool interning, and transport protocol.
- `/tmp/myagents-research/zmedelis-bosquet/resources/prompt-palette/agent/react.edn` and related prompt palette EDN files: declarative prompt packs and ReAct few-shot memory examples.
- `/tmp/myagents-research/zmedelis-bosquet/notebook/index.clj`, `user_guide.clj`, `memory_prosocial_dialog.clj`, `named_entity_processing.clj`, `text_splitting.clj`, `document_loading.clj`, and `observability.clj`: source documentation for configuration, prompt composition, memory-backed RAG, dynamic few-shot memory, chunking, document parsing, and proxy observability.
- `/tmp/myagents-research/zmedelis-bosquet/test/bosquet/memory/*.clj`, `test/bosquet/llm/generator_test.clj`, `resilience_test.clj`, `tools_test.clj`, `openai_tokens_test.clj`, `schema_test.clj`, `test/bosquet/template/*.clj`, `test/bosquet/nlp/splitter_test.clj`, and `test/bosquet/agent/*.clj`: deterministic coverage for memory helpers, prompt graph behavior, resilience, tools, tokenization, template parsing, splitting, and agent parsing.

## Excluded Paths

- `/tmp/myagents-research/zmedelis-bosquet/.git/`: VCS internals; exact reviewed commit is recorded above.
- `/tmp/myagents-research/zmedelis-bosquet/docs/`: generated Nextjournal Clerk HTML and static assets. I reviewed the source notebooks instead because they define the documentation content and executable examples.
- `/tmp/myagents-research/zmedelis-bosquet/docs/_data/*.png` and `/tmp/myagents-research/zmedelis-bosquet/notebook/assets/*.png`: generated or illustrative images. They do not define memory storage, retrieval, prompt composition, or safety behavior.
- `/tmp/myagents-research/zmedelis-bosquet/demo/*.edn`: small prompt/data demos were sampled through README and generator tests; they do not add memory architecture beyond prompt composition examples.
- `/tmp/myagents-research/zmedelis-bosquet/dev/`, `.github/`, `build.clj`, release/package metadata, and editor config files: reviewed only for build and task implications where relevant; they do not change the memory execution path.
- Generated build caches, local `config.edn`, local `secrets.edn`, local datasets, model downloads, Qdrant runtime storage, target directories, and Clerk caches were excluded because they are local/generated artifacts and not source design.
- Broad paper/example notebooks unrelated to memory execution, such as chain-of-density, chain-of-verification, writing letters, and math code generation, were not deep-read after confirming the relevant prompt-composition mechanisms are covered by `generator.clj`, prompt tests, and the memory/NER notebooks.
