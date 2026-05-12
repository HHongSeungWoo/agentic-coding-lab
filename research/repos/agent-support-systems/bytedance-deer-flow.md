# bytedance/deer-flow

- URL: https://github.com/bytedance/deer-flow
- Category: agent-support-systems
- Stars snapshot: 66,973 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: bedbf2291e182a53c7be6bece9485d44300d1925
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for long-horizon agent harness design, especially middleware-driven orchestration, subagent delegation, memory/context controls, and sandbox/tool boundaries. Adopt patterns selectively; the full system is a broad product platform with global config, UI, channel, and deployment surface that is too heavy to copy into a focused coding-agent lab.

## Why It Matters

DeerFlow is a high-visibility, actively maintained open-source "super agent" harness that tries to solve the hard parts around long runs: persistent threads, resumable execution, subagents, memory, skill loading, tool search, MCP/ACP integration, sandboxed files and shell, streaming run events, rollback, and audit. It is relevant because it exposes real seams and failure modes in a production-style long-horizon agent system rather than presenting only a demo graph.

For agentic coding work, the useful part is not the application shell. The useful part is the set of harness primitives: a lead agent with controlled context injection, task delegation, virtualized workspace paths, guarded shell/file tools, deferred tool exposure, checkpoint rollback, and event journaling.

## What It Is

DeerFlow 2.0 is a Python/FastAPI backend plus frontend around a LangGraph/LangChain lead-agent graph. The root graph registry exposes one graph, `lead_agent`, through `backend/langgraph.json`. Runtime requests flow through the gateway, become LangGraph runs with checkpointing and streaming, and invoke a lead agent built by `deerflow.agents:make_lead_agent`.

The harness composes behavior from configuration and middleware instead of a fixed hand-written workflow graph. The lead agent receives a system prompt, a middleware chain, selected tools, memory/context reminders, and optional subagent access. Tools cover file operations, shell, web/search, MCP servers, ACP agents, skills, image viewing, clarification, and artifact presentation. Sandboxes can be local host-backed directories, AIO containers, or provisioner-backed containers.

## Research Themes

- Token efficiency: Static prompt text is separated from dynamic date/memory reminders so provider prompt caches can reuse the stable prefix. Skills use progressive loading instead of eagerly injecting all skill content. MCP tools can be deferred behind `tool_search`, exposing schemas only after selection. Summarization preserves selected recent skill reads and truncates tool output. Run journals bucket token usage by lead agent, subagent, and middleware tags.
- Context control: `ThreadState` carries sandbox, thread data, title, artifacts, todos, uploads, and viewed images. `DynamicContextMiddleware` injects hidden memory/date reminders. Uploads middleware adds file inventories and converted outlines. Summarization, memory injection, scoped subagent prompts, and per-agent skill/tool allowlists reduce uncontrolled context growth.
- Sub-agent / multi-agent: The `task` tool delegates to named subagents from a registry. Built-ins include `general-purpose` and `bash`, and config can add custom agents. Subagents run in background tasks, stream progress events, inherit parent sandbox/thread data, and cannot call `task` again. A middleware clamps concurrent task calls and removes excess tool calls from both LangChain and raw provider metadata.
- Domain-specific workflow: Skills and custom agents are the main domain mechanism. Built-in skill categories include deep research, data analysis, chart visualization, presentation, image, documentation, newsletter, podcast, academic paper, consulting, literature review, GitHub deep research, frontend design, web design guidelines, and video generation. Coding applicability exists through bash/file tools, workspace artifacts, and ACP adapters for coding agents, but the product is not coding-only.
- Error prevention: The system has clarification tooling, loop detection, tool-error-to-ToolMessage conversion, sandbox audit middleware, local path validation, host bash disabled by default, run cancellation, rollback to a pre-run checkpoint, and tests around these paths. These reduce common long-run failures but do not make local execution a hard security boundary.
- Self-learning / memory: Memory is structured into categories such as work context, personal context, top-of-mind, history, and facts. Post-run memory updates are debounced and written through an LLM updater, with per-user and per-agent storage. Memory injection is budgeted and separated from the static prompt.
- Popular skills: The skills system is worth copying as a contract: small `SKILL.md` instructions, referenced resources loaded on demand, read-only skill mounts at `/mnt/skills`, and optional skill evolution. The individual public skills are domain content, not core harness architecture.

## Core Execution Path

The primary service path is:

1. API request reaches the gateway run route.
2. `backend/app/gateway/services.py` normalizes input, validates model overrides, injects authenticated user context, creates run config, and asks `RunManager` to start a run.
3. `backend/packages/harness/deerflow/runtime/runs/worker.py` builds runtime context, captures a pre-run checkpoint, installs LangGraph runtime into config, attaches a `RunJournal`, creates the lead agent, streams LangGraph chunks, publishes serialized events, handles aborts/errors, and rolls back on interrupt when requested.
4. `backend/packages/harness/deerflow/agents/lead_agent/agent.py` resolves config/model/agent mode, builds middleware, applies the lead prompt, loads available tools, and calls `langchain.agents.create_agent`.
5. Middleware injects thread data, uploads, sandbox state, dynamic memory/date, summarization, todo handling, token accounting, title generation, memory updates, image support, deferred tool filtering, subagent limits, loop detection, clarification, and error handling.
6. Tool calls cross explicit boundaries: local/container sandbox tools, MCP tools, ACP agents, skill management tools, artifact presentation, clarification, and `task` subagent delegation.
7. Run events and token usage are journaled and streamed back over SSE through the gateway stream bridge.

There is also an embedded sync-client path in `backend/packages/harness/deerflow/client.py`. It builds the same lead-agent style harness in process, caches agent instances by config key, and streams values/messages/custom events without going through the gateway run worker.

No current `src/agents/graph/workflows` tree exists in the reviewed 2.0 repo. The actual orchestration path is the single LangGraph `lead_agent` plus middleware, runtime worker, tool layer, and subagent executor.

## Architecture

The backend is split into:

- Gateway/runtime: FastAPI routes, run services, run manager, checkpoint/store setup, stream bridge, journal, event store, and rollback.
- Harness agents: lead-agent factory, prompt builder, thread state, standalone SDK-style factory, and embedded client.
- Middleware: dynamic context, summarization, memory, sandbox, uploads, thread data, tool error handling, sandbox audit, subagent limit, title, todo, token usage, loop detection, clarification, guardrails, and vision helpers.
- Tools: built-in file/shell/search/artifact/subagent/clarification/ACP tools, MCP loading/cache, deferred tool search, and sync wrappers for async-only tools.
- Sandboxes: virtual path abstraction over local directories, AIO containers, or provisioner/Kubernetes-backed containers. Skills are mounted read-only; thread workspace/uploads/outputs are mounted read-write.
- Memory and skills: structured per-user/per-agent memory storage with debounced LLM updates; skills stored and loaded as on-demand instruction bundles.
- Subagents: config/registry/executor around background execution, skill/tool scoping, timeout/cancellation, and progress events.

The frontend contains both UI and substantial harness documentation. For this review, frontend execution UI was excluded, but `frontend/src/content/en/harness/*.mdx` was important because it documents intended architecture and surfaces several contract-level decisions.

## Design Choices

- Middleware is the primary extension mechanism. DeerFlow treats the graph as a stable lead-agent loop and layers behavior through ordered middleware.
- The system prompt is designed for prefix-cache reuse. Dynamic memory and date context are injected as hidden user reminders instead of changing the first system message every run.
- Skills are deferred. The prompt lists available skill folders and instructs the agent to read `SKILL.md` only when relevant.
- Tool schemas can be deferred behind `tool_search`, which is a practical answer to large MCP tool inventories.
- Subagents isolate task context but share the parent sandbox and thread data. This makes delegation cheap and artifact-friendly, but it is not full workspace isolation.
- Local host bash is disabled by default. Non-local/container sandboxes are treated as safer execution boundaries, while local path checks and audit middleware are explicitly best-effort.
- Runs are observable. The worker publishes metadata, stream chunks, custom events, token usage, journal entries, terminal status, and rollback state.
- Config drives almost everything: models, tools, groups, sandbox provider, subagents, MCP, ACP, memory, summarization, skills, guardrails, and channels.

## Strengths

- Strong long-horizon scaffolding: checkpointed runs, rollback, cancellation, event journaling, token accounting, thread data, artifacts, and sandbox state are part of the normal runtime path.
- Good context hygiene patterns: static prompt cache, dynamic hidden reminders, summarization with skill preservation, output truncation, upload outlines, deferred tools, and scoped subagent prompts.
- Subagent implementation handles real operational details: background execution, timeout, cancellation, progress streaming, no nested delegation, skill/tool allowlist merging, and concurrency limiting.
- Sandbox/tool boundaries are explicit and layered: virtual paths, read-only skills, read/write workspace mounts, host path masking, local path validation, audit middleware, and provider-specific sandbox implementations.
- Test coverage targets core harness contracts, including agent factory behavior, subagent executor, task tool routing, subagent limit middleware, sandbox security, memory isolation/update behavior, MCP sync wrapping, run worker rollback, tool output truncation, and client streaming.

## Weaknesses

- Local sandbox is not a security boundary. It uses host directories and subprocesses with path validation and audit checks. That is useful for developer ergonomics but insufficient for untrusted code.
- The architecture still leans on global mutable state: config singletons, MCP caches, skill caches, ContextVars, background task maps, timers, and isolated event-loop threads. These need care in multi-process or distributed deployments.
- Documentation and code have some drift. For example, subagent max-turn defaults and some skill-loader references differ between docs and implementation.
- Memory update quality depends on LLM JSON output and best-effort filtering. It is useful as a pattern, but it would need stronger schemas, evaluations, and rollback in a coding lab.
- Subagents share the same sandbox/thread workspace, so they reduce context pressure but do not provide strong isolation between parallel tasks.
- Tool error conversion can keep a run alive, but it may also hide systemic tool failures unless the journal or evaluator checks them.
- The repo has large app/product surface area: frontend UI, channel integrations, deployment, docs site, and many domain skills. That makes direct adoption heavy.

## Ideas To Steal

- Static lead prompt plus hidden dynamic memory/date reminders for prompt-cache stability.
- Deferred MCP/tool exposure through `tool_search` instead of flooding every run with tool schemas.
- Summarization that explicitly rescues recent skill reads and skill tool results.
- `task` tool progress events: started, running, completed, failed, cancelled, and timed out.
- Subagent concurrency limiting that edits both normalized tool calls and raw provider tool-call metadata.
- Virtual path model with read-only skill mounts and host path masking in tool output.
- Pre-run checkpoint capture plus rollback on interrupt.
- Run journal with lead/subagent/middleware token buckets and external subagent usage reporting.
- Per-user/per-agent memory storage with debounced updates and explicit injection budgets.

## Do Not Copy

- Do not treat the local sandbox as sufficient isolation for untrusted coding tasks.
- Do not copy regex/shlex command audit as a primary security layer; use it only as a supplementary policy layer.
- Do not bring over the whole product shell if the target is a focused coding-agent harness.
- Do not rely on broad global singletons and background timers without a clear multi-process strategy.
- Do not adopt LLM-written memory as durable truth without schema validation, test fixtures, and user-visible correction paths.
- Do not copy the full prompt/superagent behavior wholesale; extract the contract-level ideas and keep the coding-agent prompt smaller.

## Fit For Agentic Coding Lab

Fit is conditional and pattern-oriented. DeerFlow is one of the better references for long-horizon orchestration and harness boundaries, but it should not be imported wholesale. A coding-agent lab should extract the lead-agent middleware structure, deferred tools, subagent task protocol, workspace/sandbox contract, event journal, and rollback model.

The strongest coding-agent applicability is in three areas. First, context management: dynamic reminders, summarization, skill loading, and deferred tools directly address token and context drift. Second, tool boundaries: virtual paths, read-only skill mounts, host path masking, audit, and container provider interfaces map well to coding environments. Third, orchestration: `task` delegation with scoped tools/skills and visible progress events is a practical model for helper agents.

The weakest fit is product breadth. DeerFlow optimizes for a general super-agent experience with UI, channels, media, presentations, web research, custom agents, and deployment. For coding agents, keep the narrower substrate and build stricter verification, sandbox isolation, and repository-aware evaluation on top.

## Reviewed Paths

- `README.md`
- `config.example.yaml`
- `backend/langgraph.json`
- `frontend/src/content/en/harness/design-principles.mdx`
- `frontend/src/content/en/harness/lead-agent.mdx`
- `frontend/src/content/en/harness/middlewares.mdx`
- `frontend/src/content/en/harness/tools.mdx`
- `frontend/src/content/en/harness/sandbox.mdx`
- `frontend/src/content/en/harness/subagents.mdx`
- `frontend/src/content/en/harness/memory.mdx`
- `frontend/src/content/en/harness/skills.mdx`
- `frontend/src/content/en/harness/mcp.mdx`
- `frontend/src/content/en/harness/configuration.mdx`
- `backend/app/gateway/deps.py`
- `backend/app/gateway/services.py`
- `backend/app/gateway/routers/thread_runs.py`
- `backend/packages/harness/deerflow/agents/__init__.py`
- `backend/packages/harness/deerflow/agents/factory.py`
- `backend/packages/harness/deerflow/agents/thread_state.py`
- `backend/packages/harness/deerflow/agents/lead_agent/agent.py`
- `backend/packages/harness/deerflow/agents/lead_agent/prompt.py`
- `backend/packages/harness/deerflow/agents/middlewares/dynamic_context_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/summarization_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/memory_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/thread_data_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/uploads_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/tool_error_handling_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/sandbox_audit_middleware.py`
- `backend/packages/harness/deerflow/agents/middlewares/subagent_limit_middleware.py`
- `backend/packages/harness/deerflow/agents/memory/storage.py`
- `backend/packages/harness/deerflow/agents/memory/queue.py`
- `backend/packages/harness/deerflow/agents/memory/updater.py`
- `backend/packages/harness/deerflow/subagents/config.py`
- `backend/packages/harness/deerflow/subagents/registry.py`
- `backend/packages/harness/deerflow/subagents/executor.py`
- `backend/packages/harness/deerflow/subagents/builtins/general_purpose.py`
- `backend/packages/harness/deerflow/subagents/builtins/bash_agent.py`
- `backend/packages/harness/deerflow/tools/tools.py`
- `backend/packages/harness/deerflow/tools/builtins/task_tool.py`
- `backend/packages/harness/deerflow/tools/builtins/tool_search.py`
- `backend/packages/harness/deerflow/mcp/tools.py`
- `backend/packages/harness/deerflow/mcp/cache.py`
- `backend/packages/harness/deerflow/sandbox/security.py`
- `backend/packages/harness/deerflow/sandbox/tools.py`
- `backend/packages/harness/deerflow/sandbox/local/local_sandbox.py`
- `backend/packages/harness/deerflow/sandbox/local/local_sandbox_provider.py`
- `backend/packages/harness/deerflow/community/aio_sandbox/aio_sandbox.py`
- `backend/packages/harness/deerflow/community/aio_sandbox/aio_sandbox_provider.py`
- `backend/packages/harness/deerflow/runtime/runs/worker.py`
- `backend/packages/harness/deerflow/runtime/runs/manager.py`
- `backend/packages/harness/deerflow/runtime/journal.py`
- `backend/packages/harness/deerflow/runtime/stream_bridge/async_provider.py`
- `backend/packages/harness/deerflow/runtime/events/store/base.py`
- `backend/packages/harness/deerflow/client.py`
- `backend/tests/test_create_deerflow_agent.py`
- `backend/tests/test_subagent_executor.py`
- `backend/tests/test_task_tool_core_logic.py`
- `backend/tests/test_subagent_limit_middleware.py`
- Test inventory surveyed for memory, sandbox, MCP, run-worker, tool-search, summarization, dynamic-context, and client coverage.

## Excluded Paths

- `frontend/src/components`, frontend routes, frontend tests, and general UI implementation: UI/product surface, not the harness execution path.
- `frontend/public`, images, screenshots, videos, and binary assets: generated or presentation assets, not orchestration logic.
- `docs/pr-evidence`, `pr-build`, and other PR/demo artifacts: generated review evidence or build artifacts unrelated to core agent design.
- `README_*.md` translations other than the main `README.md`: duplicate translated documentation.
- `skills/public/**` individual skill content: domain-specific prompt packs. The skills mechanism was reviewed through docs, prompts, storage, and mounts, but individual skill bodies were not needed for harness architecture.
- Channel integrations for Slack, Telegram, Feishu, WeChat, and DingTalk beyond README/config overview: useful product integrations, but not central to coding-agent orchestration.
- `docker/nginx`, frontend build scripts, deployment wrappers, and packaging metadata: operational/deployment surface outside the agent support-system core.
- Deep provider-specific model adapters and compatibility patches: sampled through model resolution and factory usage; detailed provider behavior is not the key research target.
- Auth CRUD/settings/UI routes outside gateway run creation and streaming: required for the app but not for core agent execution.
