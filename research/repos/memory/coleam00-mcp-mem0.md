# coleam00/mcp-mem0

- URL: https://github.com/coleam00/mcp-mem0
- Category: memory
- Stars snapshot: 676 (GitHub repository page/search result, captured 2026-05-19)
- Reviewed commit: 22fb7af0432e15fbe379ad7c7c7beac911fa2648
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful small reference for wiring Mem0 behind FastMCP, especially the lifespan-owned client, minimal memory tool surface, and stdio/SSE client configs. It is too thin to copy as a production memory service because all calls share one hard-coded user scope, there is no auth, no update/delete tool, no privacy policy, no tests, and most safety depends on the deployment boundary around the MCP server and database.

## Why It Matters

`coleam00/mcp-mem0` is a compact MCP memory server template. It matters because it shows the smallest practical path from MCP tools to a persistent semantic memory backend: create a Mem0 `Memory` client once, expose a few FastMCP tools, and let clients connect through stdio or SSE.

For Agentic Coding Lab, the repo is most useful as a negative-space design reference. The happy path is easy to understand, but the missing pieces are exactly the ones a coding-agent memory layer must add: identity scope, retention, redaction, update/delete, audit, tests, and guarded client configuration.

## What It Is

The repo is a Python 3.12 MCP server using `mcp[cli]`, `mem0ai`, `vecs`, and `httpx`. It exposes three tools:

- `save_memory(ctx, text)`: wraps text in a single user message and calls `mem0_client.add(..., user_id="user")`.
- `get_all_memories(ctx)`: calls `mem0_client.get_all(user_id="user")` and returns a JSON string.
- `search_memories(ctx, query, limit=3)`: calls `mem0_client.search(query, user_id="user", limit=limit)` and returns a JSON string.

Mem0 is configured through environment variables for the LLM provider, model, embedding model, and Supabase/PostgreSQL connection string. The server can run as SSE on `HOST`/`PORT` or as stdio under a local Python or Docker MCP client config.

## Research Themes

- Token efficiency: Moderate. The search tool defaults to `limit=3`, which encourages narrow retrieval, and Mem0 handles extraction/semantic indexing. The `get_all_memories` tool can dump every memory into context, so the template needs policy around when agents may call it.
- Context control: Weak. All operations use the hard-coded `DEFAULT_USER_ID = "user"`. There is no project, repo, agent, session, or tenant scope at the MCP boundary.
- Sub-agent / multi-agent: Weak. Multiple agents can share the same server, but they also share the same Mem0 user namespace unless the code is modified.
- Domain-specific workflow: Low. The tools store generic text; no coding-specific schemas, metadata, source attribution, command/test result classes, or repo filters are exposed.
- Error prevention: Low. The code catches exceptions and returns error strings, but has no validation, no tests, no typed error channel, no retries, and no safeguards against saving secrets or transient noise.
- Self-learning / memory: Good basic fit. The server gives agents durable save/search/all-memory operations backed by Mem0 and a vector store.
- Popular skills: Relevant as an MCP memory template rather than a skill pack. Its clearest reusable skill pattern is "search memory before decisions, save durable facts after work," but the repo does not ship agent instructions enforcing that policy.

## Core Execution Path

Runtime starts in `src/main.py`. `load_dotenv()` reads local configuration, `FastMCP` is initialized with name `mcp-mem0`, description, host, port, and the `mem0_lifespan` async context manager. `main()` reads `TRANSPORT`; when it equals `sse`, the server calls `mcp.run_sse_async()`, otherwise it calls `mcp.run_stdio_async()`.

`mem0_lifespan()` calls `get_mem0_client()` from `src/utils.py` once and yields a dataclass containing the resulting `Memory` client. Each tool retrieves that client through `ctx.request_context.lifespan_context.mem0_client`.

The save path builds `messages = [{"role": "user", "content": text}]`, then calls `mem0_client.add(messages, user_id=DEFAULT_USER_ID)`. It does not pass metadata, project scope, source, or tags. The returned MCP value is a success string that echoes the saved text, truncated to 100 characters.

The all-memory path calls `mem0_client.get_all(user_id=DEFAULT_USER_ID)`. If Mem0 returns a dict with `results`, the server flattens each item to `memory["memory"]`; otherwise it returns the raw structure. It serializes the result with `json.dumps(..., indent=2)`.

The search path calls `mem0_client.search(query, user_id=DEFAULT_USER_ID, limit=limit)`, flattens a `results` dict the same way, and returns formatted JSON. The default limit is 3, but callers can request a larger limit because there is no upper bound.

## Architecture

The architecture has four small pieces:

1. FastMCP transport/runtime in `src/main.py`.
2. A lifespan context containing one Mem0 `Memory` client.
3. Environment-driven Mem0 configuration in `src/utils.py`.
4. Supabase/PostgreSQL vector storage through Mem0's `supabase` vector-store provider.

`get_mem0_client()` builds a Mem0 config dictionary. For `LLM_PROVIDER=openai` or `openrouter`, it sets Mem0's LLM provider to `openai`, model from `LLM_CHOICE`, temperature `0.2`, and `max_tokens=2000`. For OpenAI it configures the OpenAI embedder with `EMBEDDING_MODEL_CHOICE` or `text-embedding-3-small` and 1536 dimensions. For Ollama it configures both LLM and embedder with `ollama_base_url` from `LLM_BASE_URL`, defaulting embeddings to `nomic-embed-text` and 768 dimensions.

The vector store is always `supabase` with collection name `mem0_memories`, `DATABASE_URL` as the connection string, and embedding dimensions selected by provider: 1536 for OpenAI/OpenRouter-style config, 768 for Ollama.

`CUSTOM_INSTRUCTIONS` exists for memory processing guidance, but the config line that would pass it to Mem0 is commented out. The current server relies on Mem0 defaults for fact extraction and memory updates inside `mem0_client.add()`.

## Design Choices

The repo chooses a minimal MCP tool set: save, list all, and semantic search. That is good for template clarity but leaves update/delete/forget flows outside the server.

It keeps the Mem0 client in MCP lifespan context instead of constructing it per request. That is the best design choice in the repo because it gives a clear pattern for shared clients, database handles, and provider setup.

It uses one default user ID for every operation. This simplifies examples, but it is the biggest design weakness for real agents because identity and authorization are not part of the tool schema.

It exposes both SSE and stdio. SSE makes the server usable as a reachable endpoint for remote-style clients; stdio lets a local MCP client spawn the process or Docker container.

It treats Mem0 as the source of truth for extraction, vector indexing, retrieval, and persistence. The MCP layer is intentionally thin and does not define its own memory schema.

It returns human-readable strings for both success and failure. That is easy to demo, but production agents need structured tool results so they can distinguish stored memory IDs, warnings, and hard failures.

## Strengths

The execution path is easy to audit. There are only two source files, one Dockerfile, and README client configs.

The FastMCP lifespan pattern is useful. Agentic Coding Lab can reuse that shape for a memory service that initializes a database/vector client once and exposes typed MCP tools.

The README gives practical client wiring for SSE, Claude Desktop/Windsurf-style stdio, Docker stdio, and n8n container networking. That is useful when evaluating MCP deployment ergonomics.

The provider split covers a common local/remote choice: OpenAI/OpenRouter-style LLMs versus Ollama, with corresponding embedding dimensions and Supabase storage.

The search tool defaults to a small limit. That is a good starting habit for memory recall because it limits context injection by default.

## Weaknesses

All memory operations share `user_id="user"`. In a multi-user, multi-project, or multi-agent coding system, this can cause cross-context memory leakage.

There is no update, delete, or forget tool. Agents can save and retrieve, but cannot correct stale facts or remove sensitive memories through the MCP interface.

There is no authentication or authorization in the MCP server. SSE binds to `0.0.0.0` by default, so deployment must provide network isolation, reverse-proxy auth, or localhost-only binding.

There is no privacy control around saved text. The server can store secrets, raw logs, proprietary code snippets, or speculative model inferences, and the success response echoes part of the saved content.

The OpenRouter configuration is questionable. The README advertises `LLM_BASE_URL`, but `src/utils.py` only uses base URL for Ollama; for `openrouter`, it sets Mem0's provider to `openai` and sets `OPENROUTER_API_KEY` without passing a base URL in the config.

Error handling returns strings such as `Error saving memory: ...`. MCP clients may treat these as ordinary tool output unless caller instructions inspect them.

There are no tests, example clients, CI workflows, schema migrations, or integration checks. The repo is a template, not a verified memory subsystem.

`get_all_memories` can return the entire memory set. Without scope and budget controls, that can defeat the point of selective memory retrieval.

## Ideas To Steal

Use FastMCP lifespan context for long-lived memory dependencies. It keeps tool handlers small and avoids repeated client initialization.

Expose memory as explicit MCP tools instead of implicit prompt injection. Agents can decide when to search and when to save.

Keep a small default search limit. Retrieval should start narrow and require explicit broadening.

Document both stdio and SSE configs for every memory server. Coding agents often need local spawning during development and reachable endpoints during integration tests.

Treat `.env.example` as part of the memory product. It should name required providers, embedding dimensions, storage URLs, and transport behavior clearly.

Keep the first version's tool surface small, but add structured returns from the start: memory IDs, stored text summary, source, scope, created time, and error codes.

## Do Not Copy

Do not copy the hard-coded user ID. Agentic Coding Lab memory needs explicit `user_id`, `repo_id`, `project_id`, `agent_id`, and/or `run_id` scope.

Do not expose `get_all_memories` without filters and token-budget rules. Broad recall should be an admin or debugging path, not a default agent habit.

Do not deploy SSE on `0.0.0.0` without an access-control layer. Memory tools are sensitive because they can reveal and persist durable user/project facts.

Do not return plain success/error strings as the only tool output. Agents need structured status and identifiers for correction, deletion, and audit.

Do not store arbitrary text with no classification. Coding memory should distinguish durable preferences, verified project facts, architecture decisions, build/test commands, failures, and sensitive content that must be rejected.

Do not rely on Mem0 defaults alone for coding-agent safety. Add redaction, retention, source attribution, update/delete, and eval checks around the backend.

Do not assume README provider settings are fully wired. Verify base URL and API-key behavior for each provider in code before copying config snippets.

## Fit For Agentic Coding Lab

Fit is moderate to strong as a template, not as a system to adopt unchanged. It belongs in `memory` because it directly exposes persistent memory through MCP and uses Mem0 for semantic storage/retrieval.

Agentic Coding Lab should borrow the thin MCP adapter shape, lifespan-owned memory client, small search default, and dual transport documentation. The lab should replace the fixed user namespace with scoped tool inputs, add project/repo metadata to saves, add update/delete/forget tools, and enforce a "search before relying on memory, save only durable verified facts" policy.

The best local pattern is a guarded memory MCP server: `save_memory` requires scope plus memory type, `search_memories` requires scope plus query, `get_all_memories` is filtered and capped, and `delete_memory`/`update_memory` require IDs. Every save should pass through secret filtering and source attribution.

## Reviewed Paths

- `/tmp/myagents-research/coleam00-mcp-mem0/README.md`: project purpose, tool list, prerequisites, environment variables, run commands, SSE/stdio client configs, Docker setup, and template guidance.
- `/tmp/myagents-research/coleam00-mcp-mem0/src/main.py`: FastMCP server construction, lifespan context, three MCP tools, fixed user scope, tool error behavior, and transport selection.
- `/tmp/myagents-research/coleam00-mcp-mem0/src/utils.py`: Mem0 client configuration, provider branches, embedder setup, Supabase vector-store config, commented custom-instruction hook, and environment variable handling.
- `/tmp/myagents-research/coleam00-mcp-mem0/.env.example`: documented transport, model, embedding, API-key, and database settings.
- `/tmp/myagents-research/coleam00-mcp-mem0/pyproject.toml`: package metadata and runtime dependencies.
- `/tmp/myagents-research/coleam00-mcp-mem0/Dockerfile`: container build path and default command.
- `/tmp/myagents-research/coleam00-mcp-mem0/.dockerignore` and `/tmp/myagents-research/coleam00-mcp-mem0/.gitignore`: environment-file exclusion and local artifact ignores.
- `/tmp/myagents-research/coleam00-mcp-mem0/LICENSE`: MIT license.
- `/tmp/myagents-research/coleam00-mcp-mem0/uv.lock`: skimmed only to confirm locked dependency snapshot and `mem0ai==0.1.88`; excluded from design analysis as generated dependency data.

## Excluded Paths

- `/tmp/myagents-research/coleam00-mcp-mem0/.git/`: VCS internals; exact reviewed commit captured separately.
- `/tmp/myagents-research/coleam00-mcp-mem0/public/Mem0AndMCP.png`: README presentation image; useful for docs appearance, not execution path or memory design.
- `/tmp/myagents-research/coleam00-mcp-mem0/uv.lock`: generated lockfile; skimmed for dependency provenance but not used as architecture evidence.
- `/tmp/myagents-research/coleam00-mcp-mem0/.gitattributes`: repository metadata with no MCP, Mem0, safety, or client-config behavior.
- Tests and examples beyond README configs: none were present in the reviewed checkout.
- Vendored source, generated code, binary runtime assets, and UI-only application paths: none were present apart from the README image and lockfile noted above.
