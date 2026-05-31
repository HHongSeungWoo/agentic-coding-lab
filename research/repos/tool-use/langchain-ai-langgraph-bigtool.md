# langchain-ai/langgraph-bigtool

- URL: https://github.com/langchain-ai/langgraph-bigtool
- Category: tool-use
- Stars snapshot: 540 (GitHub REST API repository endpoint, captured 2026-05-31; matches index snapshot 540 captured 2026-05-29)
- Reviewed commit: 616a8ad005f8e50af60f56ae7d6c77944d7a402d
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong small reference for runtime tool retrieval in LangGraph: keep only a retrieval tool in the initial model context, search a LangGraph Store for relevant tool IDs, then bind only selected tool schemas on later model calls. The key idea transfers directly to agent skill routing, but it is not a complete 10,000-skill solution by itself because the executable registry is still loaded up front, selected tools accumulate without pruning, and execution is not hard-constrained to retrieved tools.

## Why It Matters

`langgraph-bigtool` is one of the clearest open-source implementations of runtime tool shortlisting inside an agent graph. It targets the same failure mode as large skill libraries: once an agent has hundreds or thousands of capabilities, putting every schema or instruction in the prompt wastes tokens and makes selection worse.

The repository matters for Agentic Coding Lab because it shows a concrete host-mediated pattern rather than a catalog pattern. The model initially sees only `retrieve_tools`. It asks for relevant tools by query. The host searches a persistent store and maps result IDs back to real tool objects. The next model turn sees only the retrieval tool plus the selected schemas. That is the runtime shape needed for scaling from dozens of skills to a large skill corpus.

The review also exposes the boundary we should not miss. The library reduces model context but does not implement governance, lazy skill loading, permission checks, ranking evaluation, query rewriting, or a hard execution gate. It is a good graph skeleton, not a full skill router.

## What It Is

This is a compact Python package published as `langgraph-bigtool` with one public API, `create_agent`. It depends on `langgraph>=0.3.0` and uses standard LangChain tool objects. The repository contains:

- `langgraph_bigtool/graph.py`: the LangGraph state graph, model-call node, retrieval-selection node, tool-execution node, and routing condition.
- `langgraph_bigtool/tools.py`: default sync/async retrieval functions backed by `BaseStore.search` / `BaseStore.asearch`, plus helper code for detecting `InjectedStore`.
- `langgraph_bigtool/utils.py`: helper for converting Python positional-only functions, used by the math demo and tests.
- `README.md`: quickstart indexing Python `math` functions into an `InMemoryStore`, customization examples, and related tool-retrieval papers.
- `tests/unit_tests/test_end_to_end.py`: fake-model end-to-end tests for default retrieval, custom retrieval, duplicate tool IDs, async retrieval, and raw callables in the registry.
- `tests/integration_tests/test_end_to_end.py`: OpenAI-backed integration test that reuses the unit test flow.

The package does not provide a tool registry service, skill marketplace, ingestion CLI, ranking benchmark, or vector database wrapper. Users supply the executable registry and the LangGraph store entries themselves.

## Research Themes

- Token efficiency: Strong for model-facing tool schemas. Initial calls bind only `retrieve_tools`; subsequent calls bind `retrieve_tools` plus `selected_tool_ids`. It avoids sending the full tool set to the model. Token pressure can still grow because selected tools are accumulated for the whole graph state and never pruned.
- Context control: Strong skeleton, incomplete policy. `limit`, `filter`, and `namespace_prefix` constrain store retrieval, and custom retrievers can implement arbitrary routing. There is no built-in context budget, TTL, sliding top-k, confidence threshold, or forced reset between tasks.
- Sub-agent / multi-agent: Low. The graph is a single-agent ReAct-like loop. LangGraph could host multiple such agents, but this repo does not implement delegation, role-specific registries, or per-agent permission boundaries.
- Domain-specific workflow: Moderate. The README shows generic math tools and category-based retrieval. The design can support domain namespaces and metadata filters, but the repo has no coding-specific skill model, file-glob routing, project detection, or workflow packs.
- Error prevention: Moderate. The model is not exposed to every tool schema, duplicate selected tool IDs are deduped, and injected store arguments stay host-side. Gaps are significant: invalid retrieved IDs raise errors, registry/store drift is not validated, and `ToolNode` is initialized with every registered tool so execution is not hard-gated by retrieval.
- Self-learning / memory: Low to moderate. It uses LangGraph Store, including memory-store semantics and possible persistent backends, but it does not learn from tool-call outcomes, update rankings, record activation telemetry, or prune bad skills.
- Popular skills: Runtime tool retrieval, semantic search over tool descriptions, stateful selected-tool accumulation, custom retrieval functions, store injection, vector-store-backed progressive disclosure, LangGraph conditional routing, sync/async graph execution.

## Core Execution Path

The user builds two separate structures. First, `tool_registry` maps stable string IDs to executable `BaseTool` instances or callables. Second, the user writes searchable metadata into a LangGraph `BaseStore` under a namespace such as `("tools",)`, using the same IDs as keys. In the README example, each store value contains a `description` field built from `tool.name` and `tool.description`; the `InMemoryStore` index embeds that field with OpenAI embeddings.

`create_agent(llm, tool_registry, ...)` creates a LangGraph `StateGraph`. If no custom retrieval function is passed, `get_default_retrieval_tool` builds sync and async functions named `retrieve_tools`. These accept a model-supplied `query` and an injected `BaseStore`, call `store.search(namespace_prefix, query=query, limit=limit, filter=filter)`, and return the result keys as tool IDs.

The graph state extends `MessagesState` with `selected_tool_ids`. The reducer `_add_new` appends newly selected IDs while preserving earlier IDs and removing duplicates. This means selected tools are monotonic for the current graph run.

The `agent` node computes `selected_tools = [tool_registry[id] for id in state["selected_tool_ids"]]`, binds `[retrieve_tools, *selected_tools]` to the language model, and invokes the model with the message history. On the first turn, `selected_tool_ids` is empty, so the only available tool schema is `retrieve_tools`.

The conditional edge inspects the last `AIMessage`. If there are no tool calls, the graph ends. If a tool call name matches `retrieve_tools.name`, it sends that call to the `select_tools` node. Any other tool call is sent to the `tools` node.

The `select_tools` node executes the retrieval function for each retrieval call, injecting the store argument when the retriever schema requests `InjectedStore`. It formats a `ToolMessage` back to the model saying which tool names are now available, and it updates `selected_tool_ids` with the returned IDs. The graph then returns to the `agent` node, where those selected tool schemas are bound.

The `tools` node is a LangGraph `ToolNode` created from all values in `tool_registry`. It executes non-retrieval tool calls and returns their tool messages, after which the graph loops back to the agent. The README trace demonstrates the intended path: model calls `retrieve_tools` with "arc cosine calculation", selection returns `cos` and `acos`, the next model call invokes `acos`, and the final model message summarizes the result.

## Architecture

The architecture is intentionally two-plane:

- Search plane: LangGraph `BaseStore` holds searchable tool metadata under configurable namespaces. The default retriever uses semantic search if the store has an embedding index, but any retrieval implementation can be supplied.
- Execution plane: an in-process Python `tool_registry` holds the real callable objects. Store results return IDs, and those IDs are used to select objects from this registry.
- Agent graph: a LangGraph `StateGraph` coordinates model calls, retrieval calls, and tool execution. The only persistent extra state is `selected_tool_ids`.
- Model context plane: `llm.bind_tools` receives the retrieval tool plus the current selected tool objects. This is where prompt/tool-schema pressure is reduced.

The graph has three nodes: `agent`, `select_tools`, and `tools`. `agent` binds tools and calls the model. `select_tools` runs retrieval and updates state. `tools` executes selected model tool calls through `ToolNode`.

The default retriever supports `namespace_prefix`, `limit`, and `filter`. This gives a simple path for partitioning a large catalog by tenant, project, domain, risk class, or language before vector search. The README also shows an alternative categorical retriever with a `Literal["billing", "service"]` argument, demonstrating that retrieval does not have to be semantic search.

Sync and async are both first-class. `create_agent` wires a `RunnableCallable` when both sync and async retrieval functions exist, or a single function when only one is supplied. Tests cover both paths.

## Design Choices

The most important design choice is making retrieval itself a tool. The model is not given a hidden router result; it decides when it needs more capabilities and supplies the query. This keeps the loop natural for ReAct agents and lets the model refine retrieval over multiple turns.

Tool IDs are separated from tool names. Store keys are opaque IDs while model-visible names come from `BaseTool.name` or callable `__name__`. This is useful for skill systems because a skill can have a stable ID even if its displayed title or trigger text changes.

The store is injected into the retriever instead of exposed to the model. `InjectedStore` lets retrieval access LangGraph persistence without putting store handles or operational arguments in the tool schema.

The retrieval result is stateful and cumulative. Once a tool is selected, it remains bound in later model calls during the graph run. This helps multi-step tasks where the same tool is needed repeatedly, and the duplicate reducer prevents repeated retrieval from creating duplicate schemas.

The library leaves ingestion out of scope. Users decide which metadata fields to embed, how to name namespaces, which vector store backend to use, and how to keep `tool_registry` synchronized with store entries. This keeps the package small but shifts correctness to the host application.

The default `limit` is 2. That is a useful demonstration default because it makes the context savings obvious, but production systems need task-sensitive top-k, reranking, confidence thresholds, and fallbacks.

## Strengths

The implementation is small enough to audit and adapt. The core graph logic is under 200 lines and directly shows where context is assembled.

It solves the right runtime problem: do not bind every tool schema to the model up front. Even if the process has thousands of tools, the model sees a short retrieval interface first.

It uses LangGraph Store instead of inventing a storage abstraction. That gives immediate access to in-memory and persistent backends, semantic search, namespaces, filters, and injected store arguments.

Custom retrieval is clean. A host can replace semantic description search with BM25, hybrid search, graph traversal, policy filters, category routing, learned retrievers, telemetry-aware ranking, or a skill-specific router while reusing the graph pattern.

The graph separates retrieval messages from execution messages. The model receives an explicit tool result listing available tool names before it calls one of them, which makes the progressive disclosure loop inspectable.

Tests cover the intended end-to-end behavior with a fake model, deterministic embeddings, sync/async retrieval, custom retrievers with and without injected store, duplicate retrieval, and callable registries. This is enough to validate the skeleton without requiring an external LLM for unit tests.

The pattern maps well to agent skills. A skill library can keep a compact searchable index in the store, retrieve a few relevant skill IDs, then load only those skill instructions or wrapper tools into the next model call.

## Weaknesses

Execution is not hard-constrained to retrieved tools. `ToolNode` is constructed from every value in `tool_registry`, and the conditional edge sends any non-`retrieve_tools` call to that node. Normal model APIs should only emit calls for schemas that were bound, but a malformed, replayed, or adversarial state containing another registered tool name can still reach an executor that knows every tool. For skill routing, this must be fixed with an execution guard or a `ToolNode` built from selected tools only.

Selected tools accumulate without a budget. `_add_new` dedupes IDs but never removes stale ones. Long tasks, broad exploratory turns, or repeated failed retrieval can gradually reintroduce context pressure.

The default retrieval quality is only as good as one embedded metadata field. The README indexes `"description"` and the code does not define a richer schema. Large skill routing needs titles, triggers, negative triggers, domains, file globs, required tools, risks, permissions, recency, maturity, and usage telemetry.

There is no ingestion or validation pipeline. The library does not check that every store key exists in `tool_registry`, every registry entry has indexed metadata, tool names are unique, schemas fit provider limits, or descriptions are safe for prompt exposure.

The executable registry is not lazy. `create_agent` receives the full `tool_registry` and builds a `ToolNode` over all tools. This avoids model-context blowup but not process-memory, import-time, or permission-surface blowup.

The model must know to ask for retrieval. If it fails to call `retrieve_tools`, asks a vague query, or stops after an incomplete shortlist, the graph has no automatic fallback, query expansion, reranking, or self-check.

There are no large-scale benchmarks in the repo. The README demo uses roughly 50 Python math functions and explicitly notes that some LLMs can handle that number directly. The package claim covers hundreds or thousands of tools, but tests do not measure retrieval quality, latency, cost, context size, or degradation at those scales.

Security and governance are out of scope. There is no provenance, trust label, permission model, approval gate, sandbox, audit log, side-effect classification, or per-agent allowlist in this repo.

## Ideas To Steal

Use a bootstrap router tool as the only always-visible capability. For skills, that could be `search_skills(query, task_context, max_results)` or `retrieve_skills(query)`.

Separate searchable metadata from executable or instructional payloads. Keep compact skill index entries in a vector/hybrid store and load full `SKILL.md`, examples, scripts, or tools only after selection.

Use stable IDs as the join key between the index and the runtime registry. IDs should survive display-name edits and should be validated before a selection can affect model context or execution.

Make retrieval state explicit. A `selected_skill_ids` field in graph/session state is easier to audit, test, prune, and log than hidden prompt concatenation.

Use namespace and filter fields as deterministic prefilters before semantic ranking. Project, host, repo language, file glob, user-enabled pack, permission class, and risk level should narrow the candidate set before embeddings are consulted.

Support custom retrievers behind the same graph interface. Start with vector search, but leave room for hybrid sparse+dense search, category routers, learned rerankers, activation telemetry, and explicit user-pinned skills.

Return a short human-readable selection message after retrieval. It gives the model confirmation of what is now available and gives logs a useful audit point.

Keep sync and async retrieval paths symmetrical. Skill loading may hit disk, network registries, or embeddings services, so async support matters.

## Do Not Copy

Do not let the executor know all tools while claiming retrieval is a permission boundary. Context gating and execution authorization must be separate, and execution should reject tool or skill IDs that were not selected and authorized.

Do not make selected skills monotonic without pruning. Add a context budget, recency window, task-bound reset, or replace-not-append mode.

Do not rely on description-only vector search for large skill libraries. Skill routing needs structured metadata, negative examples, deterministic filters, and evaluation data.

Do not load every skill implementation into memory just to avoid loading every schema into the model. For 10,000 skills, use a lazy registry or loader that resolves selected IDs on demand.

Do not infer 10,000-skill scalability from the math demo. The demo proves the control loop, not retrieval quality or operational scale.

Do not trust model-generated retrieval queries as the only routing signal. Combine model queries with host-observed context such as current files, command intent, repo language, active task, and enabled skill packs.

Do not omit registry/index consistency checks. A missing ID from retrieval currently becomes a runtime `KeyError`; a production skill router should fail closed with a useful diagnostic.

## Fit For Agentic Coding Lab

Fit is strong as a runtime-skill-routing reference. This repo is closer to the user's target problem than marketplace and installer repos because it addresses the live session question: how does an agent avoid seeing every tool while still gaining access to relevant ones?

For Agentic Coding Lab, the best adaptation is a graph with `search_skills` always visible, `selected_skill_ids` in state, and a lazy loader that turns selected IDs into either model instructions or callable wrappers. The search index should be compact and structured: title, one-line purpose, trigger phrases, "do not use when" text, domains, file globs, required tools, risk class, host compatibility, dependency cost, last-reviewed timestamp, and usage score.

The Lab should strengthen the pattern with hard gates. A selected skill should be authorized before it can be loaded, and a callable skill should be executable only if its ID is both retrieved for the task and allowed by project policy. If a skill has side effects, the gate should require risk-specific approval or sandboxing.

The Lab should also add lifecycle controls missing here: top-k budgets, stale-skill eviction, session reset, retrieval telemetry, failed-selection feedback, offline evaluation sets, and consistency validation between `skills.index.json`, installed files, and runtime loaders.

This repo should not be treated as a complete product architecture. It is a clean LangGraph control-loop seed that needs a real registry, governance model, ranking layer, and context budget around it.

## Reviewed Paths

- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/README.md`: Product positioning, quickstart, math-tool example, store indexing flow, retrieval trace, customization hooks, category retriever example, and related work.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/pyproject.toml`: Package metadata, dependency floor, test dependency groups, pytest configuration, ruff settings, and Python version.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/langgraph_bigtool/graph.py`: Core `create_agent` implementation, `State`, selected-tool reducer, model binding, `ToolNode`, retrieval selection nodes, conditional edges, and sync/async graph wiring.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/langgraph_bigtool/tools.py`: Default retrieval functions, `store.search` / `store.asearch` behavior, namespace/filter/limit handling, and `InjectedStore` argument detection.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/langgraph_bigtool/utils.py`: Positional-only function conversion used by the README and tests to turn Python math builtins into tools.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/langgraph_bigtool/__init__.py`: Public package export confirming `create_agent` is the intended API surface.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/tests/unit_tests/test_end_to_end.py`: Fake-model end-to-end tests for retrieval, selected tool execution, duplicate selected IDs, custom retrieval failures, async execution, injected store variants, and raw callable registries.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/tests/integration_tests/test_end_to_end.py`: OpenAI integration test shape and external dependency boundary.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/Makefile`: Test, integration-test, lint, and format commands; also confirmed the upstream test command expects `uv`.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/LICENSE`: MIT license.
- Git metadata and GitHub REST repository endpoint: reviewed commit, commit date, default branch, repository timestamps, license, forks, open issues, and star snapshot.

## Excluded Paths

- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/.git/`: VCS storage. Used only through `git rev-parse`, `git show`, `git log`, and `git status` for provenance.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/uv.lock`: Generated dependency lockfile. Dependency intent was reviewed through `pyproject.toml`; the lockfile does not define routing behavior.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/static/img/graph.png`: Static image of the graph shown in the README. The actual graph behavior was reviewed from source.
- `/tmp/myagents-research/langchain-ai-langgraph-bigtool/tests/__init__.py`, `tests/unit_tests/__init__.py`, and `tests/integration_tests/__init__.py`: Empty package markers with no behavior.
- External LangGraph, LangChain, embedding model, and OpenAI implementations: Not vendored in this repo. Their APIs were considered only as used by `langgraph-bigtool`.
