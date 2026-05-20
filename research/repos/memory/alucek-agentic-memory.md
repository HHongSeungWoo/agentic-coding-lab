# ALucek/agentic-memory

- URL: https://github.com/ALucek/agentic-memory
- Category: memory
- Stars snapshot: 532 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: 03eb349dd06f050e4e21bf51d4adace8fbb65524
- Reviewed at: 2026-05-19 (Asia/Seoul)
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful conceptual notebook for mapping CoALA-style working, episodic, semantic, and procedural memory into a simple agent loop. It is not production-ready memory infrastructure: the repo is notebook-only, has no tests or packaging, stores raw conversations, uses anonymous persistent Weaviate, and lets an LLM rewrite procedural instructions without validation.

## Why It Matters

`ALucek/agentic-memory` is valuable because it compresses the CoALA cognitive-architecture taxonomy into an executable toy agent. The repo shows how a simple chatbot can combine current messages, recalled prior episodes, retrieved knowledge chunks, and a mutable instruction file in one prompt-building path.

For Agentic Coding Lab, the strongest value is the memory separation. It makes the difference between active run context, experience memory, factual/reference memory, and behavior/procedure memory easy to reason about. The repo is best treated as a design sketch for memory roles and update timing, not as a library or storage layer to adopt.

## What It Is

The repo contains a README, a primary Jupyter notebook, a LangGraph port notebook, a Docker Compose file for Weaviate plus Ollama, two text files holding procedural memory, the CoALA paper PDF, and media diagrams. There is no installable package, API server, command-line tool, requirements file, license file, or test suite.

The main notebook builds memory in stages:

- Working memory is a Python `messages` list passed to `ChatOpenAI`.
- Episodic memory is a Weaviate collection of raw conversations plus LLM-generated reflection fields.
- Semantic memory is a Weaviate collection of chunks from `CoALA_Paper.pdf`.
- Procedural memory is a local text file inserted into the system prompt and rewritten by the LLM at conversation exit.

The LangGraph notebook ports the same flow into `StateGraph` nodes for initial state population, LLM response generation, next-user-turn handling, end detection, and memory update.

## Research Themes

- Token efficiency: Weak but directionally useful. Episodic prompt construction limits prior conversations to three, and semantic context is retrieved on demand, but working memory grows unbounded and semantic recall injects up to 15 chunks without budgeting.
- Context control: Moderate as a teaching pattern. The repo separates working, episodic, semantic, and procedural inputs, but all recalled text is spliced directly into prompts with little normalization or trust boundary control.
- Sub-agent / multi-agent: Not present. There are no agent identities, shared memory scopes, locks, permissions, or cross-agent protocols.
- Domain-specific workflow: Conditional. The semantic example is paper-discussion focused; for coding agents, the analogous move would be indexing repo docs, ADRs, build logs, or verified conventions.
- Error prevention: Weak. There is no empty retrieval handling, schema validation, prompt-injection defense, test suite, rollback for procedural rewrites, or privacy redaction.
- Self-learning / memory: Strong as a concept demo. The loop stores conversations, reflects them into `what_worked` and `what_to_avoid`, retrieves similar episodes later, and rewrites a behavior guideline file.
- Popular skills: None packaged. The practical reusable skill is the conceptual pattern: separate memory classes by purpose and update risk.

## Core Execution Path

The main notebook starts with a basic working-memory loop: create a system prompt, keep `messages` in memory, append each `HumanMessage`, invoke `ChatOpenAI(model="gpt-4o", temperature=0.7)`, print the response, and append the AI response.

Episodic memory adds a reflection chain. `format_conversation()` turns message objects into a role-prefixed transcript. A prompt asks the LLM to return JSON containing `context_tags`, `conversation_summary`, `what_worked`, and `what_to_avoid`. `add_episodic_memory()` stores the raw transcript and reflection fields in a Weaviate `episodic_memory` collection. `episodic_recall()` performs Weaviate hybrid retrieval with `alpha=0.5` and `limit=1`.

The episodic prompt path calls `episodic_recall(user_input)`, reads `memory.objects[0].properties`, appends the current matched transcript to an in-process `conversations` list, accumulates `what_worked` and `what_to_avoid` in sets, keeps up to three previous conversations, and rebuilds the first `SystemMessage` with the current match, previous conversations, and accumulated lessons.

Semantic memory loads `CoALA_Paper.pdf` with `PyPDFLoader`, combines pages into one string, chunks it with `RecursiveTokenChunker(chunk_size=800, chunk_overlap=0)`, inserts each chunk into a Weaviate `CoALA_Paper` collection, and retrieves up to 15 chunks with another hybrid query. `semantic_rag()` wraps those chunks in a `HumanMessage` that is inserted temporarily before the user's actual message.

Procedural memory extends the episodic system prompt by reading `procedural_memory.txt`. On `exit`, the loop stores the episode and calls `procedural_memory_update()`, which asks the LLM to merge existing takeaways with accumulated `what_worked` and `what_to_avoid`, then overwrites `procedural_memory.txt` with up to 10 behavior guidelines.

The LangGraph port makes the same lifecycle explicit. `populate_state()` reads the first user input, loads `langgraph/procedural_memory_lg.txt`, retrieves episodic and semantic memories, and returns initial state. `memory_agent()` invokes the LLM. `user_response()` strips the old system and semantic-context messages, reads the next input, rebuilds memory-enriched prompt state, or sets `end=True`. `update_memory()` persists the final conversation reflection to Weaviate and rewrites the LangGraph procedural memory file before ending the graph.

## Architecture

The architecture is a notebook-local agent loop, not a reusable module. The external services are OpenAI for chat/reflection, local Weaviate for vector/BM25 hybrid search, and Ollama's `nomic-embed-text` through Weaviate's `text2vec-ollama` module.

Storage has three layers:

- In-process lists and sets for active working memory, recalled conversations, and accumulated behavioral lessons.
- Weaviate collections for episodic transcripts/reflections and semantic paper chunks.
- Plain text files for procedural memory instructions.

The CoALA mapping is direct. Working memory is the current `messages` list. Episodic memory is prior conversation history plus reflection. Semantic memory is factual paper context. Procedural memory is both the fixed notebook code and the mutable guideline text. Learning actions happen only at conversation end: write a new episode and rewrite procedural text. Semantic memory is loaded from the paper but not updated from experience.

The LangGraph version adds a clearer control-flow architecture with typed state and graph nodes, but it keeps the same storage, retrieval, and prompt-construction assumptions.

## Design Choices

The repo chooses an educational, incremental notebook style. Each memory type is introduced separately, then composed into a final full-memory loop. This makes the conceptual layering easy to inspect.

Episodic storage preserves raw conversations and separate distilled lessons. That is useful because later prompts can include both evidence and compressed guidance, but it also means sensitive user facts are stored verbatim.

Retrieval is fixed and simple: one episodic match, up to three previous conversations, accumulated lesson sets, and 15 semantic chunks. There is no adaptive query rewriting, scoring explanation, conflict handling, or token budget allocator.

Procedural memory is treated as a mutable behavior file. This demonstrates the CoALA idea that agents can learn by changing procedures, but the implementation updates behavior by unreviewed LLM overwrite rather than by a validated patch, policy gate, or human approval.

The notebooks use `HumanMessage` for semantic context. That keeps the demo small, but for a coding agent it blurs the trust boundary between retrieved context and user instruction.

The Weaviate collection setup configures named vectors from `source_properties=["title"]`, while the inserted episodic and semantic objects do not define a `title` property. The notebook outputs show retrieval examples, but the checked-in schema/code mismatch is a practical warning for anyone copying the setup.

## Strengths

The four-memory taxonomy is concrete. A reader can see exactly where working, episodic, semantic, and procedural memory enter the prompt.

The end-of-conversation write path is a useful pattern. It avoids doing expensive reflection and procedural updates on every turn.

The episodic reflection schema is compact and practical. `conversation_summary`, `what_worked`, and `what_to_avoid` map well to future coding-agent run retrospectives.

The LangGraph port clarifies the control loop. Separating populate, respond, user-turn, conditional-end, and update nodes is a better basis for a real agent than the raw `while True` loops.

The repo explicitly connects notebook mechanics to CoALA concepts: memory modules, retrieval, learning, and decision-making. That makes it good source material for internal memory-design docs.

## Weaknesses

The repo is not packaged or tested. There are no unit tests, dependency manifests, CI files, scripts, or reusable Python modules.

The memory stores have weak privacy posture. Weaviate anonymous access is enabled, data persists in a Docker volume, raw conversations are stored, and there is no retention, deletion, redaction, consent, or secret-filtering policy.

Prompt-injection risk is high. Raw prior conversations, recalled chunks, and mutable procedural text are inserted into prompts without escaping, provenance labels with authority levels, or instruction hierarchy enforcement.

Procedural self-modification is unsafe as implemented. An LLM can overwrite the entire guideline file from noisy or adversarial feedback, with no schema validation, review step, diff, version history, rollback, or tests.

Retrieval paths assume success. Code reads `memory.objects[0]` without empty-result handling and does not guard collection creation, duplicate collections, Weaviate connection failure, embedding failure, or malformed reflection JSON beyond `JsonOutputParser`.

Token control is shallow. Current conversation history grows, semantic context can be large, and retrieved raw transcripts can dominate the system prompt.

The Weaviate named-vector configuration appears inconsistent with inserted properties. Both episodic and semantic collections define vectors from `title`, but inserted records contain fields like `conversation` or `chunk`.

The examples remember personal facts such as a user's name, favorite food, and dislike of emojis. That is useful for demonstration, but it highlights why coding-agent memory needs explicit classification before storage.

## Ideas To Steal

Use four memory lanes for coding agents: working memory for current task state, episodic memory for prior runs and outcomes, semantic memory for repo/docs/reference facts, and procedural memory for reviewed operating rules.

Store episodic memory as both transcript pointer/provenance and distilled lessons. For coding agents, the distilled fields should be closer to `task_summary`, `verified_fix`, `failed_approach`, `commands_used`, and `evidence`.

Do memory learning at natural boundaries such as task completion, test pass/fail, PR review, or user correction. Boundary updates are easier to audit than turn-by-turn learning.

Keep procedural memory small and separately governed. Let the LLM propose procedural changes, but require schema validation, diff review, tests, and possibly user approval before adoption.

Model memory in explicit graph state. The LangGraph state fields are a useful sketch for an Agentic Coding Lab state object: messages, semantic context, procedural rules, prior episodes, positive/negative lessons, and end/update status.

Separate semantic RAG from durable episodic learning. Repo docs and facts should be refreshed from source material; user/project experience should be written through a different policy.

Use `what_worked` and `what_to_avoid` as retrieval payloads for future planning, but attach evidence and timestamps so stale lessons can be retired.

## Do Not Copy

Do not let an LLM directly overwrite procedural rules from raw conversation feedback. Procedural memory is high-authority and needs review, validation, and rollback.

Do not inject raw recalled conversations into the system prompt as authoritative instruction. Treat them as evidence with lower authority than current user instructions and project policy.

Do not store personal or project-sensitive facts by default. Coding-agent memory needs allowlists for durable conventions and blocklists for secrets, credentials, raw logs, private source snippets, and speculative conclusions.

Do not use anonymous persistent Weaviate for multi-user or sensitive memory. Add auth, network scoping, backups, retention, and deletion paths.

Do not rely on fixed top-1 episodic retrieval and fixed 15-chunk semantic retrieval. Coding tasks need score thresholds, fallback behavior, filters by repo/branch/run, and a token budget.

Do not copy the collection schema without correcting vector source properties and adding migration/tests.

Do not treat notebook outputs as verification. The repo needs deterministic tests around reflection parsing, retrieval misses, prompt construction, and procedural update safety.

## Fit For Agentic Coding Lab

Fit is conditional. The repo belongs in `memory` because it directly demonstrates agent memory architecture, but it is a tutorial notebook rather than a mature memory subsystem.

The best use is as a teaching reference and pattern source. Agentic Coding Lab should borrow the memory taxonomy, end-of-run reflection, explicit LangGraph state shape, and separation between semantic knowledge and episodic experience. It should not borrow the storage/privacy defaults or procedural overwrite path.

A production coding-agent version would need scoped memory IDs for user, repo, branch, agent, and run; redaction before storage; source-linked provenance; retrieval thresholds; token budgeting; conflict and staleness handling; reviewed procedural-rule changes; and regression tests proving memory improves coding behavior without leaking cross-project context.

## Reviewed Paths

- `/tmp/myagents-research/alucek-agentic-memory/README.md`: project framing and four memory definitions.
- `/tmp/myagents-research/alucek-agentic-memory/agentic_memory.ipynb`: primary execution path for working, episodic, semantic, and procedural memory.
- `/tmp/myagents-research/alucek-agentic-memory/langgraph/agentic_memory_langgraph.ipynb`: graph-based port of the same memory loop.
- `/tmp/myagents-research/alucek-agentic-memory/procedural_memory.txt`: mutable behavior guideline store for the main notebook.
- `/tmp/myagents-research/alucek-agentic-memory/langgraph/procedural_memory_lg.txt`: mutable behavior guideline store for the LangGraph notebook.
- `/tmp/myagents-research/alucek-agentic-memory/docker-compose.yml`: Weaviate/Ollama storage and embedding service setup.
- `/tmp/myagents-research/alucek-agentic-memory/CoALA_Paper.pdf`: cognitive architecture source context, especially memory, action-space, learning, and decision-making sections.
- Notebook embedded outputs in `agentic_memory.ipynb` and `langgraph/agentic_memory_langgraph.ipynb`: sample conversations and generated prompt/context state used as execution evidence.

## Excluded Paths

- `/tmp/myagents-research/alucek-agentic-memory/.git/`: VCS internals; exact reviewed commit captured separately.
- `/tmp/myagents-research/alucek-agentic-memory/media/`: binary image and diagram assets used for notebook presentation; helpful for visual explanation but not execution logic.
- Rendered notebook display images such as LangGraph Mermaid PNG output: generated visualization artifacts; graph source cells were reviewed instead.
- Remaining PDF references, bibliography pages, and broad survey details outside the CoALA architecture/actionable-design sections: useful academic context but not part of the repo's memory execution path.
- No vendored dependency directories, generated source trees, binary model weights, UI implementation, package build artifacts, or test fixtures were present in the reviewed checkout.
