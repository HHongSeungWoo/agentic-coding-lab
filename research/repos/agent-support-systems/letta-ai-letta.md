# letta-ai/letta

- URL: https://github.com/letta-ai/letta
- Category: agent-support-systems
- Stars snapshot: 22,650 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: bb52a8900a79cf1378e6e9cdecf244b673a13a72
- Reviewed at: 2026-05-12 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope reference for stateful agents with explicit memory blocks, recall history, archival memory, tool-mediated mutation, context accounting, and compaction. Best use is selective adaptation of its memory/context patterns, not adopting the full platform.

## Why It Matters

Letta is one of the clearest open-source implementations of a long-running agent whose state is not just a chat transcript. It persists core memory blocks, message history, archival passages, tools, secrets, file context, agent settings, and conversation-specific state, then rebuilds or compacts context as the agent runs.

For Agentic Coding Lab, the repo matters because coding agents have the same hard problems: durable project/user memory, scoped recall, prompt budget control, tool state, secret handling, reproducible agent lifecycle, and safe mutation of memory. Letta exposes these as real service code with tests, not only as docs or prompts.

## What It Is

Letta, formerly MemGPT, is a Python server and agent runtime for building stateful agents. The public API creates agents from `CreateAgent` requests, stores them as `AgentState`, runs messages through an agent loop, executes tools, updates memory, and records messages/runs in a database.

The main architecture is DB-first. Agents have persisted rows, many-to-many core memory blocks, attached tools, sources, archives, environment variables, and message IDs. The runtime assembles a system prompt from memory blocks, tool rules, directories, and memory metadata, then combines that with in-context messages and tool definitions for the LLM request.

## Research Themes

- Token efficiency: Strong. Letta avoids recompiling the persisted system prompt on ordinary V3 steps to preserve provider prefix caching, uses request-scoped skill text instead of persisting transient skills, truncates tool returns, counts tokens by provider when possible, and compacts message history when context approaches the configured threshold.
- Context control: Strong. Core memory blocks have labels, descriptions, char limits, read-only flags, metadata, and optional file-block projections. `ContextWindowOverview` breaks down token usage across system prompt, core memory, filesystem memory, tool rules, directories, summary memory, function definitions, messages, and archival/recall metadata.
- Sub-agent / multi-agent: Moderate. The repo has multi-agent groups, sleeptime agents, multi-agent core tools, conversation-specific state, and agent types. The reviewed core is stronger as a stateful single-agent substrate than as a general multi-agent coordination system.
- Domain-specific workflow: Strong. Agent types (`letta_v1_agent`, workflow, react, voice, sleeptime, legacy MemGPT variants), tool rules, files, sources, folders, blocks, and skills allow different prompt and tool surfaces without changing the storage model.
- Error prevention: Strong. Read-only blocks are enforced by memory tools, line-number artifacts are rejected in memory edits, client-side tools can require approval, custom sandbox tools receive a copied agent state, messages are checkpointed only after a successful step, and direct message modification is intentionally disabled in the newer API.
- Self-learning / memory: Core fit. Agents can append/replace/apply-patch to core memory, create/delete/rename blocks, insert and search archival passages, search prior conversation messages, and update file/directory context.
- Popular skills: Relevant pattern is Letta's `skills/*` memory blocks plus request-scoped `client_side_tools`. Available skills are rendered into prompt context without permanently changing the compiled system prompt.

## Core Execution Path

The main lifecycle starts in `AgentManager.create_agent_async`. It validates model settings, creates or attaches memory blocks, resolves tools and tool rules, adds base tools for the selected agent type, attaches sources/folders/tags/identities, encrypts agent secrets into environment-variable rows, creates the agent row, and persists the initial message sequence. For `letta_v1_agent`, the initial sequence is just the system message; older agent types get legacy boot/login messages.

Message handling enters through `POST /agents/{agent_id}/messages`. The router loads the agent with memory, tools, sources, tags, and environment variables, creates a run record, stores the active run in Redis, selects an `AgentLoop`, and calls `step` or streaming variants.

For current `letta_v1_agent` and sleeptime agents, `AgentLoop.load` selects `LettaAgentV3`. V3 applies conversation-specific block overrides when a `conversation_id` is present, prepares in-context messages without persisting the new input yet, builds request data from the current system prompt, message list, valid tools, tool rules, and request-scoped skills, then calls the LLM adapter.

If the model returns a normal assistant message, V3 can finish the step. If it returns tool calls, V3 routes them through the tool execution layer. Core memory tools mutate blocks and rebuild or refresh memory through services. Sandbox tools execute with copied `agent_state` and can only update persisted memory through explicit returned state. Client-side tools can stop for approval or external execution.

Only after the step succeeds does V3 checkpoint messages. It sets step/run/conversation IDs, persists new user/assistant/tool messages, and updates either `agent.message_ids` or the `conversation_messages` table. If the estimated context exceeds the threshold, V3 compacts messages into `[system] + [summary] + remaining messages` and updates the in-context message IDs.

## Architecture

The state model centers on `AgentState`. It includes the agent ID/name, message IDs, system prompt, agent type, LLM and embedding config, model settings, compaction settings, memory, blocks, tools, sources, tags, secrets, timezone, file limits, multi-agent group metadata, last-run metadata, and flags such as `message_buffer_autoclear` and `enable_sleeptime`.

Core memory is modeled as `Block` records. Blocks have `label`, `value`, `limit`, `description`, `read_only`, metadata, hidden tags, and optimistic versioning in the ORM. The `blocks_agents` join table enforces one block per label per agent and one attachment of a block to an agent. `Human` and `Persona` are special block labels with default descriptions.

`Memory.compile` renders memory into prompt sections. Standard agents get XML-like `<memory_blocks>` with descriptions, metadata, char counts, values, and read-only markers. Anthropic-backed modern agents can get line-numbered blocks for patch-style edits. Git-enabled memory renders `system/persona` as `<self>` and other system/external blocks as filesystem-like projections. Workflow/react-style agents intentionally render different directory sections.

The compiled system prompt is persisted as the first message. `PromptGenerator` and `agent_manager_helper` add `<memory_metadata>` with agent ID, conversation ID, prompt compile time, previous-message count, archival-memory count, and archive tags. Request-scoped available skills are appended to the request system prompt in V2/V3, but are not persisted into the compiled base prompt.

Message state uses both legacy and newer paths. Agents still store `message_ids` as a JSON list on the agent row. Conversations use `conversation_messages` with position and `in_context`, allowing conversation forks and isolated block copies. Message rows store role, content, tool calls, tool returns, run/step IDs, sender/conversation fields, and approval-related fields.

Long-term recall has two layers. Recall memory searches prior messages, optionally through Turbopuffer hybrid/vector/FTS search when enabled, or SQL fallback otherwise. Archival memory stores passages in archives with embeddings, metadata, tags, and optional Turbopuffer vector storage. Search formats results with IDs, timestamps, content, tags, and relevance metadata.

Tool execution is split by tool type. `ToolExecutionManager` dispatches Letta core memory/file tools to in-process executors, built-in tools to built-in executors, MCP tools to external MCP execution, and user tools to sandbox execution. Tool return char limits are applied after execution. Tool schemas carry source code, JSON schema, dependency requirements, approval defaults, parallel-execution flags, metadata, and project IDs.

Context accounting is first-class. `ContextWindowCalculator` parses compiled prompt sections, extracts top-level memory/filesystem/tool-rule/directory metadata, detects summary messages at index 1, counts tokens using provider-specific counters or fallbacks, and returns a structured overview. V3 compaction uses `compact_messages`, with self-compaction, sliding-window, and all-message modes plus fallback behavior when a mode fails or does not reduce tokens enough.

Security and privacy are mixed between useful primitives and deployment caveats. Agent secrets use a `Secret` wrapper and AES-256-GCM encryption when `LETTA_ENCRYPTION_KEY` is configured. Without an encryption key, plaintext is stored in the encrypted-value column by design. REST auth accepts bearer tokens and maps API keys to users. The privacy policy says basic telemetry is collected unless disabled, and hosted services may collect message requests/responses.

## Design Choices

Letta treats memory as structured state, not free text appended to a prompt. Block labels, limits, descriptions, read-only markers, and versioned ORM rows make memory inspectable and tool-addressable.

The system prompt is a persisted message, not rebuilt every step. This improves prefix caching but creates deliberate rebuild boundaries: some memory changes recompile immediately, while V3 ordinary steps preserve the current prompt until a rebuild, reset, or compaction path.

The agent loop checkpoints only after successful execution. Input messages are prepared in memory first, tool calls are handled, and only then are new messages persisted and linked into the agent or conversation context.

Memory mutation is tool-mediated. Core tools call service-layer methods, enforce read-only blocks, rebuild or refresh memory, and avoid letting arbitrary sandbox code mutate the live in-process `agent_state`.

Conversation isolation is implemented by copying selected blocks for a conversation and replacing those blocks into the agent state at run time. This is useful for task-specific memory without contaminating the agent's global blocks.

Skills are rendered as context rather than installed globally into every compiled prompt. Blocks under `skills/*` and request-scoped client tools can appear in the request system prompt while leaving the base prompt stable.

Compaction creates a deterministic summary slot. The final compacted context is `[system]`, a summary message, then retained messages. That makes context-window accounting and later updates easier to reason about.

## Strengths

Letta has a complete stateful-agent lifecycle: create, update, attach/detach tools and memory, run, cancel, reset messages, recompile prompts, inspect context windows, compact, fork conversations, and delete state.

The memory model is practical for coding agents. Small labeled blocks with limits and descriptions map well to user preferences, project conventions, repo notes, task state, and tool instructions.

Context observability is unusually good. The context overview explains where tokens are being spent instead of exposing only one total count.

The tool/memory boundary is well considered. Built-in memory tools mutate through services, sandbox tools get copied state, and client-side tools can require approval or external execution.

The tests cover important behavior: memory rendering, line-number rules, context extraction, prefix-caching behavior, compaction thresholds, static-buffer summarization, secret encryption, MCP encryption, and message search formatting.

Conversation-local blocks and conversation forks are a useful design for coding-agent tasks, where one repo/task may need temporary overrides without polluting global agent memory.

## Weaknesses

The platform is heavy. It combines agent runtime, REST API, ORM, migrations, provider adapters, sandboxing, MCP, file systems, tools, local LLM support, queues, telemetry, and hosting concerns. A coding-agent lab should not copy the whole surface.

`agent.message_ids` remains a JSON list with source comments pointing toward better mapping. Conversations have a stronger position/in-context join table; the agent-level path is less normalized.

Prompt rebuild semantics are subtle. Prefix caching is valuable, but memory changes are not always visible to the next request unless the right rebuild path runs. The integration tests intentionally check this behavior, so adopters must document it clearly.

Secrets are only encrypted at rest when an encryption key is configured. Without `LETTA_ENCRYPTION_KEY`, tests confirm plaintext is stored in the `_enc` column, which is unsafe for sensitive coding-agent environments.

Concurrent requests to the same agent are warned as undefined/interleavable in the router. That matters for coding agents running parallel subtasks against one shared memory.

Custom tools can receive agent IDs, copied agent state, Letta client access, and agent-scoped secrets as sandbox environment variables. That is useful, but it requires a clear trust and approval model.

The reviewed commit has an apparent compaction-threshold inconsistency: tests and comments expect non-GPT-5 models to use 100 percent unless proactive mode is forced, while `get_compaction_trigger_threshold` currently returns `context_window * 0.9` for all models.

The repo has multiple active agent loop generations and agent types. That provides compatibility but increases the chance of behavior drifting between V2, V3, workflow, react, sleeptime, and legacy MemGPT paths.

## Ideas To Steal

Use labeled memory blocks with `description`, `limit`, `read_only`, and metadata. This gives the agent and humans a stable schema for editable prompt memory.

Expose a context-window inspection API that breaks down token use by memory, messages, tools, system prompt, summaries, and retrieval metadata.

Keep request-scoped skills separate from persisted system prompts. This preserves cacheability and avoids accidental permanent prompt growth.

Checkpoint messages only after a step succeeds. For coding agents, this reduces durable state corruption from failed tool calls or interrupted runs.

Represent task/conversation overrides as isolated copies of selected memory blocks. That is a clean way to handle per-issue or per-repo state.

Route memory changes through a small set of core tools and service methods, with read-only enforcement and patch-style validation.

Use a deterministic compaction shape with one summary message near the front of context. It makes downstream context accounting simpler.

Separate in-process core tools, sandboxed custom tools, MCP tools, and client-side approval tools. The different trust levels should not share one execution path.

## Do Not Copy

Do not copy the entire Letta server as the default architecture for a coding-agent lab. The useful patterns are smaller than the platform.

Do not use a JSON `message_ids` list as the long-term primary context index if starting fresh. A join table with position and `in_context` is easier to query, fork, compact, and audit.

Do not hide prompt rebuild semantics behind implicit behavior. If memory edits are deferred for caching, users and tests need to know exactly when the prompt sees them.

Do not allow plaintext secret fallback in production. A missing encryption key should fail closed for coding-agent memory and tool credentials.

Do not expose custom-tool sandbox state, API clients, or secrets without a capability model, per-tool approvals, and audit logs.

Do not rely on LLM-written memory as verified repo truth. Coding-agent memory still needs source-file citations, command outputs, and freshness checks.

Do not inherit every provider adapter and agent type unless those paths have local tests. Provider sprawl makes memory/context bugs harder to isolate.

## Fit For Agentic Coding Lab

Fit is strong. Letta is directly relevant to stateful coding-agent support systems because it shows how to persist editable core memory, search history, attach tool state, account for context windows, compact long transcripts, and run agents through a service boundary.

The most useful adaptation is a smaller memory/context subsystem: project/user/task blocks, recent-message context, summary messages, archival passages, context-budget reports, tool-mediated edits, and conversation/task-local block copies. That would cover many coding-agent needs without adopting Letta's full hosted-agent platform.

For coding agents, the safest memory classes would be user preferences, repo conventions, commands, dependency constraints, architecture decisions, known failure modes, and task-local findings. The system should avoid storing raw secrets, unverified model guesses, stale source facts without provenance, and large code chunks that belong in retrieval indexes instead.

Before production use, Agentic Coding Lab would need stronger defaults for encryption, tenant/project isolation, concurrent run locking, memory provenance, memory-retention policy, and source-backed verification of coding facts.

## Reviewed Paths

- `/tmp/myagents-research/letta-ai-letta/README.md`: positioning, quickstart, stateful-agent examples, memory blocks, and tools.
- `/tmp/myagents-research/letta-ai-letta/PRIVACY.md` and `/tmp/myagents-research/letta-ai-letta/SECURITY.md`: telemetry, hosted-service data collection, opt-out note, and vulnerability reporting.
- `/tmp/myagents-research/letta-ai-letta/letta/schemas/agent.py`: `AgentState`, `CreateAgent`, model/settings, memory/tool/source fields, secrets, message-buffer behavior, and file limits.
- `/tmp/myagents-research/letta-ai-letta/letta/schemas/block.py` and `/tmp/myagents-research/letta-ai-letta/letta/schemas/memory.py`: core block schema, file blocks, memory rendering, git memory, line-numbered blocks, and skill rendering.
- `/tmp/myagents-research/letta-ai-letta/letta/schemas/message.py`, `/tmp/myagents-research/letta-ai-letta/letta/schemas/tool.py`, `/tmp/myagents-research/letta-ai-letta/letta/schemas/secret.py`, and conversation-related schemas: message/tool/approval/secret/conversation state surfaces.
- `/tmp/myagents-research/letta-ai-letta/letta/orm/agent.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/block.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/blocks_agents.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/message.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/archive.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/passage.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/conversation.py`, `/tmp/myagents-research/letta-ai-letta/letta/orm/conversation_messages.py`, and `/tmp/myagents-research/letta-ai-letta/letta/orm/blocks_conversations.py`: persisted state model for agents, blocks, messages, archives/passages, and conversations.
- `/tmp/myagents-research/letta-ai-letta/letta/services/agent_manager.py`, `/tmp/myagents-research/letta-ai-letta/letta/services/helpers/agent_manager_helper.py`, `/tmp/myagents-research/letta-ai-letta/letta/services/block_manager.py`, `/tmp/myagents-research/letta-ai-letta/letta/services/conversation_manager.py`, `/tmp/myagents-research/letta-ai-letta/letta/services/message_manager.py`, `/tmp/myagents-research/letta-ai-letta/letta/services/archive_manager.py`, and `/tmp/myagents-research/letta-ai-letta/letta/services/passage_manager.py`: create/update/rebuild lifecycle, conversation isolation, recall search, archival memory, passage insertion, and memory refresh.
- `/tmp/myagents-research/letta-ai-letta/letta/agents/agent_loop.py`, `/tmp/myagents-research/letta-ai-letta/letta/agents/letta_agent_v2.py`, `/tmp/myagents-research/letta-ai-letta/letta/agents/letta_agent_v3.py`, and `/tmp/myagents-research/letta-ai-letta/letta/agents/base_agent.py`: loop selection, V2/V3 request building, checkpointing, compaction, and tool response handling.
- `/tmp/myagents-research/letta-ai-letta/letta/services/tool_executor/`: core memory/file tools, sandbox tools, built-in tools, MCP execution, tool execution manager, tool return truncation, and memory mutation.
- `/tmp/myagents-research/letta-ai-letta/letta/services/tool_sandbox/base.py`: sandbox script generation, agent-state/client/env injection, and sandbox environment shape.
- `/tmp/myagents-research/letta-ai-letta/letta/functions/function_sets/base.py`: legacy/core memory tool interfaces and archival-memory tool definitions.
- `/tmp/myagents-research/letta-ai-letta/letta/prompts/prompt_generator.py` and `/tmp/myagents-research/letta-ai-letta/letta/prompts/`: system prompt compilation, memory metadata, and prompt templates.
- `/tmp/myagents-research/letta-ai-letta/letta/services/context_window_calculator/`: context section extraction, provider token counters, cached counting, and `ContextWindowOverview`.
- `/tmp/myagents-research/letta-ai-letta/letta/services/summarizer/`: V3 compaction, legacy summarizer, sliding-window/all/self compaction modes, and threshold helper.
- `/tmp/myagents-research/letta-ai-letta/letta/helpers/crypto_utils.py` and `/tmp/myagents-research/letta-ai-letta/letta/server/rest_api/auth_token.py`: encryption primitives and API-key/bearer-token auth.
- `/tmp/myagents-research/letta-ai-letta/letta/server/rest_api/routers/v1/agents.py` and `/tmp/myagents-research/letta-ai-letta/letta/server/rest_api/routers/v1/messages.py`: create/update/run/reset/recompile/context/archive/core-memory/message API surfaces.
- `/tmp/myagents-research/letta-ai-letta/tests/test_memory.py`, `/tmp/myagents-research/letta-ai-letta/tests/test_context_window_calculator.py`, `/tmp/myagents-research/letta-ai-letta/tests/integration_test_system_prompt_prefix_caching.py`, `/tmp/myagents-research/letta-ai-letta/tests/test_compaction_thresholds.py`, `/tmp/myagents-research/letta-ai-letta/tests/test_static_buffer_summarize.py`, `/tmp/myagents-research/letta-ai-letta/tests/test_secret.py`, `/tmp/myagents-research/letta-ai-letta/tests/test_crypto_utils.py`, and `/tmp/myagents-research/letta-ai-letta/tests/test_mcp_encryption.py`: verification of memory rendering, context accounting, prefix caching, summarization, secret handling, and MCP encryption.
- Repository docs note: there is no top-level `docs/` directory at the reviewed commit. I reviewed README, root policy/security docs, source-level docs/comments, and server/API code; generated Fern API artifacts were excluded as generated reference output.

## Excluded Paths

- `/tmp/myagents-research/letta-ai-letta/.git/`: VCS internals; exact reviewed commit captured separately.
- `/tmp/myagents-research/letta-ai-letta/.github/`, `/tmp/myagents-research/letta-ai-letta/.agents/`, and `/tmp/myagents-research/letta-ai-letta/.codex/`: CI, repo automation, and assistant-local instructions; not runtime memory/context architecture.
- `/tmp/myagents-research/letta-ai-letta/fern/openapi.json` and `/tmp/myagents-research/letta-ai-letta/fern/openapi-overrides.yml`: generated API spec/config output; REST router source was reviewed instead.
- `/tmp/myagents-research/letta-ai-letta/uv.lock` and `/tmp/myagents-research/letta-ai-letta/package-lock.json`: generated dependency lockfiles.
- `/tmp/myagents-research/letta-ai-letta/assets/`, `/tmp/myagents-research/letta-ai-letta/certs/`, `/tmp/myagents-research/letta-ai-letta/tests/data/`, and binary fixtures such as PDFs, images, pickles, and SQLite files: generated/binary/test fixture material, not architecture.
- `/tmp/myagents-research/letta-ai-letta/letta/local_llm/webui/` and UI-only local LLM presentation assets: frontend/UI surface; local model provider details were out of scope for memory architecture.
- `/tmp/myagents-research/letta-ai-letta/letta/llm_api/` provider-specific clients except where reached through agent loops/token counters: model-adapter breadth, not the stateful-memory design under review.
- `/tmp/myagents-research/letta-ai-letta/letta/client/`, `/tmp/myagents-research/letta-ai-letta/letta/cli/`, and `/tmp/myagents-research/letta-ai-letta/letta/openai_backcompat/`: SDK/CLI/backcompat wrappers; server and runtime internals were the relevant surfaces.
- `/tmp/myagents-research/letta-ai-letta/examples/`, `/tmp/myagents-research/letta-ai-letta/scripts/`, `/tmp/myagents-research/letta-ai-letta/sandbox/resources/`, `/tmp/myagents-research/letta-ai-letta/otel/`, and deployment compose files: examples, operational scaffolding, and observability/deployment material; sampled only when it clarified runtime boundaries.
- `/tmp/myagents-research/letta-ai-letta/alembic/` and `/tmp/myagents-research/letta-ai-letta/db/`: migrations and database scripts; ORM models were reviewed as the current schema source.
- `/tmp/myagents-research/letta-ai-letta/letta/personas/`, `/tmp/myagents-research/letta-ai-letta/letta/humans/`, and static prompt/persona examples: content samples, not memory architecture.
- `/tmp/myagents-research/letta-ai-letta/tests/performance_tests/`, `/tmp/myagents-research/letta-ai-letta/tests/configs/`, `/tmp/myagents-research/letta-ai-letta/tests/model_settings/`, and unrelated integration tests: lower-priority fixtures/performance/config coverage outside the assigned memory/context/tool-state review.
