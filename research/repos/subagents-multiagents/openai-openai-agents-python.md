# openai/openai-agents-python

- URL: https://github.com/openai/openai-agents-python
- Category: subagents-multiagents
- Stars snapshot: 26,498 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 9514473c234c8419b812b658157a5c3d4341713f
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong source of runtime patterns for multi-agent orchestration, handoff control, resumable approvals, MCP lifecycle, sessions, tracing, and tool error boundaries. It is a general agent SDK rather than an agentic coding system, so adopt patterns selectively instead of copying the framework shape.

## Why It Matters

This repository is a production-grade Python SDK for agent workflows where a runner coordinates agents, tools, handoffs, guardrails, sessions, tracing, MCP servers, sandbox runtime, and human approval pauses. It matters for agentic coding research because it shows concrete interfaces for isolating local application context from model-visible context, routing control between specialist agents, making tool approvals resumable, and preserving enough run state for streaming, retries, sessions, and interrupted runs.

The fit is conditional. The repo is not primarily about coding-agent collaboration, repository ownership, patch discipline, or test-driven development. Its value is in the execution machinery underneath those workflows: explicit runner state, handoff filtering, agent-as-tool nesting, MCP tool conversion, guardrail placement, trace topology, and careful error classification.

## What It Is

`openai-agents-python` packages the `openai-agents` Python library. The central objects are `Agent`, `Runner`, `RunConfig`, `RunContextWrapper`, `RunState`, tools, handoffs, sessions, guardrails, MCP servers, and tracing spans. An `Agent` carries instructions, model settings, tools, MCP servers, handoffs, guardrails, output schema, hooks, and tool-use behavior. The `Runner` repeatedly calls the current agent model, resolves model output into messages, tools, approvals, handoffs, or final output, and then either returns, switches agents, pauses, or loops.

The SDK supports two different multi-agent styles. A handoff transfers the conversation to another agent and makes that agent the current owner of the run. `Agent.as_tool()` exposes a nested specialist as a function tool, letting the original agent keep control after the nested run returns. That distinction is the most useful part for subagent design: delegation can either transfer ownership or produce a tool result.

## Research Themes

- Token efficiency: Uses tool search and deferred function-tool loading, session history limits, `session_input_callback`, `call_model_input_filter`, reasoning item ID policy, prompt cache key resolution, and `OpenAIResponsesCompactionSession`. The SDK exposes useful hooks for token trimming but does not provide a general budget planner or coding-specific context packer.
- Context control: Keeps `RunContextWrapper.context` local to Python callbacks, tools, hooks, guardrails, and approvals rather than passing it to the LLM. Handoff filters can rewrite what the receiving agent sees while preserving new items for session persistence. Sessions and server-managed continuation are treated as separate strategies to avoid duplicated history.
- Sub-agent / multi-agent: Handoffs are model-callable routing tools; only the first handoff in a turn is honored when multiple are emitted. Agents-as-tools run nested agents with separate tool context and approval state, then return a result to the caller. Dynamic handoff/tool enablement supports per-run routing decisions.
- Domain-specific workflow: The SDK gives domain teams agent definitions, hooks, tool wrappers, MCP servers, sandbox options, and tracing processors, but the core abstractions are intentionally domain-neutral. Coding-agent workflows would need additional policy around file ownership, verification, commits, and review gates.
- Error prevention: Uses strict schemas, duplicate tool-name checks, `UserError`, `ModelBehaviorError`, `ModelRefusalError`, `MaxTurnsExceeded`, `ToolTimeoutError`, guardrail tripwires, tool approvals, tool input/output guardrails, MCP retries, required-parameter validation, and configurable model-visible tool error formatting.
- Self-learning / memory: Provides session stores, OpenAI conversation-backed history, and response compaction. This is durable conversation memory, not autonomous skill learning or long-term self-improvement.
- Popular skills: Best patterns to reuse are handoff filters, resumable approval state, MCP server management, trace spans, agent-as-tool isolation, session compaction, and state-schema versioning.

## Core Execution Path

1. A caller invokes `Runner.run`, `Runner.run_sync`, or `Runner.run_streamed` with an `Agent`, input, optional `RunConfig`, optional session, optional server continuation identifiers, and optional `RunState` for resume.
2. The runner creates or restores `RunContextWrapper`, run state, usage accounting, trace context, task span, current agent, and optional sandbox runtime.
3. Session preparation merges stored history with the new turn, or a server conversation tracker prepares a provider-managed delta. The SDK avoids layering local sessions with `conversation_id`, `previous_response_id`, or `auto_previous_response_id`.
4. On the first turn of a new run, input guardrails run for the starting agent. Blocking guardrails complete before model execution; parallel guardrails may race with model/tool work and then cancel if a tripwire fires.
5. `run_single_turn` resolves the system prompt, prompt object, output schema, tools, MCP tools, handoffs, model settings, and filtered model input, then calls the model through retry logic that can rewind session/server tracker state.
6. Model output is converted into run items and plans: messages, reasoning, function tools, hosted tools, MCP list/call/approval items, shell/computer/apply-patch/custom tools, handoff calls, refusals, and final-output candidates.
7. Tool execution handles approval checks, pending interruptions, input guardrails, invocation, timeout/failure formatting, output guardrails, MCP callbacks, and concurrency limits.
8. If a handoff was selected, the runner invokes handoff callbacks, records handoff output, filters or nests input history, switches the current agent, and continues the loop. If final output was selected, output guardrails run for the final agent before returning.
9. The result saves new session items, carries interruptions and `RunState` when paused, records raw responses and generated items, finalizes tracing spans, and cleans up sandbox or tool resources.

## Architecture

The public API is intentionally small while the runtime internals are split by concern.

`src/agents/agent.py` defines the agent configuration surface: instructions, prompt, model settings, handoffs, tools, MCP servers, guardrails, output schema, hooks, and conversion to a tool. `src/agents/run.py` and `src/agents/run_internal/*` implement the loop, model calls, turn resolution, handoff execution, tool execution, session persistence, OpenAI conversation tracking, and prompt cache key handling.

Tools are modeled in `src/agents/tool.py` and include local function tools, hosted tools, local/runtime shell and patch tools, computer tools, custom tools, tool search, and hosted MCP tools. Local MCP servers live under `src/agents/mcp/*`, where transports connect/list/call tools and `MCPUtil` converts MCP tools into `FunctionTool` objects.

Memory is separated under `src/agents/memory/*` and `src/agents/run_internal/session_persistence.py`. Sessions are an async protocol with built-in SQLite, OpenAI Conversations, and compaction wrappers. Tracing is separated under `src/agents/tracing/*` with trace/span context based on context variables and processors/exporters for backend or custom destinations.

`RunState` is the durable pause/resume boundary. It serializes current turn, current agent, original input, model responses, generated items, session items, guardrail results, current step, reasoning policy, trace state, sandbox state, and context metadata. It is schema-versioned and conservative about custom context serialization.

## Design Choices

- Handoff and agent-as-tool are distinct delegation primitives. Handoff transfers conversation ownership; agent-as-tool nests a specialist and returns control to the caller.
- Handoffs are exposed as tool calls to the model, but execute through a dedicated handoff pipeline rather than the normal function-tool pipeline.
- Only the first handoff emitted in a turn is executed. Additional handoff calls are converted to ignored tool outputs and traced as errors.
- Local context is intentionally not model-visible. `RunContextWrapper` gives tools/hooks/guardrails application state, usage accounting, approvals, current turn input, and current tool input without adding that data to the prompt.
- Handoff filters operate on structured `HandoffInputData`, separating previous input history, pre-handoff generated items, current-turn items, optional next-agent input items, and run context.
- Server-managed conversations are not mixed with local sessions, and handoff input filters are rejected for server-managed conversation mode because the SDK cannot rewrite remote history safely.
- MCP tool names can be server-prefixed with deterministic safe names to avoid collisions. The SDK also detects duplicate function/Codex tool names before model execution.
- Tool failures can either raise exceptions or become model-visible error strings. This is configurable globally, per agent MCP config, per server, and per tool.
- Guardrail placement is explicit: input guardrails only on the first agent, output guardrails only on the final agent, and tool guardrails only around custom function tools.
- Tracing captures task, turn, agent, model response/generation, function, handoff, guardrail, and MCP tool-list spans, with a run-level sensitive-data flag.

## Strengths

- Clear state machine: each turn resolves to final output, handoff, tool work, interruption, or another model call.
- Strong context separation: application context, model input, session history, tool input, and approval state are represented separately.
- Resumable human-in-the-loop design: tool approvals become interruption items, `RunState` can be approved/rejected, and nested agent-as-tool calls preserve pending nested results.
- Mature MCP handling: multiple transports, hosted/local distinction, cache invalidation, dynamic filters, approval policies, retries, strict-schema conversion, failure formatting, and tool-name collision handling.
- Useful session machinery: session input customization, history limits, deduplication, orphan tool-call cleanup, retry rewind, and compaction wrapper.
- Trace model is reusable: spans line up with the runner's operational boundaries and allow sensitive model/tool payloads to be disabled.
- Error taxonomy is more precise than a generic exception surface, especially around invalid model outputs, user configuration mistakes, refusals, max-turn exits, tool timeouts, and guardrail tripwires.

## Weaknesses

- The framework is broad. Copying the full abstraction set would add more surface area than an agentic coding lab needs.
- Guardrail defaults require care. Parallel input guardrails reduce latency but can allow token use or tool side effects before a tripwire cancels the run.
- Agent-level guardrails do not cover every subagent boundary. Input guardrails only run on the first agent, output guardrails only on the final agent, and tool guardrails do not apply to handoffs, hosted tools, built-in execution tools, or agent-as-tool calls.
- Handoff filtering is incompatible with server-managed conversation state, and nested handoff history is still opt-in beta.
- `Agent.clone()` is shallow for many fields. That is ergonomic, but mutable tool/handoff/list state can surprise callers who expect isolation.
- Model-visible tool error strings are good for recovery but can hide operational failures if the caller treats any final answer as success.
- Custom context serialization for `RunState` requires explicit serializers or mappings. That is safer than importing arbitrary classes, but it means resume behavior is only as good as the application-provided serializer.

## Ideas To Steal

- Represent the runner as an explicit turn state machine with typed next-step outcomes instead of scattered loop flags.
- Keep local application context out of model input and pass it only to tools, hooks, guardrails, approval callbacks, and serializers.
- Split handoff history into previous input, pre-handoff generated items, current-turn items, and optional next-agent input, so filtering does not corrupt persisted session history.
- Treat tool approval as a first-class resumable run item with approve/reject APIs and scoped approval keys.
- Give agent-as-tool calls a fresh nested tool context while mirroring explicit approvals from the parent run.
- Store run state with a schema version, version summary, trace state, current agent identity, current step, generated items, and conservative context serialization.
- Add an MCP manager that exposes active servers, failed servers, strict vs best-effort connection behavior, dynamic tool filtering, and safe tool-name prefixing.
- Build traces around task, turn, agent, handoff, guardrail, model, function, and MCP boundaries, and make sensitive input/output capture a run-level decision.
- Make session preparation return both model input and the exact new items to persist, then support best-effort tail rewind on retry.

## Do Not Copy

- Do not import the entire SDK-style framework into this project; the research lab needs narrower, coding-specific orchestration.
- Do not rely on parallel guardrails when filesystem writes, external calls, or paid model/tool calls must be blocked before execution.
- Do not let model-visible tool error messages count as successful verification without a separate success policy.
- Do not copy server-managed conversation limitations unless the target system has the same provider assumptions and remote history constraints.
- Do not use shallow cloning for mutable agent configuration unless shared-state behavior is documented and tested.
- Do not treat MCP dynamic filter failures as merely logging concerns in security-sensitive workflows; fail-closed behavior should be explicit in policy.

## Fit For Agentic Coding Lab

This is a strong conditional candidate for the `subagents-multiagents` category. It is most useful as a pattern source for specialist delegation, explicit handoff ownership, nested subagent tool calls, approval interruptions, MCP lifecycle control, session compaction, context isolation, and traceable execution. It is less useful as a direct product model because it does not encode repository ownership, patch review, shell-command policy, test verification, memory-note workflows, or multi-worker note isolation.

The best adaptation would be a smaller runner with the same control principles: current worker, typed next step, explicit handoff target, filtered context handoff, local-only project context, approval/resume items, per-tool error policy, trace spans, and session compaction. Coding-specific policy should sit above it: owned paths, allowed commands, destructive-action approval, test evidence, and final-report requirements.

## Reviewed Paths

- `README.md`
- `AGENTS.md`
- `pyproject.toml`
- `docs/running_agents.md`
- `docs/guardrails.md`
- `docs/handoffs.md`
- `docs/tools.md`
- `docs/mcp.md`
- `docs/sessions/index.md`
- `docs/tracing.md`
- `src/agents/agent.py`
- `src/agents/run.py`
- `src/agents/run_config.py`
- `src/agents/run_context.py`
- `src/agents/run_state.py`
- `src/agents/result.py`
- `src/agents/exceptions.py`
- `src/agents/guardrail.py`
- `src/agents/tool.py`
- `src/agents/tool_guardrails.py`
- `src/agents/run_internal/run_loop.py`
- `src/agents/run_internal/turn_resolution.py`
- `src/agents/run_internal/tool_execution.py`
- `src/agents/run_internal/session_persistence.py`
- `src/agents/run_internal/oai_conversation.py`
- `src/agents/run_internal/prompt_cache_key.py`
- `src/agents/handoffs/__init__.py`
- `src/agents/handoffs/history.py`
- `src/agents/mcp/server.py`
- `src/agents/mcp/manager.py`
- `src/agents/mcp/util.py`
- `src/agents/memory/session.py`
- `src/agents/memory/sqlite_session.py`
- `src/agents/memory/openai_conversations_session.py`
- `src/agents/memory/openai_responses_compaction_session.py`
- `src/agents/tracing/create.py`
- `src/agents/tracing/context.py`
- `src/agents/tracing/span_data.py`
- `src/agents/tracing/processors.py`
- `src/agents/tracing/traces.py`

## Excluded Paths

- Locale/generated documentation under translated docs directories.
- Voice, realtime, UI, browser, and audio examples except where top-level docs referenced shared runner concepts.
- Sandbox provider implementation details beyond `RunConfig` and runner lifecycle touchpoints.
- Optional storage backends beyond the session protocol, SQLite, OpenAI Conversations, and compaction wrapper.
- CI, packaging metadata, changelog, lockfile, images, screenshots, and media assets.
- Example applications not needed to validate agents, handoffs, tools, guardrails, tracing, sessions, MCP, context isolation, and error handling.
