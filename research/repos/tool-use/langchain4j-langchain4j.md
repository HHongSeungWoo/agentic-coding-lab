# langchain4j/langchain4j

- URL: https://github.com/langchain4j/langchain4j
- Category: tool-use
- Stars snapshot: 11,941 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: 1b5050bb45ddc9d83cdf2dfbce0d58a7dab3084a
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern source for typed tool execution, MCP bridging, dynamic tool discovery, tool search, skills activation, guardrail placement, and workflow scope persistence. Do not copy the broad Java framework surface, unsafe shell skill mode, or default raw exception leakage.

## Why It Matters

LangChain4j is one of the more mature Java-first LLM application frameworks. For Agentic Coding Lab, the useful part is not the provider matrix itself but the concrete execution path around tool schemas, tool loops, MCP adapters, guardrails, RAG, agent workflow state, and recoverable sub-agent orchestration.

The repo is valuable because its tool-use stack has moved past simple demos. It covers static annotated tools, dynamic tool providers, MCP servers, searchable tool catalogs, immediate-return tool behavior, concurrent tool execution, typed result surfaces, input/output guardrails, human-in-the-loop workflows, and crash recovery tests.

## What It Is

LangChain4j is an idiomatic Java library for building LLM applications. Its main abstraction is an AI Service: a Java interface backed by chat models, memory, prompt templates, tools, RAG, guardrails, and output parsers. The library also has experimental agentic workflows in `langchain4j-agentic`, MCP support in `langchain4j-mcp`, and skill activation support in `langchain4j-skills`.

The repo is not a small coding-agent harness. It is a broad framework with many provider and vector-store integrations. The reviewed parts are the runtime paths that affect tool use: AI Service invocation, `@Tool` schema creation, tool execution, dynamic tool providers, MCP clients/transports, RAG augmentation, guardrail execution, agentic scope state, and tests that prove these pieces work together.

## Research Themes

- Token efficiency: Tool search keeps only a search tool and always-visible tools in the initial request, then exposes matched tools through `found_tools` metadata stored in chat memory. Skills use an `activate_skill` tool plus optional resource reader to lazily reveal skill content and skill-scoped tools. Agentic scope stores compact invocation context instead of naively appending every sub-agent transcript.
- Context control: AI Service invocation applies system/user message transforms, RAG augmentation, guardrails, chat memory, and tool loops in a fixed order. `DefaultAgenticScope` records scoped state and selected conversation context. MCP resource support exposes explicit `list_resources` and `get_resource` tools instead of automatically dumping resource contents into the model context.
- Sub-agent / multi-agent: `langchain4j-agentic` supports typed agents, sequence, loop, parallel, parallel mapper, conditional routing, supervisor, planner, A2A, and human-in-the-loop workflows. Agents inherit AI Service features such as tools, tool providers, RAG, memory, and guardrails.
- Domain-specific workflow: Java annotations (`@Tool`, `@P`, `@Agent`, `@V`, `@MemoryId`, guardrail annotations) turn domain methods into schemas and workflow nodes. This gives a concrete pattern for typed tool APIs and explicit state keys.
- Error prevention: The runtime validates duplicate tool names, nested iterable parameters, invalid default values, missing primitive arguments, malformed MCP argument JSON, max tool-calling round trips, and guardrail failures. It has separate policies for hallucinated tool names, argument errors, execution errors, and output-guardrail retry or reprompt.
- Self-learning / memory: The repo has chat memory, persistent `AgenticScope`, MCP/tool-list caches, and tool-search discoveries that persist through chat memory. It does not implement autonomous long-term self-improvement; memory is operational state rather than a learning loop.
- Popular skills: The skills module loads `SKILL.md`-style instructions and preloaded resources. Tool mode is the useful pattern: activate a skill, read its resources, and expose skill-scoped tools. Shell mode is explicitly experimental and unsafe because it executes host commands.

## Core Execution Path

`DefaultAiServices` is the central path for normal AI Service calls. It builds an invocation context, resolves memory id and chat memory, renders system/user messages, applies the system-message transformer, runs RAG augmentation, attaches multimodal input, then executes input guardrails. After that it adds messages to memory, optionally starts moderation, creates `ToolServiceContext`, builds the `ChatRequest`, calls the model through `ChatExecutor`, verifies moderation, runs the tool loop, executes output guardrails, and parses or wraps the result.

The ordering matters for Agentic Coding Lab. RAG happens before input guardrails, so guardrails inspect the final augmented prompt rather than only the user's raw message. Tool execution happens before output guardrails, so output validation sees the final model answer after any tool calls. The `Result<T>` path can carry sources, token usage, tool executions, intermediate responses, and the final response, which is a useful evidence surface for coding-agent traces.

`ToolService` owns the main tool loop. It collects static `@Tool` methods and provider tools, evaluates dynamic providers before each model call, applies optional tool search, builds the effective tool set, and submits tool specifications in the next `ChatRequest`. When the model returns tool execution requests, the service appends the assistant message, executes tool calls sequentially or concurrently, appends `ToolExecutionResultMessage` entries, fires before/after tool events, and either returns immediately or sends tool results back to the LLM for another round.

The loop has an explicit `maxToolCallingRoundTrips` cap, defaulting to 100. Immediate-return behavior is controlled per tool with `ReturnBehavior`: `TO_LLM` forces another model pass, `IMMEDIATE` can return without another pass when all calls are immediate, and `IMMEDIATE_IF_LAST` returns when the last call allows it. Any tool error forces results back through the LLM rather than immediate return.

`DefaultToolExecutor` is the reflection bridge. It parses JSON tool arguments, injects special parameters such as memory id, invocation parameters, invocation context, and managed handles, coerces values to Java primitives, boxed primitives, enums, UUID, `BigDecimal`, collections, maps, POJOs, and optional defaults, then invokes the Java method. Return conversion is predictable: `void` becomes `"Success"`, `String` returns as-is, other objects become JSON, and image/content objects can return multimodal tool results.

MCP tools follow the same AI Service loop through `McpToolProvider`. The provider asks one or more `McpClient` instances for tool specs, optionally filters tool names, maps logical names, maps full specs, marks always-visible tools, and creates `McpToolExecutor` instances. The executor keeps the physical MCP tool name fixed, so logical tool renaming does not break server calls.

`DefaultMcpClient` handles JSON-RPC protocol details, transport startup, initialize handshake, timeouts, health checks, reconnect, pagination, tool/resource/prompt list caching, cancellation on tool timeout, listeners, `_meta` injection, and error conversion. `ToolExecutionHelper` prefers MCP `structuredContent` over free-form text content and converts JSON into Java maps/lists/basic values.

Agentic workflows wrap AI Services rather than replacing them. `AgentBuilder` builds typed agents with the same chat models, tools, tool providers, RAG, guardrails, memory, and tool error policies. `PlannerBasedInvocationHandler` creates or retrieves `AgenticScope`, writes input args into scope, runs planner actions, invokes subagents, checkpoints persistent scope after each subagent invocation, and returns outputs from scope. Parallel planner execution uses `CompletableFuture`, and tests cover follow-up scheduling races.

## Architecture

The tool-use architecture splits into small runtime layers:

- `langchain4j-core`: model messages, tool annotations, tool specifications, RAG interfaces, guardrail interfaces, structured outputs, and shared data types.
- `langchain4j`: AI Services, tool execution, tool search, chat-memory integration, guardrail service integration, and high-level invocation path.
- `langchain4j-mcp`: MCP client, transports, tool provider, resource-as-tool presenter, prompt/resource APIs, listeners, and MCP error/result handling.
- `langchain4j-mcp-docker`: Docker-backed MCP transport that can run an MCP server container and attach stdio.
- `langchain4j-agentic`: experimental typed agents, workflow planners, agentic scope state, persistent scope stores, human-in-the-loop support, and observability hooks.
- `langchain4j-skills`: experimental skill loader and tool-mode activation path.
- `experimental/langchain4j-experimental-skills-shell`: unsafe shell-backed skill execution.
- Provider and embedding-store modules: adapters behind the shared APIs, mostly outside the reviewed architecture.

The key design is that tools are ordinary tool specifications plus executors. Static tools come from annotated methods, provider tools come from `ToolProvider`, MCP tools are just provider tools, tool search is another tool/provider layer, and skills are another dynamic provider layer. This lets the same AI Service loop work for local methods, remote MCP servers, searched tools, and activated skills.

## Design Choices

Tool declaration is typed and annotation-driven. `ToolSpecifications` converts `@Tool` methods into JSON schemas and excludes injected parameters from the schema. `@P` can name, describe, mark optional, and supply defaults. Required fields exclude optional/defaulted parameters. Duplicate tool names fail fast.

Dynamic tool providers are evaluated before each LLM request inside the tool loop. Tests show the static provider is called once, while dynamic providers run before each chat model request. Newly returned tools are added to the effective set for the invocation; tools absent from later dynamic provider results are not removed during that invocation. This favors monotonic tool availability and avoids invalidating pending tool calls.

Tool search is implemented as a visibility protocol. Initially the model sees `tool_search_tool` and any `ALWAYS_VISIBLE` tools. A search result stores matched tool names in a `ToolExecutionResultMessage` attribute named `found_tools`; later requests make those tools available. `SimpleToolSearchStrategy` performs string scoring, while `VectorToolSearchStrategy` embeds tool names/descriptions and caches tool embeddings.

Hallucinated tool names are policy-driven. The default strategy throws, but tests show a custom strategy can return an error result to the LLM so it can self-correct and call the right tool. Argument errors and execution errors also have handlers. The default execution-error handler returns the raw exception message to the model, which is useful for demos but a poor default for security-sensitive coding agents.

MCP support treats trust and token use as first-class concerns. `McpToolProvider` can combine clients, skip failed servers unless configured to fail closed, filter tools by name or predicate, map names/specs, mark selected tools always visible, and present resources as explicit list/get tools. Docs call out filters as a way to expose read-only subsets such as selected GitHub MCP tools.

MCP list caching is explicit. Tool, resource, and prompt lists can be cached, evicted, or disabled; notifications invalidate caches. Concurrent cache refreshes coalesce through futures. This is a useful pattern for agent systems that poll external capability catalogs without wasting tokens or network calls.

Guardrails are placed around the model/tool path rather than bolted on after parsing. Input guardrails run after RAG augmentation and before the model. Output guardrails run after tool calls and can rewrite, fail, fatal, retry, or reprompt with bounded attempts. Guardrails emit observability events and preserve ordering.

Agent workflows use a shared state object instead of passing every sub-agent transcript by default. `AgentExecutor` maps scope state into method args, optional agents can skip missing inputs, outputs write back to `outputKey`, and planner state is checkpointed under internal keys. Persistent scope supports crash recovery, while registered scopes support keyed access and eviction.

## Strengths

- Clear end-to-end path from Java interface call to prompt messages, RAG, guardrails, model call, tool loop, output validation, and typed result.
- Typed tool declaration with automatic JSON schema generation, injected runtime parameters, defaults, multimodal returns, and duplicate-name validation.
- Practical dynamic tool model: static providers, dynamic providers, tool search, skills activation, and MCP tools all plug into the same loop.
- Strong MCP adapter design: filtering, name/spec mapping, listener hooks, `_meta`, cancellation, timeouts, reconnect, pagination, structured-content parsing, resource tools, and cache invalidation.
- Useful safety knobs: hallucinated tool strategy, argument/execute error handlers, max tool-calling rounds, moderation input guardrail, output retries/reprompts, and before/after tool callbacks.
- Agentic workflows have real state and recovery mechanics: `AgenticScope`, persistent stores, checkpointing after subagent calls, human-in-the-loop pending responses, and tests that simulate recovery after lost in-memory state.
- Tests cover important edge cases: concurrent tool execution, dynamic provider re-evaluation, immediate-return combinations, hallucinated tool self-correction, default argument values, MCP protocol/application errors, cache behavior, resources-as-tools, pagination, workflow persistence, and parallel planner race prevention.

## Weaknesses

- The repo is very broad. Provider modules, vector stores, examples, and integration tests are useful to LangChain4j users but too large to copy into a focused coding-agent lab.
- Several relevant APIs are experimental, including agentic workflows, skills, and guardrails. Their shapes may change.
- Default tool execution error handling can leak raw exception messages back to the LLM. The docs warn about this risk; an Agentic Coding Lab should default to sanitized error envelopes.
- Required parameter semantics are uneven in the 1.x line. Missing required primitive values throw, while missing object reference values can pass as `null`; docs say this is planned to change in 2.0.
- The default `maxToolCallingRoundTrips` value of 100 is high for coding-agent workflows. Lab harnesses should set a tighter domain-specific cap.
- Dynamic providers add tools during an invocation but do not remove tools absent from later provider results, which can retain stale capabilities longer than expected.
- MCP stdio and Docker transports can run local or containerized server processes. The library exposes the mechanism but does not provide a coding-agent sandbox or approval system.
- Shell skills are explicitly unsafe. They run host shell commands, expose process environment, and can be driven by prompt injection unless wrapped by a separate sandbox and approval layer.

## Ideas To Steal

- Model tools as `(ToolSpecification, ToolExecutor)` pairs, regardless of whether they originate from local methods, MCP servers, skill activation, or search results.
- Use a monotonic per-invocation tool set: add dynamic/search-discovered tools during a loop, but record exactly why each tool became visible.
- Add a searchable tool catalog with one always-visible search tool plus a `found_tools` attribute on tool result messages. This is a clean token-saving pattern for large toolboxes.
- Carry tool execution evidence in final results: tool call ids, tool names, raw/sanitized arguments, result summaries, errors, intermediate model responses, and source documents.
- Split error policy into hallucinated-tool, argument-error, and execution-error handlers. Make recoverable model-facing errors structured and sanitized.
- Support tool return behavior for agentic workflows. Some tools should return immediately, while others should feed results back to the model for synthesis.
- Add before/after tool execution hooks with invocation context. Use them for audit trails, approval gates, secret redaction, metrics, and UI progress events.
- For MCP, keep logical display names separate from physical server tool names. Filter and rename specs for the model, but execute against the original server name.
- Expose MCP resources with a two-step list/get tool pair, not automatic context injection.
- Use cache invalidation notifications and explicit cache eviction for remote tool catalogs.
- Place input guardrails after context augmentation and output guardrails after tool loops. This validates what the model actually sees and what the user actually receives.
- Store workflow state in a typed scope with named outputs. Checkpoint after each sub-agent so long-running coding workflows can resume after crashes or human review waits.
- Implement skills as lazy capability bundles: a catalogue in the system prompt, an activation tool, preloaded resource reads, and skill-scoped tools revealed only after activation.

## Do Not Copy

- Do not copy the whole provider/vector-store matrix. It would dilute the lab with integration maintenance instead of sharpening tool-use research.
- Do not copy shell skill execution without an external sandbox, command allowlist, working-directory isolation, secret filtering, timeouts, and explicit user approval.
- Do not default to returning raw Java exception messages to the LLM. Use sanitized public messages and private diagnostics.
- Do not preserve the 1.x missing-object-argument behavior. Required structured args should fail validation before tool execution.
- Do not use a default 100-round tool loop for coding tasks. Coding agents need stricter caps, progress checks, and stuck-loop detection.
- Do not auto-run registry-discovered MCP servers. Treat local MCP process launch as privileged code execution.
- Do not make dynamic provider removal ambiguous. If a tool disappears, record whether existing pending calls may still execute and why.

## Fit For Agentic Coding Lab

Fit is conditional and strong as a design reference. The repo should not be adopted wholesale, but several patterns should be translated into small lab artifacts:

- A local tool registry with static tools, dynamic providers, per-invocation visibility state, and explicit tool provenance.
- A tool-search protocol that keeps large toolboxes out of context until queried.
- An MCP adapter boundary with allowlists, logical name mapping, resource list/get, structured result parsing, cache invalidation, and process-launch trust controls.
- A guardrail/error-policy layer around tool execution that separates private diagnostics from model-facing recovery messages.
- A skill activation path that preloads resources and reveals scoped tools without giving the model arbitrary filesystem or shell access.
- A workflow scope store that checkpoints after each sub-agent and supports human-in-the-loop pending responses.

For Agentic Coding Lab, the most important lesson is compositional: local tools, MCP tools, searched tools, and activated skill tools can all be normalized into one execution loop if visibility, provenance, error handling, and result evidence are explicit.

## Reviewed Paths

- `README.md`: project scope, AI Services positioning, provider breadth, tools, agents, and RAG claims.
- `docs/docs/tutorials/tools.md`: low-level and high-level tool APIs, `@Tool`, `@P`, defaults, required-argument behavior, return conversion, streaming tool calls, and error-handler notes.
- `docs/docs/tutorials/mcp.md`: MCP transports, `McpToolProvider`, filters, mappings, metadata, listeners, resources, prompts, cache controls, and security warnings.
- `docs/docs/tutorials/agents.md`: experimental agentic workflow concepts, sequence/loop/parallel/conditional/supervisor/planner patterns, and `AgenticScope`.
- `docs/docs/tutorials/rag.md`: indexing/retrieval split, `ContentRetriever`, `RetrievalAugmentor`, and AI Service integration.
- `docs/docs/tutorials/guardrails.md`: input/output guardrail order, retry/reprompt behavior, moderation guardrail, and configuration precedence.
- `docs/docs/tutorials/skills.md`: skill tool mode, activation/resource tools, and shell-mode warnings.
- `langchain4j/src/main/java/dev/langchain4j/service/DefaultAiServices.java`: main AI Service invocation path and ordering.
- `langchain4j/src/main/java/dev/langchain4j/service/tool/ToolService.java`: tool discovery, dynamic providers, loop, concurrent execution, immediate return, hallucinated tool policy, and event hooks.
- `langchain4j/src/main/java/dev/langchain4j/service/tool/DefaultToolExecutor.java`: JSON argument parsing, type coercion, injected parameters, defaults, method invocation, and return conversion.
- `langchain4j-core/src/main/java/dev/langchain4j/agent/tool/Tool.java`, `P.java`, and `ToolSpecifications.java`: annotation schema model and validation.
- `langchain4j/src/main/java/dev/langchain4j/service/tool/search/*`: simple/vector tool search strategies and found-tool metadata.
- `langchain4j-mcp/src/main/java/dev/langchain4j/mcp/*`: MCP client, provider, executor, result extraction, listeners, resources-as-tools, and cache/error behavior.
- `langchain4j-mcp/src/main/java/dev/langchain4j/mcp/client/transport/stdio/StdioMcpTransport.java`: stdio subprocess transport.
- `langchain4j-mcp-docker/src/main/java/dev/langchain4j/mcp/client/transport/docker/DockerMcpTransport.java`: Docker MCP transport and bind/env behavior.
- `langchain4j-agentic/src/main/java/dev/langchain4j/agentic/*`: agent builders, invocation handlers, planners, scope, persistence, supervisor, parallel, conditional, loop, and human-in-the-loop implementation.
- `langchain4j-core/src/main/java/dev/langchain4j/rag/*` and `langchain4j/src/main/java/dev/langchain4j/rag/*`: retrieval augmentor, retrievers, routers, query transformation, and content injection.
- `langchain4j-core/src/main/java/dev/langchain4j/guardrail/*`, `langchain4j/src/main/java/dev/langchain4j/service/guardrail/*`, and `langchain4j-guardrails/src/main/java/dev/langchain4j/guardrails/*`: guardrail interfaces, executors, services, and moderation guardrail.
- `langchain4j-skills/src/main/java/dev/langchain4j/skills/*`: safe tool-mode skill activation and resource reading.
- `experimental/langchain4j-experimental-skills-shell/src/main/java/dev/langchain4j/skills/shell/*`: unsafe shell-backed skill mode and command runner.
- `langchain4j/src/test/java/dev/langchain4j/service/AiServicesWithToolsIT.java`: dynamic providers, concurrent tools, max round trips, and tools-as-agents examples.
- `langchain4j/src/test/java/dev/langchain4j/service/tool/HallucinatedToolNameStrategyTest.java`: default throw and model-recoverable hallucinated tool handling.
- `langchain4j/src/test/java/dev/langchain4j/service/ReturnBehaviorCombinationsTest.java`: immediate-return behavior combinations.
- `langchain4j/src/test/java/dev/langchain4j/service/AiServicesWithToolSearchToolIT.java`: searchable tools, `found_tools`, always-visible tools, and chat-memory retention.
- `langchain4j/src/test/java/dev/langchain4j/service/AiServicesWithToolsWithDefaultValuesTest.java`: default tool argument parsing and optional schema behavior.
- `langchain4j-mcp/src/test/java/dev/langchain4j/mcp/*`: MCP provider mapping/filtering, cache behavior, structured content, resource tools, listeners, errors, timeouts, and pagination.
- `langchain4j-agentic/src/test/java/dev/langchain4j/agentic/RecoverabilityIT.java`: persistent scope recovery after simulated crash with human-in-the-loop pending response.
- `langchain4j-agentic/src/test/java/dev/langchain4j/agentic/WorkflowAgentsIT.java`: parallel/async workflows, persistent scope, human-in-the-loop, and agent composition.
- `langchain4j-agentic/src/test/java/dev/langchain4j/agentic/PlannerLoopThreadSafetyIT.java`: parallel planner follow-up race coverage.

## Excluded Paths

- `docs/static/*`, `docs/src/*`, and Docusaurus/package files under `docs/`: UI-only documentation site assets and build plumbing, not runtime tool-use behavior.
- Provider modules such as `langchain4j-open-ai`, `langchain4j-anthropic`, `langchain4j-google-*`, `langchain4j-azure-*`, `langchain4j-bedrock`, and similar model adapters: useful integrations but mostly provider glue behind the shared chat/tool interfaces.
- Embedding-store modules such as `langchain4j-pgvector`, `langchain4j-qdrant`, `langchain4j-pinecone`, `langchain4j-milvus`, `langchain4j-chroma`, and similar store adapters: relevant only through the common RAG interfaces reviewed above.
- Binary and test-data resources such as PDFs, images, audio samples, tokenizer/model resource files, zips, and generated fixture outputs: not source logic and not needed for tool-use design.
- Build and release plumbing including `.github/*`, Maven parent/BOM modules, native-image configs, CI scripts, and devcontainer files: operational packaging rather than agent/tool runtime behavior.
- Unrelated experimental modules such as SQL/Hibernate examples unless they touched the shared tool path: domain examples did not add new tool-use architecture.
- Broad example apps and provider-specific integration tests that only demonstrate adapter connectivity: skipped after confirming the shared AI Service, tool, MCP, RAG, guardrail, and agentic paths.
