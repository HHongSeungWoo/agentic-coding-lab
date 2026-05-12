# langchain-ai/deepagents

- URL: https://github.com/langchain-ai/deepagents
- Category: agent-support-systems
- Stars snapshot: 22,652 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 5b8476c8ad4db2f696506b47b2b13608de0cd47c
- Reviewed at: 2026-05-12T11:52:44+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for a LangGraph-based agent harness with planning tools, subagents, context offload, skills, memory, MCP loading, and CLI safety gates. Use it as a pattern source for middleware assembly and tool-boundary design, not as a drop-in because the CLI/local-shell surface is broad and the security model depends heavily on sandboxing and HITL.

## Why It Matters

Deep Agents is one of the clearest open-source implementations of the "coding-agent harness" stack: todo planning, virtual filesystem, shell execution, subagent delegation, skills, memory, summarization, and approval gates are composed as explicit middleware around a LangGraph agent. The repo is especially relevant to Agentic Coding Lab because it shows how to turn prompt-only agent behavior into reusable runtime structure while still exposing familiar coding-agent features.

Its core claim is practical rather than novel: many productive agents are not just model loops, but model loops plus a disciplined set of tools, context stores, subagents, prompts, and verification paths. The implementation makes those boundaries visible enough to inspect and copy selectively.

## What It Is

The repo is a Python monorepo with these relevant packages:

- `libs/deepagents`: SDK package. Main API is `create_deep_agent`, which returns a compiled LangGraph agent.
- `libs/cli`: prebuilt terminal coding agent using the SDK, a local LangGraph dev server, MCP, memory, skills, HITL, shell allow lists, and optional remote sandboxes.
- `libs/evals`: behavioral eval suite for real-LLM trajectories, tool use, memory, todos, file operations, summarization, and external benchmarks.
- `examples`: working agents that show deep research, content writing, deployed coding agents, async subagents, MCP docs agents, and domain-specific skill/subagent layouts.

The SDK default backend is `StateBackend`, so file state is in LangGraph state and `execute` is unavailable unless the caller supplies a backend implementing `SandboxBackendProtocol`. The CLI chooses a broader default for local coding: it uses `LocalShellBackend` in local mode, wraps it in `CompositeBackend`, and relies on HITL or shell allow lists to control side effects.

## Research Themes

- Token efficiency: Strong. Sync subagents isolate context and return only final reports; large tool results and huge human messages are offloaded into backend files; summarization replaces old messages with a summary and a pointer to full history. Skills use progressive disclosure by listing metadata first and loading full `SKILL.md` only when needed.
- Context control: Strong. Context is assembled from base prompt, caller prompt, harness profile suffixes, memory files, skill metadata, local project detection, MCP inventory, tool descriptions, and summarization events. The system has multiple explicit storage lanes: `files`, `/large_tool_results/`, `/conversation_history/`, `memory_contents`, `skills_metadata`, and `async_tasks`.
- Sub-agent / multi-agent: Strong. The `task` tool launches ephemeral inline subagents with isolated message windows. Async subagents use remote Agent Protocol/LangGraph servers and expose start/check/update/cancel/list tools.
- Domain-specific workflow: Medium-high. Skills, memory files, custom subagents, MCP servers, and examples support domain packaging. The core SDK does not natively load subagents from files, but the CLI and examples do.
- Error prevention: Medium-high. The CLI has HITL approval for side-effecting tools, shell allow lists for headless runs, MCP config validation/trust fingerprints, URL/Unicode warning display, test suites, evals, and threat models. The SDK itself still follows a "trust the LLM, enforce at tool/backend boundary" model.
- Self-learning / memory: Medium. `MemoryMiddleware` loads `AGENTS.md` files and prompts the agent to update them, but memory is file-based and prompt-mediated rather than a typed memory manager.
- Popular skills: Skills are first-class via `SkillsMiddleware`, with Agent Skills style frontmatter and path-based progressive disclosure. The CLI ships built-in skills such as skill creation and memory helpers, and examples include planning, code-review, blog-post, social-media, and coding-preferences skills.

## Core Execution Path

SDK path:

1. `create_deep_agent` resolves the model, selects a harness profile, validates excluded middleware, applies tool-description overrides, and chooses `StateBackend()` unless a backend is provided.
2. It preprocesses subagents. Declarative sync subagents get their own middleware stack: `TodoListMiddleware`, `FilesystemMiddleware`, summarization, patch-tool-call middleware, optional skills, user middleware, profile middleware, tool exclusion, prompt caching, and optional inherited HITL. Compiled subagents are used as-is. Async subagents are routed separately.
3. If no sync subagent named `general-purpose` exists, a default general-purpose subagent is auto-added unless the active harness profile disables it.
4. Main-agent middleware is assembled in order: todo list, optional skills, filesystem, sync subagents, async subagents, summarization, patch-tool-calls, user middleware, harness profile middleware, tool exclusion, Anthropic prompt caching, optional memory, optional HITL.
5. The final system prompt is caller `USER` prompt first, then base or profile-custom prompt, then profile suffix. The graph is created with LangChain `create_agent` and configured with a high recursion limit plus LangSmith integration metadata.

CLI path:

1. `server_graph.make_graph` reads environment-backed server config, initializes model settings, loads built-in tools (`fetch_url`, optional Tavily `web_search`), resolves MCP tools, optionally creates a sandbox, loads async subagents from config, then calls `create_cli_agent`.
2. `create_cli_agent` adds CLI middleware: configurable model, token state, optional `ask_user`, memory, skills, local context detection, optional shell allow-list middleware, and a manual `compact_conversation` tool.
3. Local mode uses `LocalShellBackend` when shell is enabled, or `FilesystemBackend` without shell. Remote sandbox mode uses the sandbox backend. Local mode wraps the backend in `CompositeBackend` with `/large_tool_results/` and `/conversation_history/` routed to temp virtual filesystems.
4. HITL is enabled unless auto-approve or shell allow-list mode disables LangGraph interrupts. Gated tools include `execute`, file writes/edits, web search, URL fetch, `task`, async subagent launch/update/cancel, and compact conversation.

## Architecture

The central architecture is middleware composition around LangChain/LangGraph, not a custom agent runtime. Built-in behavior is delivered by middleware that adds tools, edits the system prompt, mutates private state, or wraps tool/model calls.

Planning is implemented through `TodoListMiddleware` and prompt instructions rather than a separate planner. The SDK base prompt tells the agent to understand, act, and verify. The CLI prompt adds a stricter coding workflow, todo guidance, file-reading rules, git safety, dependency rules, and debugging rules. Example coding agents add a Plan -> Implement -> Review -> Deliver workflow and a planning skill that instructs `write_todos`.

Subagents are two systems:

- Sync subagents: `_build_task_tool` maps `subagent_type` to a runnable. It passes a new state dict with excluded keys removed and replaces `messages` with one `HumanMessage(description)`. It returns a single `ToolMessage` containing either `structured_response` JSON or the final subagent message. Non-excluded state updates can merge back to the parent.
- Async subagents: `AsyncSubAgentMiddleware` builds five tools: `start_async_task`, `check_async_task`, `update_async_task`, `cancel_async_task`, and `list_async_tasks`. It tracks tasks in `async_tasks`, stores thread/run IDs, fetches live status from a LangGraph server, and updates state through reducers.

Context management is layered:

- `FilesystemMiddleware` exposes `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`, and conditionally `execute`.
- Large tool results can be stored under `/large_tool_results/<tool_call_id>` and replaced with previews.
- Oversized human messages can be stored under `/conversation_history/<uuid>.md` and replaced with previews.
- `SummarizationMiddleware` stores full conversation history under `/conversation_history/{thread_id}.md`, inserts a summary `HumanMessage`, and keeps recent messages.
- `MemoryMiddleware` loads configured AGENTS.md files into the system prompt and marks memory state private.
- `SkillsMiddleware` scans skill directories, parses `SKILL.md` frontmatter, lists skill metadata in prompt, and tells the agent to read full skill files on demand.
- `LocalContextMiddleware` runs a static bash detection script inside the active backend to inject current directory, git, package manager, runtime, test command, files, and MCP server inventory.

Tool boundaries are backend-driven. `BackendProtocol` defines file storage and batch upload/download. `SandboxBackendProtocol` adds `execute`. `CompositeBackend` routes file paths by prefix while execution always delegates to the default backend. `FilesystemPermission` rules are enforced by `FilesystemMiddleware` for file tools, but not as a backend-level security policy. Permissions are intentionally rejected when a backend provides command execution unless all permission paths are scoped to composite routes, because shell can bypass file-tool permissions.

## Design Choices

- Middleware is the unit of feature composition. This keeps features like memory, skills, filesystem tools, subagents, summarization, and HITL independently testable.
- The default general-purpose subagent makes delegation available without user configuration, but harness profiles can disable it or alter descriptions/prompts.
- Subagents inherit parent tools by default, which improves convenience but increases blast radius unless explicitly narrowed.
- Private state keys prevent parent memory/skills/todos/messages from leaking wholesale into subagents.
- Tool output management uses files and previews rather than trying to keep everything in chat history.
- The CLI separates local user process from the agent graph by running a local LangGraph server and a RemoteAgent client. This supports streaming, session persistence, and deployment parity, but adds local server attack surface.
- MCP project configs are all gated when untrusted, including remote servers, because project-controlled remote MCP config can cause SSRF or environment-variable header exfiltration during discovery.
- The code favors explicit warnings over hidden safety claims. `LocalShellBackend` and `FilesystemBackend` document that virtual paths are not OS sandboxing.

## Strengths

- Clear, inspectable harness assembly around a standard LangGraph agent.
- Good context-control primitives: summaries, offloaded tool results, offloaded human messages, file-backed memory, skill metadata, local context, and subagent isolation.
- Practical subagent ergonomics: default general-purpose subagent, custom sync subagents, compiled runnables, async remote subagents, structured-response support, and parallel task-tool guidance.
- Strong CLI safety UX compared with bare tool calling: custom approval descriptions, Unicode/URL warnings, project MCP trust fingerprints, tool filters, shell allow lists, and non-interactive mode behavior.
- Extensive tests across SDK middleware, backends, permissions, subagents, skills, summarization, local shell, CLI config, MCP, ask-user, UI widgets, and integration paths.
- Examples show concrete agent-support patterns rather than only abstract docs: deep research, deployed coding agent, content builder with memory/skills/subagents, async subagent server, and MCP docs agent.

## Weaknesses

- Planning is mostly prompt plus todo tool. There is no typed plan artifact, plan validator, dependency graph, or enforced plan-review gate in the SDK.
- Sync subagents return final output only. This is good for context hygiene, but poor when the parent needs an auditable trace of intermediate decisions.
- Tool security relies on backend and CLI policy. The SDK default is conservative, but the CLI local mode enables `LocalShellBackend`, which runs `subprocess.run(..., shell=True)` with no isolation.
- `FilesystemPermission` is tool-level and explicitly not backend-level. It cannot safely constrain shell execution.
- Memory files are injected as trusted prompt content and have no explicit size/sanitization layer. The memory prompt also encourages immediate persistent updates, which may be too aggressive.
- Remote async subagent outputs and MCP tool results re-enter the main agent context without prompt-injection filtering.
- The CLI local LangGraph server uses localhost and no auth in the documented threat model; this is acceptable for a local developer tool but not a production control plane.
- The monorepo surface is large. Adopting it wholesale would import UI, server, MCP, sandbox, provider, and eval complexity that many agent-support systems do not need.

## Ideas To Steal

- Use an ordered middleware stack as the explicit harness contract. Make every feature state what tools it adds, what prompt text it appends, and what state keys it owns.
- Protect required scaffolding from profile-level exclusion. Deep Agents refuses to exclude core filesystem/subagent middleware where that would silently break guarantees.
- Make subagent state isolation explicit with an excluded-state-key set, and return compact final reports instead of full trajectories by default.
- Pair context compaction with durable history pointers. A summary alone loses auditability; summary plus `/conversation_history/{thread_id}.md` keeps recovery possible.
- Use `CompositeBackend` style path routing for artifacts: one default workspace plus separate roots for large tool results, conversation history, or memories.
- Treat skill loading errors as untrusted diagnostics in the prompt. This prevents malformed skill paths/errors from becoming instructions.
- Gate project MCP configs by content fingerprint and gate remote configs too, not only stdio process configs.
- Provide both interactive HITL and headless shell allow lists. They solve different verification problems.
- Write examples as runnable harness recipes: one for coding, one for research, one for async subagents, one for memory/skills/subagents.

## Do Not Copy

- Do not copy local shell execution without an OS-level sandbox, strict approvals, and environment-secret policy. `LocalShellBackend` is intentionally unrestricted.
- Do not depend on prompt instructions as the main safety boundary for file, shell, web, or MCP access.
- Do not make subagents inherit all parent tools by default for high-risk domains. Prefer explicit tool lists for sensitive roles.
- Do not inject long-term memory as fully trusted instructions without size limits, provenance, and a way to distinguish user preference from project instruction.
- Do not build a local unauthenticated HTTP control plane unless the deployment is strictly local and ephemeral.
- Do not import the full CLI architecture when a narrower SDK middleware or artifact pattern is enough.

## Fit For Agentic Coding Lab

Fit is conditional but high-signal. Deep Agents is a reusable architecture reference for agent support systems, especially for:

- planning via todo tools plus stronger prompt contracts;
- subagent dispatch and context isolation;
- progressive skill loading;
- filesystem-backed context and artifact routing;
- human approval and shell policy;
- MCP trust and tool filtering;
- eval-oriented verification.

For Agentic Coding Lab, the best adoption path is not to wrap the whole framework. Instead, extract patterns: middleware contracts, subagent state isolation, artifact roots for large outputs/history, project trust fingerprints, HITL descriptions, and eval categories. Then add stronger lab-specific policy where Deep Agents is intentionally permissive: typed plans, narrower subagent tools, memory provenance, and sandbox-first execution.

## Reviewed Paths

- `README.md` and `libs/deepagents/README.md`: product claims, default included features, SDK/CLI boundary, and security note.
- `libs/deepagents/deepagents/__init__.py`: public API surface.
- `libs/deepagents/deepagents/graph.py`: main execution path, middleware ordering, prompt assembly, default subagent insertion, backend defaults, HITL and profile handling.
- `libs/deepagents/deepagents/middleware/subagents.py`: sync `task` tool, subagent state filtering, final-message return, structured-response behavior, task prompt.
- `libs/deepagents/deepagents/middleware/async_subagents.py`: remote/background subagent lifecycle, `async_tasks` state, start/check/update/cancel/list tools.
- `libs/deepagents/deepagents/middleware/filesystem.py`: file and shell tool definitions, permission checks, large tool result offload, human-message offload, execute-tool exposure.
- `libs/deepagents/deepagents/middleware/skills.py`: skill discovery, frontmatter validation, progressive disclosure prompt, load warnings.
- `libs/deepagents/deepagents/middleware/memory.py`: AGENTS.md loading and prompt injection.
- `libs/deepagents/deepagents/middleware/summarization.py`: automatic and tool-triggered compaction, history offload, summary event state, tool-argument truncation.
- `libs/deepagents/deepagents/backends/protocol.py`, `state.py`, `filesystem.py`, `local_shell.py`, `sandbox.py`, and `composite.py`: storage/execution contracts, state backend, direct filesystem backend, unrestricted local shell, base sandbox file operations, path routing.
- `libs/deepagents/deepagents/profiles/harness/harness_profiles.py`: harness profile customization and required-scaffolding guardrails.
- `libs/cli/README.md`, `deepagents_cli/agent.py`, `server_graph.py`, `system_prompt.md`, `tools.py`, `local_context.py`, `mcp_tools.py`, `mcp_trust.py`, `subagents.py`, and `ask_user.py`: CLI coding-agent stack, prompt, HITL, MCP trust, project context, custom subagents, and user-question tool.
- `libs/deepagents/tests/unit_tests/test_graph.py`, `test_subagents.py`, `test_async_subagents.py`, `test_permissions.py`, middleware tests for summarization and skills, plus CLI tests for agent prompts, MCP tools, and MCP trust: behavioral coverage for architecture claims.
- `libs/evals/README.md`: eval suite intent and trajectory-scoring scope.
- `libs/deepagents/THREAT_MODEL.md` and `libs/cli/THREAT_MODEL.md`: documented trust boundaries and known risks. These files were generated for an older commit, so I used them as supporting context, not as exact current-code authority.
- `examples/deploy-coding-agent`, `examples/deep_research`, `examples/content-builder-agent`, and `examples/async-subagent-server`: concrete recipes for planning skills, code review, research delegation, memory/skills/subagents, MCP docs config, sandbox deploy, and remote async subagent pattern.
- `libs/deepagents/pyproject.toml` and `libs/cli/pyproject.toml`: package versions, dependencies, and test/lint tooling.

## Excluded Paths

- `libs/cli/frontend/` and `libs/cli/deepagents_cli/deploy/frontend_dist/`: UI/static bundles. Relevant to product packaging, not to agent harness architecture.
- `libs/acp/`: separate Agent Client Protocol package. Skipped because the assigned focus was Deep Agents SDK/CLI harness, not ACP serving.
- `libs/repl/` and most `libs/partners/`: separate integration packages and provider-specific backends. I reviewed core backend abstractions and local/base sandbox behavior instead of every partner implementation.
- `libs/evals/tests/evals/data/` and benchmark sample JSON: generated/fixture data for evals. Useful for running evals, not for understanding harness design.
- `uv.lock`, `package-lock.json`, release metadata, changelogs, and generated release notes: dependency snapshots and release artifacts, not architecture.
- Binary/media assets such as `.png`, `.gif`, `.svg`, and `.ipynb`: UI screenshots, diagrams, notebooks, and packaged examples. I read the adjacent Markdown/Python files where architecture was described.
- Example folders not central to the assigned themes, such as `examples/nvidia_deep_agent`, `examples/text-to-sql-agent`, and `examples/rlm_agent`: domain demos. I sampled representative examples that covered planning, subagents, context, tools, and coding-agent applicability.
- Most Textual widget files under `libs/cli/deepagents_cli/widgets/`: UI rendering details. I inspected approval/tool-boundary code paths rather than UI-only presentation.
