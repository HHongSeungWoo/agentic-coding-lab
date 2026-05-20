# langchain-ai/memory-agent

- URL: https://github.com/langchain-ai/memory-agent
- Category: memory
- Stars snapshot: 439 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 09bf577731b4d5a35157cf4e18aa5af3c7a5095d
- Reviewed at: 2026-05-20 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Small, clear LangGraph reference for long-term user memory through a `Store` and one model-visible `upsert_memory` tool. Best as a minimal architecture pattern for scoped memory retrieval and write-back, not as a complete memory subsystem: there is no separate reflection worker, no deterministic extraction policy, thin tests, README/default-model drift, and privacy controls stop at `user_id` namespace isolation plus hidden injected tool args.

## Why It Matters

`langchain-ai/memory-agent` is useful because it shows the shortest real LangGraph path from conversation state to durable memory and back into future prompts. It is not a broad framework; the whole agent is a few Python files plus LangGraph deployment config.

For Agentic Coding Lab, the repo matters as a baseline memory loop. It demonstrates how much can be done with three primitives: typed runtime context, namespaced store search, and a model-bound tool that persists structured memory. It also exposes what is missing when memory is left entirely to the chat model's judgment.

## What It Is

The repo is a Python package named `memory-agent` that exports a compiled LangGraph graph called `MemoryAgent`. It implements a ReAct-style chatbot that retrieves memories for a configured `user_id`, inserts matching memories into the system prompt, lets the model call `upsert_memory(content, context, memory_id=None)`, stores memories under `("memories", user_id)`, then routes back to the model to answer with the stored result available.

The memory schema is intentionally tiny: each store value is `{"content": str, "context": str}` keyed by a UUID string. Existing memories can be updated when the model passes `memory_id`; otherwise a new UUID is created. The `user_id` and `store` arguments are hidden from the model with `InjectedToolArg`.

The LangGraph config exposes one graph, `agent`, backed by `src/memory_agent/graph.py:graph`. It also configures a store index with OpenAI `text-embedding-3-small` embeddings at 1536 dimensions, so semantic search is available in hosted or LangGraph runtime contexts that honor `langgraph.json`.

## Research Themes

- Token efficiency: Moderate for a demo. Retrieval is limited to 10 memories and the query uses only the last three messages, but there is no token budget, memory summarizer, score threshold, or prompt-size guard.
- Context control: Moderate. Memories are explicitly wrapped in `<memories>` and include keys/scores, and storage is namespaced by `user_id`. Current chat history is otherwise passed through unchanged, and recalled memory content enters the system prompt without authority labeling beyond the XML-like wrapper.
- Sub-agent / multi-agent: Not present. There are no subagents, shared memory protocols, locking, cross-agent scopes, or role-specific memory rules.
- Domain-specific workflow: Low as-is. The example learns user preferences across chat threads; coding-agent adaptation would need repo/task/run fields, source provenance, and rules for what facts are worth storing.
- Error prevention: Low. The tool docstring asks the model to update conflicting memories, but there is no deterministic duplicate detection, redaction, conflict resolver, deletion path, memory validation, or prompt-injection guard for stored content.
- Self-learning / memory: Strong as a minimal example. The active loop retrieves previous memories, lets the model decide what to save or update, and persists facts across threads through LangGraph Store.
- Popular skills: No Codex/Claude skills or MCP tools. Reusable pattern is the LangGraph memory circuit: retrieve scoped memories before model call, expose one narrow write tool, then re-enter the model after storage.

## Core Execution Path

The graph starts at `call_model`. It reads `user_id`, `model`, and `system_prompt` from `Runtime[Context]`. It searches `runtime.store` under namespace `("memories", user_id)` with a query built from the last three message contents and `limit=10`.

Search results are formatted as `[memory_key]: {value} (similarity: {score})` and inserted into the system prompt inside `<memories>...</memories>`. The prompt also receives `datetime.now().isoformat()` as `time`.

`utils.load_chat_model()` splits the configured `provider/model` string and calls LangChain `init_chat_model`. The loaded model is bound to one tool, `upsert_memory`, then invoked with the system message plus all current state messages.

`route_message` checks the last model message. If it has tool calls, execution goes to `store_memory`; otherwise the graph ends.

`store_memory` reads all tool calls from the last message and executes them concurrently with `asyncio.gather`. Each call passes model-provided args plus injected `user_id` and `store`. `upsert_memory` writes to the store using `store.aput(("memories", user_id), key=str(mem_id), value={"content": content, "context": context})`.

After writes finish, `store_memory` returns tool messages tied to the original tool call IDs. The graph then routes back to `call_model`, so the model can see storage confirmations and produce a final user-facing response. If that second model call also emits tool calls, the same cycle repeats.

There is no separate reflection path. Memory extraction, conflict detection, update choice, and content/context wording are all controlled by the main chat model through the tool call.

## Architecture

The architecture is a single LangGraph `StateGraph` with two nodes and one conditional edge:

- `State.messages`: conversation state, using LangGraph `add_messages` reducer.
- `Context.user_id`: memory namespace selector, defaulting to `"default"` or `USER_ID` env var.
- `Context.model`: chat model selector, defaulting in code to `anthropic/claude-sonnet-4-5-20250929`.
- `Context.system_prompt`: configurable prompt template from `prompts.SYSTEM_PROMPT`.
- `call_model`: retrieves memories, builds prompt, binds the memory tool, invokes the LLM.
- `store_memory`: executes model-requested memory writes and returns tool responses.

Runtime storage is delegated to LangGraph Store. The repo does not implement a custom database, vector index, serializer, migration path, or retention policy. `langgraph.json` provides the deployment-facing store index configuration with OpenAI embeddings.

Configuration is intentionally light. `.env.example` documents LangSmith project naming and provider API keys. `Context.__post_init__` lets environment variables override default field values when explicit constructor values are not supplied.

The README and code disagree on the default model. README says the default is `anthropic/claude-3-5-sonnet-20240620`, while `context.py` currently defaults to `anthropic/claude-sonnet-4-5-20250929`. Treat source code as authority for this reviewed commit.

## Design Choices

The repo chooses model-directed memory writes instead of a deterministic extractor. This keeps the graph small and makes memory behavior easy to customize by changing prompts, but it makes save frequency, save quality, and update correctness model-dependent.

Memory values are structured just enough to separate a fact from its surrounding context. This is useful because future prompts can show both the remembered claim and why it was stored, without replaying the full original transcript.

Memory IDs are exposed in retrieval output and accepted back as `memory_id` tool args. This gives the model a simple update path for corrections and conflicts, but there is no validation that an update target belongs to the current search set beyond store namespace.

The graph re-enters the model after every memory write. That gives the model a chance to answer naturally after persistence, and lets it chain multiple writes if needed. The tradeoff is possible extra latency and recursive tool-call loops if the model keeps choosing to save memories.

The store namespace is only `("memories", user_id)`. That is good enough for a personal assistant demo. Coding agents would need more dimensions such as repo, branch, worktree, task, agent role, privacy class, and source event.

The deployed store index uses OpenAI embeddings. This is convenient for semantic search but means memory content can leave the local/runtime boundary for embedding unless a different store/index configuration is used.

## Strengths

The code is very easy to audit. The active memory loop fits in `graph.py`, the schema is visible in `tools.py`, and the state/context types are minimal.

Namespacing by `user_id` is explicit and tested. The integration test verifies that memories saved for `test-user` do not appear in `wrong-user`.

`InjectedToolArg` is used correctly for `user_id` and `store`, so the model sees the memory fields it should decide on but not the runtime plumbing.

The update story is understandable. Existing memory IDs are shown in the prompt, and the tool docstring tells the model to pass `memory_id` when correcting or deduplicating a fact.

The LangGraph Studio screenshots and README provide a concrete operator path: create a thread, store memories, start a new thread, and inspect/edit memory through the Studio memory panel.

The test/eval idea is pragmatic. The integration test uses LangSmith `@unit` over short, medium, and long conversations and checks that at least one memory is produced for the intended namespace.

## Weaknesses

There is no independent reflection/update worker. The main chat model must decide when to remember, what to remember, whether a fact conflicts, and how to rewrite old memory.

Memory safety is thin. There is no consent gate, PII/secret redaction, retention period, deletion API, audit trail, confidence field, privacy class, or policy that blocks storing sensitive user/project content.

Stored memory is inserted into the system prompt without strong trust-boundary framing. A malicious or stale memory could influence future behavior as prompt content.

The retrieval path has no score threshold or fallback policy. Up to 10 memories are included whenever the store returns them, even if weakly related or stale.

The query is a stringified Python list of the last three message contents. It is simple, but it is not a controlled search query and may behave poorly for long, multimodal, or tool-heavy messages.

Tests are sparse and partly non-deterministic. Unit tests cover `Context` env fallback only. Integration tests require a real model and assert only that some memory is saved under the right user namespace, not that the memory is accurate, deduplicated, updated, or safe.

README setup is stale in at least one important place: it references `.env.example` and default model setup, but the documented default model does not match the source default at the reviewed commit.

There is no coding-agent domain schema. The memory fields do not capture repo path, commit, command, error, decision, evidence, owner, expiry, or whether the fact came from user instruction versus observed execution.

## Ideas To Steal

Use a narrow, model-visible memory write tool with hidden runtime args. For coding agents, expose fields like `lesson`, `evidence`, `scope`, `privacy_class`, and `source`, while injecting repo/user/run IDs outside model control.

Keep memory retrieval in the graph before model invocation. This makes the memory boundary explicit and testable instead of burying it in a prompt helper.

Show memory IDs in recalled context and allow targeted updates. This is a practical way to support corrections without building a full merge UI first.

Route back to the model after storage. Coding agents can use the same pattern after writing a lesson or repo convention so final responses can mention what changed only when appropriate.

Treat `user_id` namespacing as the floor, not the ceiling. Agentic Coding Lab should extend the namespace to `(memory, user, repo, branch/worktree, agent_role)` or similar.

Use LangSmith-style small evals early. Even simple assertions like "saved under correct namespace" are useful, then add checks for false positives, conflict updates, no-secret storage, and retrieval relevance.

Keep demo schemas small but typed. A compact `content` plus `context` pair is a good starting point; production coding memory should add provenance and policy fields before adding graph complexity.

## Do Not Copy

Do not let the main chat model be the only memory policy. Add deterministic allow/deny filters, redaction, schema validation, and review gates for high-authority or sensitive memories.

Do not inject recalled memories as near-authoritative prompt text without provenance and trust labels. Coding-agent memories should be marked as remembered evidence, not instructions above current user/project rules.

Do not use only `user_id` for multi-project coding agents. Cross-repo memory bleed is a serious failure mode.

Do not rely on a tool docstring for duplicate/conflict handling. Add retrieval, comparison, and update tests that prove corrected facts replace old ones.

Do not send memory content to external embedding/model providers by default in private-code settings. Make embedding/model provider selection part of the memory privacy policy.

Do not evaluate memory quality only by "some memory exists." Add negative cases, exact expected fields, stale-memory handling, and no-store cases.

Do not copy README defaults blindly. The source and docs drift at this commit, so downstream templates need automated config/docs checks.

## Fit For Agentic Coding Lab

Fit is high as a minimal memory-loop reference and low as a complete dependency. The repo directly implements the relevant primitives: scoped retrieval, prompt injection, model-selected memory writes, store persistence, and update-by-ID.

The best Agentic Coding Lab use is to adapt the circuit, not the schema. A coding-agent version should retrieve repo/user scoped lessons before planning, expose a narrow `upsert_coding_memory` tool, inject runtime scope through hidden args, and store memories with evidence paths, timestamps, privacy class, confidence, and invalidation rules.

The main lesson is that memory architecture starts simple but policy debt appears immediately. Once a memory can affect future coding behavior, the system needs authority labels, source provenance, stale/conflict handling, secret filtering, and tests that prove memory helps without leaking or overfitting.

## Reviewed Paths

- `/tmp/myagents-research/langchain-ai-memory-agent/README.md`: project framing, LangGraph Studio setup, memory behavior, evaluation guidance, customization points, screenshots references, and stale default-model claim.
- `/tmp/myagents-research/langchain-ai-memory-agent/langgraph.json`: graph entrypoint, Python version, local dependency, `.env` usage, and OpenAI embedding store index configuration.
- `/tmp/myagents-research/langchain-ai-memory-agent/pyproject.toml`: package metadata, LangGraph/LangChain dependencies, dev dependencies, ruff/mypy settings, and Python version.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/graph.py`: active graph execution path, memory retrieval, prompt assembly, tool binding, conditional routing, memory storage, and graph compilation.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/state.py`: graph state schema and `messages` reducer.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/context.py`: runtime context schema, `user_id`, model default, system prompt config, and environment-variable override behavior.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/tools.py`: `upsert_memory` schema, hidden injected args, UUID/key behavior, namespace write path, and update guidance.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/prompts.py`: default system prompt and memory/time insertion points.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/utils.py`: provider/model parsing and LangChain chat model initialization.
- `/tmp/myagents-research/langchain-ai-memory-agent/src/memory_agent/__init__.py`: package export surface.
- `/tmp/myagents-research/langchain-ai-memory-agent/tests/unit_tests/test_context.py`: context initialization and environment fallback tests.
- `/tmp/myagents-research/langchain-ai-memory-agent/tests/integration_tests/test_graph.py`: LangSmith-decorated memory storage/eval cases and namespace isolation assertion.
- `/tmp/myagents-research/langchain-ai-memory-agent/tests/conftest.py`: async pytest backend fixture.
- `/tmp/myagents-research/langchain-ai-memory-agent/.github/workflows/unit-tests.yml`: CI unit-test, lint, type-check, spelling, and read-only workflow permissions.
- `/tmp/myagents-research/langchain-ai-memory-agent/.github/workflows/integration-tests.yml`: scheduled integration test workflow, provider/LangSmith secrets, and read-only workflow permissions.
- `/tmp/myagents-research/langchain-ai-memory-agent/.env.example`: LangSmith project and provider API key expectations.
- `/tmp/myagents-research/langchain-ai-memory-agent/.gitignore`: local secret/env, cache, build, and virtualenv exclusions.
- `/tmp/myagents-research/langchain-ai-memory-agent/Makefile`: local test/lint commands.
- `/tmp/myagents-research/langchain-ai-memory-agent/LICENSE`: MIT license and warranty posture.
- `/tmp/myagents-research/langchain-ai-memory-agent/static/memory_graph.png` and `/tmp/myagents-research/langchain-ai-memory-agent/static/memories.png`: viewed as README architecture/operator screenshots only, not source logic.

## Excluded Paths

- `/tmp/myagents-research/langchain-ai-memory-agent/.git/`: VCS internals; exact reviewed commit is recorded separately.
- `/tmp/myagents-research/langchain-ai-memory-agent/uv.lock`: generated dependency resolution snapshot. I used `pyproject.toml` for direct dependency and tooling review; the lock does not define memory behavior.
- `/tmp/myagents-research/langchain-ai-memory-agent/static/*.png`: binary LangGraph Studio screenshots. I viewed both screenshots for architecture/operator context, then excluded binary image data from source review.
- `/tmp/myagents-research/langchain-ai-memory-agent/.codespellignore`: empty spelling-tool config; no execution, memory, or safety behavior.
- `/tmp/myagents-research/langchain-ai-memory-agent/tests/**/__init__.py`: empty package marker files; no test behavior beyond package import layout.
- Generated local artifacts such as `.venv/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.langgraph_api/`, `__pycache__/`, build outputs, and local `.env` files: ignored by repo configuration or absent from the reviewed checkout; not source architecture.
- No vendored dependency source, generated code directories, model weights, binary databases, or UI implementation source were present in the reviewed checkout.
