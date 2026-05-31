# Pro-GenAI/Tool-SEE

- URL: https://github.com/Pro-GenAI/Tool-SEE
- Category: tool-use
- Stars snapshot: 7 (GitHub REST API repository endpoint, captured 2026-05-31; index row also recorded 7 captured 2026-05-29)
- Reviewed commit: 68419f3bac0f22048e4d6935d15338d9b202670f
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Directly relevant runtime skill-routing reference, but best treated as a small proof of concept rather than a production-grade 10,000-skill router. The useful idea is query-time top-k retrieval plus an always-available `search_tools` expansion tool, so the agent initially sees only a compact capability set and can ask for more. The current implementation is in-memory, exact cosine full-scan retrieval over name/description embeddings, with no durable schema registry, ANN index, permission filtering, execution policy, reranker, CI, or robust eval. It validates the architecture shape we want, but not the large-scale or safety claims by itself.

## Why It Matters

Tool-SEE targets the exact problem behind `runtime-skill-routing`: an agent should not receive every skill or tool description in its model context. It should receive a small, query-conditioned candidate set, then be able to ask for more capabilities during the run when the initial set is insufficient.

For Agentic Coding Lab, this is more relevant than marketplace-style skill repos because it sits in the runtime path. `ToolMemory.add_tools` indexes tool records, `select_tools_for_query` retrieves top-k candidates, and `run_agent` attaches only those selected tools plus a `search_tools` tool to a LangChain agent. That is the same control surface we need for "10,000 installed skills, 3-7 exposed now."

The repo is also useful because its gaps are clear. It shows where a minimal dense-retrieval router stops: it reduces prompt bloat, but it does not solve trust, permissions, duplicate skills, schema normalization, tool-call safety, or retrieval quality for ambiguous coding tasks.

## What It Is

Tool-SEE is a small Python package named `tool_see` with three main pieces:

- `ToolMemory`: an in-memory store from `tool_id` to metadata plus embedding.
- `select_tools_for_query`: a query helper that returns top-k metadata records with `_tool_id` and `_score`.
- `auto_tool_agent`: a LangChain agent demo that starts with initial retrieved tools and exposes `search_tools` so the model can retrieve more tools mid-run.

The repo also contains:

- `examples/test_flow.py`: a two-tool demo and latency smoke script.
- `benchmark_toolsee/benchmark.py`: MetaTool dataset benchmark for selection correctness, retrieval latency, and token savings.
- `benchmark_toolsee/ttft_comparison.py` and `api_server.py`: latency comparison scripts that contrast "all tool descriptions in prompt" against "five selected tools in prompt."
- README, assets, and a preprint/blog/project-page set that describe the intended architecture.

It is not a full tool platform. There is no database-backed registry, no OpenAPI/MCP import path, no hosted search service, no permission model, no persistent execution handles, and no general agent framework beyond the LangChain demonstration.

## Research Themes

- Token efficiency: Strong concept, narrow implementation. The model-facing tool set is bounded by `top_k`, and the README reports 95-96% token savings on MetaTool-style descriptions. The code does not count real provider tool schemas or full skill files, and retrieval compute still scales with catalog size.
- Context control: Strong first-order pattern. Initial prompt exposure is top-k selected tools plus `search_tools`; dynamic expansion can add more tools during the same LangChain run. Missing pieces are per-project enabled sets, negative routing constraints, duplicate/collision control, and context-budget accounting across multi-step runs.
- Sub-agent / multi-agent: Low. There is no subagent scheduler or per-agent profile, but the same `ToolMemory` interface could be scoped per agent or per task. The current demo has one global memory passed through LangChain runtime context.
- Domain-specific workflow: Low to moderate. The package is domain-agnostic and uses simple name/description metadata. It does not model coding-specific signals such as file globs, repo languages, risk labels, tool prerequisites, or workflow phases.
- Error prevention: Moderate for wrong-tool reduction, weak for safety. Retrieval narrows the action space, which can reduce accidental wrong calls. There is no deterministic execution gate, approval policy, trust provenance, secret handling, sandboxing, or audit log.
- Self-learning / memory: Low. `ToolMemory` stores embeddings and can save/load JSON, but there is no activation telemetry, feedback learning, failed-route repair, or pruning.
- Popular skills: Runtime top-k tool retrieval, dense embedding search, dynamic `search_tools` expansion, in-memory vector store, LangChain tool injection middleware, MetaTool selection evaluation, and TTFT/token-savings measurement.

## Core Execution Path

Tool ingestion starts with a list of `(tool_id, metadata)` tuples. Each metadata dict is expected to contain at least `name` and `description`; executable use also needs a Python `function` callable. `ToolMemory.add_tools` builds text from `name` and `description` by default, or from caller-provided `text_keys`, sends those texts to the configured embedding provider, and stores the resulting vector plus the original metadata in `self._store`.

Query-time retrieval goes through `select_tools_for_query(query, tool_memory, top_k=5, score_threshold=None)`. It calls `ToolMemory.query`, which embeds the query, computes cosine similarity against every stored embedding in Python, sorts all scores descending, and returns the first `top_k`. `select_tools_for_query` then copies metadata, adds `_tool_id` and `_score`, and optionally drops records below `score_threshold`.

Agent integration starts in `run_agent(prompt, tool_memory)`. The default tool list contains `search_tools`. The runner retrieves initial matches for the prompt, converts each selected metadata dict into a LangChain `BaseTool` via `create_tool`, and passes those tools into `langchain.agents.create_agent` with `RuntimeToolExpansionMiddleware`.

Dynamic expansion happens when the model invokes `search_tools(query)`. That tool retrieves another top 5 from `ToolMemory` with a hard-coded `score_threshold=0.35`, converts matching metadata records into LangChain tools, and mutates the running LangGraph `ToolNode` so the newly discovered tools become callable in later model/tool steps. The middleware refreshes the model request's tool list from the mutated `ToolNode` before each model call.

Execution is direct LangChain tool execution of the underlying Python callable. Tool-SEE does not broker execution through a permissioned service; selected tools are real callables attached to the agent.

## Architecture

The runtime architecture is a compact retrieval gate in front of an agent:

- Embedding provider: `tool_see/utils/llm_utils.py` defines a custom `OpenAIEmbeddings` wrapper around `openai.OpenAI().embeddings.create`, configured by `EMBED_API_KEY`, `EMBED_MODEL`, and `EMBED_API_BASE`.
- Tool memory: `tool_see/utils/tool_utils.py` stores metadata and embedding lists in a Python dict. Optional JSON persistence serializes the whole dict.
- Retriever: `tool_see/tool_searcher.py` is a thin wrapper around memory query and score-threshold filtering.
- Tool adapter: `create_tool` wraps metadata callables with LangChain's `@tool` decorator, using metadata `name` and `description`.
- Agent adapter: `tool_see/auto_tool_agent.py` uses LangChain `create_agent`, a `search_tools` tool, a runtime context containing `tool_memory` and `tool_node`, and middleware that refreshes the model-visible tools after dynamic registration.
- Evaluation scripts: `benchmark_toolsee` downloads MetaTool datasets, builds a `ToolMemory`, evaluates retrieved tool names with DeepEval `ToolCorrectnessMetric`, counts token deltas, and measures chat-completion latency with all descriptions versus five descriptions.

There is no separate search server, no vector database abstraction, no ANN implementation, and no canonical schema layer. The "index" is the process-local `_store` dict.

## Design Choices

Tool-SEE separates model context size from installed catalog size by exposing top-k results instead of the whole catalog. This is the central design choice worth keeping.

The system keeps the agent flexible by providing `search_tools` as a permanent bootstrap tool. That means the first retrieval does not need perfect recall if the model can formulate a better search query after reading the user task and seeing the initial candidates.

The ingestion format is deliberately simple: a tuple id plus free-form metadata dict. This makes demos easy but shifts schema discipline to the caller. The default retrieval text only includes `name` and `description`; richer metadata such as tags, examples, input schema, output schema, risk, ownership, and host constraints are not parsed unless the caller passes custom `text_keys`.

Retrieval is exact cosine search in Python. This avoids vector DB setup and is enough for small demos, but it does not match the paper's broader discussion of FAISS/HNSW/external vector stores as supported deployment options.

The LangChain integration mutates LangGraph `ToolNode` internals (`_tools_by_name`, `_tool_to_state_args`, `_tool_to_store_arg`, `_tool_to_runtime_arg`) to register tools mid-run. This is pragmatic and shows dynamic exposure can work, but it is version-sensitive because it relies on private implementation details.

The benchmark evaluates selection as candidate recall/correctness, not complete task success. Retrieved tool names are compared to labeled expected tool names; the model is not asked to solve the downstream task with retrieved tools in the main benchmark.

## Strengths

The repo implements the runtime routing loop directly. Unlike catalog/marketplace repos, it shows how a model can start with only a small candidate set and discover more tools while running.

The code surface is small and easy to audit. The whole retrieval path is readable in `ToolMemory.query` and `select_tools_for_query`, making the tradeoffs obvious.

`search_tools` is the right primitive for large skill sets. It turns the skill catalog into a callable retrieval affordance instead of trying to fit all descriptions into the system prompt.

Initial top-k exposure plus dynamic expansion is a good interaction model for coding agents. The agent can start with likely tools, then search for a narrower capability after it has inspected files, errors, or test output.

The evaluation scripts measure the right categories at a high level: selection accuracy, retrieval latency, token footprint, and TTFT. Even if the current methodology is preliminary, these are the metrics a production router should track.

The implementation is provider-flexible for embeddings because it uses an OpenAI-compatible client and `EMBED_API_BASE`. This can point at local embedding servers as shown in `.env.example`.

## Weaknesses

The retrieval index is a full Python scan over every stored embedding. The model context can remain O(top-k), but query-time compute is O(number of tools * embedding dimension), not O(1). This is fine for a small MetaTool catalog, but it does not demonstrate 10,000+ or 80,000+ skill-scale routing.

The paper and README discuss structured metadata, tags, input/output schemas, metadata filters, optional reranking, FAISS/HNSW, and external vector stores. The current code implements only name/description embedding, cosine sorting, optional score threshold, and in-memory storage.

Persistence is not production-ready. `ToolMemory.save` JSON-dumps the entire `_store`, but normal metadata contains Python callables under `function`, which are not JSON serializable. If metadata is persisted without callables, `create_tool` cannot reconstruct executable tools after load.

There is no execution gating. A retrieved callable is attached to the LangChain agent and can run. The router has no permission checks, risk labels, approval requirements, read/write distinction, tenant scoping, provenance validation, or audit envelope.

There is no schema normalization. Tool metadata is arbitrary dict data. The package does not ingest OpenAPI, MCP tool schemas, LangChain tools, Copilot/Claude skills, or JSON Schema definitions into a canonical searchable record.

The dynamic tool registration path depends on LangGraph private fields. A LangChain/LangGraph upgrade could break `_tools_by_name` mutation or runtime arg maps without a type-level compatibility guard.

The score threshold check uses truthiness (`if score_threshold and score < score_threshold`), so `0.0` is treated as "no threshold." That is minor, but it shows the filtering layer is basic.

The benchmark has methodology gaps. It evaluates selected names against labels, not actual agent success; it does not compare against an LLM given all tools and asked to choose; it provides no confidence intervals; and token counting uses stringified Python dicts rather than exact provider tool schemas.

The benchmark has implementation issues. `benchmark.py` downloads datasets into `Path(__file__).parent.parent.parent / "eval_datasets"`, which is a sibling of the repo when run from this checkout, while `ttft_comparison.py` expects `eval_datasets` under the repo root. The lambda in the MetaTool loop captures the loop variable, so all generated callables would call the final tool name if executed.

The chat model `OPENAI_API_BASE` in `.env.example` is not wired into `ChatOpenAI`; the `base_url` line is commented out. Embeddings can use a local OpenAI-compatible endpoint, but chat completions may not.

There are no tests or CI. I could compile the Python files, but running the package demos or benchmarks requires installing dependencies and configuring embedding/chat API keys.

## Ideas To Steal

Use a two-stage runtime router: deterministic/embedding search over a compact skill index first, then expose only top-k skill/tool definitions to the model.

Always include a small `search_skills` or `search_tools` capability so the model can recover from a weak initial shortlist by issuing a refined query during execution.

Separate "retrieved but not exposed" from "model-visible and executable." A production version should retrieve candidates, apply policy, then expose only approved schemas.

Track `_score` and `_tool_id` beside returned metadata. These fields are essential for telemetry, debugging, route-quality evaluation, and automatic pruning.

Benchmark routers on four axes: top-k recall/correctness, selection latency, prompt-token savings, and downstream task success. Tool-SEE covers the first three directionally; Agentic Coding Lab should add the fourth.

Make initial top-k conservative but expandable. For coding, start with maybe 3-7 skills, then let the agent search again after observing repository language, test failures, framework, or user intent.

Treat tool descriptions as retrievable documents. The same pattern can apply to skill `description`, `when_to_use`, file globs, host compatibility, tool requirements, examples, and known failure modes.

Use a local in-memory exact scan as the development baseline. It is easy to test and reason about before replacing storage with SQLite-vec, FAISS, HNSW, pgvector, or another ANN layer.

## Do Not Copy

Do not claim context-size O(1) as whole-system O(1). Top-k prompt exposure is bounded, but retrieval, indexing, memory footprint, and policy checks still scale with catalog size unless the index is engineered for it.

Do not rely on name/description embeddings alone for coding skills. Real routing needs task type, language/framework, file globs, current repo signals, tool dependencies, risk class, examples, and negative triggers.

Do not attach retrieved tools directly to an agent without a policy pass. Retrieval relevance is not authorization.

Do not persist tool metadata that contains raw Python callables as JSON. Store executable references separately from searchable metadata.

Do not mutate private framework internals as the only dynamic-registration mechanism in a durable product. If this pattern is needed, wrap it in compatibility tests and isolate the adapter.

Do not benchmark only candidate recall and call it end-to-end tool-use reliability. A router can retrieve the right tool while the agent still misuses it, skips it, or supplies bad arguments.

Do not use random selected tools for TTFT claims when evaluating task-conditioned retrieval. TTFT should be measured with the actual top-k selected for each task and with provider-native tool schemas.

## Fit For Agentic Coding Lab

Fit is high as a conceptual runtime-router seed and moderate as reusable code. The repo confirms the basic architecture for large skill sets: keep a compact searchable index, retrieve top-k by query, expose a small shortlist, and provide an in-session search tool for dynamic expansion.

For Agentic Coding Lab, the production version should be stricter:

- Build a canonical `skills.index.json` or database table with routing text, host, category, globs, risk, permissions, maturity, source, reviewed commit, and enabled scopes.
- Use hybrid retrieval: deterministic filters first, dense/sparse retrieval second, rerank third, policy gate fourth.
- Expose `search_skills(query, constraints)` and `read_skill(skill_id)` rather than loading all skill descriptions into the initial prompt.
- Keep execution handles separate from routing metadata.
- Record activation telemetry: query, shortlist, selected skill, used resources, outcome, token cost, latency, and correction events.
- Add route-quality evals with hard negatives, near-duplicate skills, stale skills, missing-skill cases, and real coding tasks.

Tool-SEE should not be copied wholesale, but its top-k plus dynamic-search shape is the right backbone for solving "10,000 skills without context blow-up."

## Reviewed Paths

- `/tmp/myagents-research/pro-genai-tool-see/README.md`: Motivation, quick start, API example, dynamic expansion description, benchmark claims, token/TTFT figures, and links to blog/preprint.
- `/tmp/myagents-research/pro-genai-tool-see/pyproject.toml`: Package metadata, Python version, LangChain/LangGraph/OpenAI dependencies, and optional eval dependencies.
- `/tmp/myagents-research/pro-genai-tool-see/.env.example`: Embedding and chat model configuration, including local OpenAI-compatible endpoint examples.
- `/tmp/myagents-research/pro-genai-tool-see/tool_see/utils/tool_utils.py`: `ToolMemory`, ingestion text construction, embedding storage, cosine search, JSON persistence, and LangChain tool conversion.
- `/tmp/myagents-research/pro-genai-tool-see/tool_see/tool_searcher.py`: Top-k selection wrapper, score threshold handling, and result metadata shape.
- `/tmp/myagents-research/pro-genai-tool-see/tool_see/auto_tool_agent.py`: LangChain agent integration, `search_tools`, dynamic tool registration, middleware refresh path, and system prompt.
- `/tmp/myagents-research/pro-genai-tool-see/tool_see/utils/llm_utils.py`: Chat and embedding provider configuration, SQLite cache use, and OpenAI-compatible embedding wrapper.
- `/tmp/myagents-research/pro-genai-tool-see/tool_see/__init__.py`: Public package exports.
- `/tmp/myagents-research/pro-genai-tool-see/examples/test_flow.py`: Demo tool corpus, ingestion smoke flow, selection latency helper, tool creation helper, and agent demo.
- `/tmp/myagents-research/pro-genai-tool-see/benchmark_toolsee/benchmark.py`: MetaTool dataset download path, benchmark setup, ingestion, DeepEval tool correctness scoring, retrieval timing, and token-savings calculation.
- `/tmp/myagents-research/pro-genai-tool-see/benchmark_toolsee/token_utils.py`: Token counting method and tool-list token helper.
- `/tmp/myagents-research/pro-genai-tool-see/benchmark_toolsee/ttft_comparison.py`: All-tools versus five-tools latency measurement, prompt construction, model requirements, and token-delta reporting.
- `/tmp/myagents-research/pro-genai-tool-see/benchmark_toolsee/api_server.py`: OpenAI-compatible FastAPI shim for comparing all-tools and selected-tools modes.
- `https://api.github.com/repos/Pro-GenAI/Tool-SEE`: Repository metadata, star count, default branch, timestamps, license field, and topics.
- `https://github.com/Pro-GenAI/Tool-SEE`: GitHub repository page, README rendering, star/fork snapshot, and file map.
- `https://prane-eth.github.io/papers/tool-search-engine/` and `https://www.preprints.org/manuscript/202512.1744/download/final_file`: Preprint/project claims about architecture, metadata ingestion, dynamic expansion, benchmark methodology, results, and limitations.
- `https://huggingface.co/blog/prane-eth/tool-retrieval-for-scalable-agents`: Blog positioning and "thousands of tools without context collapse" claim, used only to compare marketing language against source.

## Excluded Paths

- `/tmp/myagents-research/pro-genai-tool-see/.git/`: VCS storage only. Used through `git rev-parse`, `git log`, and remote metadata commands for provenance.
- `/tmp/myagents-research/pro-genai-tool-see/assets/Comparison.gif`, `assets/Workflow.gif`, and `assets/Workflow.drawio`: Visual explanation assets. I checked the asset README and searched the drawio text for token/latency claims, but did not inspect binary image contents because they do not define runtime behavior.
- Generated `__pycache__` files under `/tmp/myagents-research/pro-genai-tool-see`: Created by `compileall`; excluded as build artifacts.
- Downloaded MetaTool datasets: The benchmark code references remote files from `HowieHwong/MetaTool`, but I did not download or review dataset contents because the assignment is the Tool-SEE repo implementation and running the benchmark would require external model/embedding configuration.
- External social/publication mirrors such as ResearchGate, Academia, Scribd, and Medium: The project page and Preprints PDF were sufficient to compare paper claims with code; additional mirrors were not needed.
- Dependency source for LangChain, LangGraph, OpenAI SDK, DeepEval, FastAPI, Uvicorn, and tiktoken: Reviewed as integration boundaries via imports and package metadata, not as vendored code.
