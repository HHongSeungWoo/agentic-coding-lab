# emcie-co/parlant

- URL: https://github.com/emcie-co/parlant
- Category: agent-support-systems
- Stars snapshot: 18,068 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 7909239ad4bd7cb235fdd6e7da4fe46da0528356
- Reviewed at: 2026-05-12T11:54:49+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal guidance-control runtime for conversational agents. The useful pieces are the rule matching pipeline, deterministic relationship resolver, guideline-gated tools, tool-result reevaluation, context pruning, response analysis, and strict/composited canned response modes. Fit is conditional because the product is a customer-facing agent framework, not a coding agent system, and its safety model still depends heavily on LLM judgments.

## Why It Matters

Parlant is an interaction-control harness for agents that need predictable behavior under many business instructions. Instead of putting all instructions in one system prompt, it models behavior as guidelines, relationships, journeys, tools, context variables, glossary terms, capabilities, and canned responses, then decides at runtime which subset belongs in the current response.

That makes it relevant to Agentic Coding Lab because coding agents face the same control problem: many repo rules, tool constraints, workflow policies, and conflict cases cannot all be treated as flat prompt text. Parlant shows one concrete pattern for matching rules, resolving conflicts, gating tool calls, preserving only relevant context, and verifying whether selected guidance was followed.

## What It Is

Parlant is a Python framework for building customer-facing conversational agents. Its core behavioral primitive is the guideline: a natural-language condition plus an optional action. Guidelines can be ordinary instructions, observational conditions, journey-derived workflow states, tool-enabling rules, or transient guidance returned by tools.

The engine combines probabilistic LLM-based matching with deterministic post-processing. LLM batches decide which guideline conditions apply, which tool arguments are available, and whether a response followed selected actions. The `RelationalResolver` then applies dependencies, priorities, numerical priority, and entailment rules to produce the final active guidance set. Tools are not exposed as a global menu; they are associated with specific matched guidelines. Message generation then receives a narrowed context pack plus ordinary guidelines, tool insights, glossary terms, canned response candidates, and missing/invalid tool data.

## Research Themes

- Token efficiency: Parlant is not primarily a token-saving project, but it avoids dumping the full policy corpus into every prompt. It prunes low-probability journeys, batches guideline matching, retrieves relevant glossary terms and capabilities, sends only matched guidelines to message generation, and lets tool results have response-only or session lifespan.
- Context control: Strong. The engine builds typed prompt sections for agent, customer, context variables, glossary, capabilities, interaction history, staged tool events, guidelines, and tool insights. Relationship resolution narrows conflicts before generation, and canned response modes add another output boundary.
- Sub-agent / multi-agent: Limited. There is no coding-style subagent system. Tool services, plugins, OpenAPI tools, and MCP servers act as external execution surfaces, while hooks and planners provide extension points inside one engine.
- Domain-specific workflow: Strong for customer support SOPs. Journeys model conversational state diagrams, while observational guidelines and relationships encode process gates. The pattern maps well to coding workflows such as triage, implementation, verification, and handoff.
- Error prevention: Strong at the policy layer. The system has dependencies, exclusions, priority, disambiguation, parameter source constraints, enum validation, missing/invalid data reporting, response analysis, and strict canned responses. It does not replace deterministic code verification.
- Self-learning / memory: Narrow. Session state records applied guideline IDs and journey paths, and context variables can refresh external facts. There is no autonomous long-term learning loop in the reviewed control path.
- Popular skills: Not a skill-pack repo. Useful transferable "skills" are policy matching, conflict resolution, tool gating, tool-result reevaluation, strict response composition, and traceable guidance adherence.

## Core Execution Path

`AlphaEngine.process()` loads the agent, customer, session, and interaction history, then exits early if the session is in manual mode. `_initialize_response_state()` fetches context variables, glossary terms, and capabilities. A planner then drives one or more preparation iterations before the final response.

In the first preparation iteration, `_load_matched_guidelines_and_journeys()` retrieves enabled guidelines and active journeys, prunes the journey graph, runs `GuidelineMatcher.match_guidelines()`, optionally re-runs matching for activated low-probability journeys, converts journey nodes into matched guidelines, and passes the result through `RelationalResolver.resolve()`. The engine splits ordinary matches from tool-enabled matches, calls `ToolEventGenerator.infer_tool_calls()`, lets the plan filter or reorder calls, executes the selected tools, emits tool events, and reloads glossary terms after tool execution.

Additional preparation iterations happen when tool results require reevaluation. `_load_additional_matched_guidelines_and_journeys()` finds guidelines marked by `reevaluate_after(tool)`, matches them against the new tool insight, resolves relationships again, and may trigger more tools until the plan is prepared to respond or the maximum iteration count is reached.

Before generation, the engine injects missing and invalid tool-insight metadata, converts tool-returned transient guidelines into synthetic `GuidelineMatch` objects, resolves relationships once more, invokes guideline and journey handlers, and updates session labels. Message generation uses either the normal generator or the canned response generator depending on the agent and active guideline composition modes. After emitting messages, `_add_agent_state()` runs response analysis so applicable actions can be marked as applied and future matching can treat them differently.

## Architecture

The repo follows a hexagonal shape documented in `CLAUDE.md`: `core` contains domain objects and ports, `adapters` contain persistence and provider implementations, and `api` exposes HTTP/SDK surfaces. The reviewed guidance-control path is concentrated under `src/parlant/core/engines/alpha`.

Key components:

- `AlphaEngine`: orchestration for context loading, planning, guideline matching, tool execution, generation, and response analysis.
- `GuidelineMatcher`: groups guidelines by strategy and runs generic, custom, low-criticality, disambiguation, previously-applied, and journey-node matching batches.
- `RelationalResolver`: deterministic resolver for dependencies, priorities, numerical priority, entailment, tags, journeys, and traceable activation/deactivation reasons.
- `ToolEventGenerator` and `ToolCaller`: turn matched guideline-tool associations into tool-call inference, execution, event emission, and tool insight storage.
- `PromptBuilder`: creates structured prompt sections and censors or adapts events so generation sees tool result data but not hidden metadata.
- `MessageGenerator` and `CannedResponseGenerator`: generate free-form replies, composited canned replies, or strict canned-response-only replies.
- Tool services: local, SDK/plugin, MCP, and deprecated OpenAPI integrations behind `ServiceRegistry`.

The files named "policy" are not business policy engines. `optimization_policy.py` controls batch sizes, embedding cache use, and retry temperatures; `perceived_performance_policy.py` controls preamble/typing delays; `nlp/policies.py` provides retry wrappers. Behavioral policy is implemented through guidelines, relationships, journeys, tools, and composition modes.

## Design Choices

Guidance is matched before generation instead of being appended wholesale to the final prompt. This makes the system a runtime context selector, not just a prompt template.

Rules can be actionless. Observational guidelines establish circumstances, unlock dependencies, and help journey traversal without adding direct response instructions.

Probabilistic matching is followed by deterministic resolution. Once candidate rules are selected, dependencies, priorities, tag rules, journey rules, and entailment are handled by code with explicit resolution events.

Tools are guideline-scoped. A tool can only be considered when its associated guideline matched, which gives the engine a smaller and more explainable tool boundary than a global tool list.

Tool results can alter control flow. `ToolResult` can set session/response lifespan, switch the session to manual mode, provide canned response fields, and inject transient guidelines. Reevaluation relationships let new facts trigger another guideline matching pass before response generation.

Output control has levels. Fluid mode allows normal generation, composited mode rewrites using canned candidates, and strict mode returns only approved canned responses or no match. The effective mode is the most restrictive one across the agent and active guidelines.

Journey pruning is aggressive. The engine uses semantic relevance and active journey continuity to reduce workflow context, with a second pass for low-probability journeys that become activated. This saves context but can miss parallel workflows if retrieval fails.

## Strengths

The guidance-control path is explicit and inspectable. There are named stages for context loading, rule matching, relationship resolution, tool gating, reevaluation, composition, and response analysis.

Relationship semantics are unusually rich. Dependencies support AND/OR and tag targets; priorities work across guidelines and journeys; entailment can activate related guidance; numerical priority can enforce a highest-priority-only subset.

Tool boundaries are practical. Tool parameters carry source constraints, significance, examples, enum choices, adapters, precedence, and hidden flags. Missing or invalid data becomes structured insight for the response rather than silent hallucinated parameters.

Tool-result reevaluation is a strong pattern. The system can run a tool, use its result to activate more guidance, and only then compose the final answer.

Strict canned-response mode is a useful safety layer for regulated text, sensitive handoffs, and fields that must come from tools rather than generation.

Tests cover important policy machinery. The relational resolver test suite exercises priorities, dependencies, tags, journeys, cascading filters, entailment, and trace reasons; SDK/API tests cover tools, reevaluation, composition modes, canned fields, and manual mode behavior.

## Weaknesses

The first matching pass is still model judgment. Guideline applicability, tool-call applicability, and response adherence are prompt-based and retried with temperatures, not formally verified.

The domain is customer conversation. Coding-agent concerns such as file mutation policy, sandbox approval, repository ownership boundaries, static analysis, build/test execution, and patch safety are not first-class.

Tool services are broad execution surfaces. Local, plugin, MCP, and OpenAPI services are extensible, but a coding-agent adaptation would need stricter allowlists, permissions, provenance, and sandbox controls.

The response generator's verification is self-revision, not external validation. It checks facts, guideline adherence, and hallucination through LLM critique, which is useful but weaker than running tests or typecheckers.

Journey pruning can hide relevant process state. `top_k=1` low-probability journey pruning is context-efficient, but a coding workflow may need multiple simultaneous tracks such as implementation, migration, security review, and release notes.

Strict canned-response quality depends on curated templates and tool-provided fields. Without those assets it can degrade to no-match or fall back in non-strict modes.

The repository surface is large. UI assets, generated bundles, adapters, examples, and product API layers add audit cost around the smaller guidance-control core.

## Ideas To Steal

Use a pipeline shaped like `match rules -> resolve relationships -> gate tools -> execute tools -> reevaluate rules -> compose response -> analyze adherence`.

Model repo instructions as typed guidelines with condition/action fields instead of a flat prompt block. Keep observational conditions separate from actionable instructions.

Add first-class relationship records for dependency, priority, entailment, disambiguation, and tag-targeted rules. Emit traceable activation/deactivation reasons so an agent can explain why a rule applied or lost.

Gate tools through matched rules. A shell command, MCP tool, web call, or file edit should become available because a current policy allowed it, not because every tool is globally present.

Let tool results carry control metadata: response-only vs session lifespan, manual handoff, approved response fields, and transient guidance for the immediate turn.

Track missing and invalid tool parameters with precedence. This maps well to coding agents that must ask for a branch name, credential, deployment target, or destructive-action approval before acting.

Use strict composition modes for risky outputs such as commit messages, PR summaries, release notes, user-facing migration warnings, or regulated support replies.

Run post-response analysis to mark instructions as satisfied, but pair it with deterministic verification for code changes.

## Do Not Copy

Do not copy the whole customer-agent framework, hosted API, or chat UI when only the policy runtime pattern is needed.

Do not rely on LLM matching as the sole safety control for coding-agent actions. File writes, shell commands, dependency installs, network calls, and destructive git operations need deterministic checks and explicit approval paths.

Do not expose broad local/plugin/MCP/OpenAPI tool execution without a stronger threat model than Parlant needs for customer support integrations.

Do not make one global numerical priority decide all coding policy conflicts. Coding work often needs scoped priority domains, such as safety, repo ownership, user intent, test policy, and release policy.

Do not treat canned strict mode as a substitute for validating tool output. It prevents free-form wording, but it still depends on correct field provenance and template coverage.

Do not import large ARQ prompts as an opaque control layer. The useful part is the staged contract and trace, not the exact customer-service wording.

## Fit For Agentic Coding Lab

Fit is conditional but high value. Parlant is one of the better references for guidance control as an execution system: rules are selected, related, conflicted, reevaluated, and verified instead of merely written into a prompt.

The strongest coding-agent mapping is a repo-policy engine around AGENTS.md, user instructions, tool permissions, and verification obligations. Guidelines can represent repo rules; relationships can encode precedence and conflicts; tools can be shell, git, file editing, MCP, and browser actions; tool results can trigger new checks; response analysis can mark instructions applied. To be adopted for coding work, the model-based pieces need deterministic companions: sandbox policy, static checks, tests, git diff inspection, and explicit approvals for irreversible actions.

## Reviewed Paths

- `README.md`, `llms.txt`, `CLAUDE.md`: product framing, context-engineering model, quick concepts, and repository architecture instructions.
- `docs/concepts/customization/guidelines.md`, `relationships.md`, `tools.md`, `journeys.md`, `canned-responses.md`: primary user-facing model for guidelines, relationship types, guideline-gated tools, journey state, and output composition modes.
- `docs/production/agentic-design.md`, `docs/advanced/explainability.md`: guidance-boundary recommendations, ARQ-based explainability, and runtime rationale logging.
- `src/parlant/core/engines/alpha/engine.py`: main process, preparation iterations, guideline/journey loading, tool execution, transient guideline injection, generation, and response analysis.
- `src/parlant/core/engines/alpha/guideline_matching/**`: generic/custom matching strategies, observational/actionable/low-criticality/disambiguation/journey-node batches, response analysis batches, and matching context assembly.
- `src/parlant/core/engines/alpha/relational_resolver.py`: dependency, priority, numerical priority, entailment, tag, journey, and trace resolution logic.
- `src/parlant/core/engines/alpha/tool_event_generator.py`, `tool_calling/tool_caller.py`, `default_tool_call_batcher.py`, `single_tool_batch.py`, `overlapping_tools_batch.py`: guideline-scoped tool inference, batching, parameter validation, overlap handling, and tool execution.
- `src/parlant/core/engines/alpha/prompt_builder.py`, `message_generator.py`, `canned_response_generator.py`: context section construction, generation retries/self-revision, canned response retrieval, strict/composited/fluid composition, and missing-tool-data injection.
- `src/parlant/core/guidelines.py`, `guideline_tool_associations.py`, `relationships.py`, `journeys.py`, `journey_guideline_projection.py`, `tools.py`, `agents.py`, `context_variables.py`, `sessions.py`, `entity_cq.py`: core entities behind behavior policy, journey projection, tool schema, agent composition modes, state, and entity queries.
- `src/parlant/core/engines/alpha/optimization_policy.py`, `perceived_performance_policy.py`, `src/parlant/core/nlp/policies.py`: reviewed to separate infrastructure/retry policies from behavioral guidance control.
- `src/parlant/core/services/tools/service_registry.py`, `plugins.py`, `mcp_service.py`, `openapi.py`: local/plugin/MCP/OpenAPI tool service boundaries, schema conversion, payload limits, streaming callbacks, and lifecycle management.
- `src/parlant/api/guidelines.py`, `relationships.py`, `agents.py`, `sessions.py`, and `src/parlant/sdk.py`: public API/SDK surfaces for creating and mutating the reviewed behavior-control concepts.
- Tests sampled from `tests/core/stable/engines/alpha/test_relational_resolver.py`, `test_tool_caller.py`, `test_guideline_matcher.py`, `test_disambiguation_batch.py`, `tests/sdk/test_guidelines.py`, `test_tools.py`, `test_dynamic_composition_mode.py`, `test_canned_responses.py`, and API tests for guidelines, relationships, sessions, agents, and canned responses.

## Excluded Paths

- `src/parlant/api/chat/**`, `src/parlant/api/chat/dist/**`, chat React components, and chat static assets: UI and built frontend output, not the policy/guidance-control execution path.
- `docs/assets/**`, images, videos, fonts, and other binary/static media: useful for docs presentation but irrelevant to rule matching, tool boundaries, or context control.
- `poetry.lock`, `uv.lock`, `package-lock.json`, TypeScript build metadata, and generated bundles: dependency/build outputs. Dependency metadata was enough for this review.
- Most `src/parlant/adapters/**`: persistence/provider adapter implementations. Reviewed core ports and service boundaries instead; adapter internals do not change guideline resolution semantics.
- Broad `docs/adapters/**`, release docs, deployment docs, and product installation pages: operational documentation outside the guidance-control path.
- `examples/**`: useful usage samples, but not authoritative runtime logic. Core docs, engine code, SDK/API surfaces, and tests were higher signal.
- `.github/**`, `.devcontainer/**`, `.githooks/**`, `scripts/**`: CI, development, release, and maintenance tooling. Not needed to understand rule matching or tool execution.
- Tests focused only on UI, packaging, adapters, or broad end-to-end server behavior: excluded after reviewing representative core, SDK, and API tests that exercise guidance matching, relationships, tools, composition, and session control.
