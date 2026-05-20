# pguso/ai-agents-from-scratch

- URL: https://github.com/pguso/ai-agents-from-scratch
- Category: tool-use
- Stars snapshot: 3,520 (GitHub REST API repository metadata, 2026-05-20)
- Reviewed commit: 8b9251726043de209673102e14c8922f10da0653
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful teaching reference for first-principles tool-use patterns, especially `defineChatSessionFunction`, prompt-visible tool schemas, JSON grammar constrained planning, file-backed memory, and a small typed error taxonomy. It is not a production-ready agent runtime: tools are local demo functions, policies are prompt-driven, tests are absent, and most guardrails are illustrative rather than enforced by a shared gateway.

## Why It Matters

This repo is valuable because it strips agent tool use down to the execution mechanics that frameworks usually hide. The examples show how a local LLM session sees tool descriptions, chooses a function, receives tool output, uses memory injected through the system prompt, and iterates through a ReAct-style loop.

For Agentic Coding Lab, the main lesson is not the exact JavaScript code. The reusable pattern is the progressive decomposition: start with direct model calls, add one tool, add persistent state, add an explicit loop, then split planning from deterministic execution and add error classification. That sequence makes good lab material because each new capability changes the execution path in an inspectable way.

## What It Is

`ai-agents-from-scratch` is an educational JavaScript repository for building agents without LangChain-style frameworks. Most examples use `node-llama-cpp` with local GGUF models under an ignored `models/` directory. One optional intro uses the OpenAI SDK.

The repo has 14 numbered examples. The tool-use center is `examples/07_simple-agent`, `examples/08_simple-agent-with-memory`, `examples/09_react-agent`, `examples/10_aot-agent`, and `examples/11_error-handling`. Later Tree of Thought, Graph of Thought, and Chain of Thought examples use grammar-constrained JSON phases and deterministic orchestration, but they are reasoning-structure demos more than external tool-use systems.

## Research Themes

- Token efficiency: Low-to-moderate. Examples keep contexts small, set explicit context sizes, use JSON schemas to narrow output shape, reset chat history in later JSON phase examples, and put only a compact memory summary into the system prompt. There is no token budgeting, compression, summarization policy, or retrieval layer.
- Context control: Moderate as tutorial material. The system prompt is the main control surface; tool schemas are passed per `session.prompt`; memory is loaded once into the prompt; ReAct loop state stays in the chat session. Later examples isolate phases by resetting chat history before grammar-constrained calls.
- Sub-agent / multi-agent: Low. The repo has parallel batch sequences and branching/graph reasoning examples, but no sub-agent dispatch, worker isolation, inter-agent messaging, or shared work queues.
- Domain-specific workflow: Moderate. Each example hard-codes a tiny domain: chronology, translation, arithmetic, user profile lookup, return-risk review, or psychology analysis. It demonstrates domain-specific prompts and schemas, not reusable domain workflow infrastructure.
- Error prevention: Good as a teaching slice. `error-handling.js` includes typed errors, stable codes, retryability, timeouts, backoff with jitter, correlation IDs, user-safe messages, degraded deterministic fallback, and workflow-level errors. Other examples have limited safety checks.
- Self-learning / memory: Moderate. `MemoryManager` persists facts/preferences in JSON, migrates an older schema, avoids duplicate key/type saves, and formats a memory summary. It does not score memories, expire them, source-verify them, isolate users, or prevent prompt-injection into memory.
- Popular skills: Good source for small skills around function calling, JSON schema design, ReAct loop tracing, grammar-constrained JSON output, prompt debugging, memory summaries, and typed error handling for agent demos.

## Core Execution Path

Every local LLM example follows the same base path: resolve `__dirname`, load a GGUF model through `getLlama().loadModel(...)`, create a context or multiple context sequences, construct `LlamaChatSession`, call `session.prompt(...)`, print output, and dispose session/context/model/llama resources.

`examples/07_simple-agent/simple-agent.js` is the first real tool path. It defines `getCurrentTime` with `defineChatSessionFunction`, gives it a description and empty JSON Schema parameter object, registers it as `{ getCurrentTime }`, then calls `session.prompt(prompt, { functions })`. `node-llama-cpp` handles the model function-call format, calls the JavaScript handler, returns the tool result into the chat, and lets the model format the final answer under the chronologist system prompt.

`examples/08_simple-agent-with-memory/simple-agent-with-memory.js` adds persistent state. Startup creates `MemoryManager('./agent-memory.json')`, loads facts/preferences, formats them into `=== LONG-TERM MEMORY ===`, and injects that summary into the system prompt. The only memory write path is the `saveMemory` tool. The handler calls `memoryManager.addMemory`, which normalizes type/key/value, updates existing entries by type/key, skips exact duplicates, and writes the JSON file.

`examples/09_react-agent/react-agent.js` implements the explicit loop. The system prompt requires `Thought`, one `Action`, `Observation`, repeat, then `Answer`. Calculator tools are registered as function calls. `reactAgent(userPrompt, maxIterations)` repeatedly calls `session.prompt(...)`, using the original prompt first and `"Continue your reasoning. What's the next step?"` afterward. It streams chunks through `onTextChunk`, appends them to `fullResponse`, and stops when `Answer:` appears or the max iteration limit is reached.

`examples/10_aot-agent/aot-agent.js` separates planning from execution. The model emits a JSON plan constrained by `llama.createGrammarForJsonSchema(planSchema)`. `JsonParser.parse` cleans and repairs messy output, then `JsonParser.validatePlan` checks the broad shape. A second local validator checks duplicate atom IDs, allowed tool/decision names, required inputs, concrete numbers for first atoms, and dependency references. `executePlan` then sorts atoms by ID, resolves `<result_of_N>` references, and executes local pure arithmetic tools or decision handlers deterministically.

`examples/11_error-handling/error-handling.js` is the most production-shaped execution path. `runAgent` creates a correlation ID, validates input, handles a scripted policy failure, calls `promptLLM` with `session.prompt(prompt, { functions, maxTokens: 400 })`, and wraps the prompt call in `withTimeout` and `withRetries`. Tool and LLM failures are normalized through `AppError` subclasses. If the LLM path fails with `LLMCallError`, the agent switches to `runDegradedProfileResolution`, extracts a user id, calls primary/fallback tools deterministically, and surfaces `AgentWorkflowError` when the recovery chain fails.

The later ToT, GoT, and CoT examples reuse a JSON phase pattern: reset chat history, create a JSON grammar from a phase schema, call the local model with a narrow prompt, parse/repair JSON, pass structured phase outputs to later phases, and optionally write visualization HTML.

## Architecture

The architecture is intentionally flat. There is no framework runtime, registry service, plugin boundary, server, queue, database, or MCP layer. Each numbered example is a runnable script with local constants, local schemas, local tools, and direct model/session lifecycle management.

The shared helper layer has two notable utilities:

- `helper/json-parser.js` cleans LLM JSON output, extracts object/array boundaries, applies simple repair passes, and validates AoT plan shape.
- `helper/prompt-debugger.js` can inspect exact prompts, context token state, and structured token representation, then write debug logs.

The dependency surface is small: `node-llama-cpp` for local model loading/function calling/JSON grammar, `openai` for one hosted intro, and `dotenv` for API key loading. Model files, node_modules, `.env`, internal/ui folders, frontend outputs, and debug text logs are ignored by `.gitignore`.

## Design Choices

The repo uses progressive disclosure instead of abstraction. Every example repeats model/session setup so learners can see the full path. That duplication is a teaching choice, not an application architecture.

Tool schemas are deliberately small and prompt-visible. Simple tools use JSON Schema parameters with names/descriptions that the model can select. There is no central registry or permission model.

The ReAct example trusts the model to follow a textual protocol while the host loop only checks for `Answer:` and an iteration cap. This makes the loop easy to understand but leaves most correctness to the prompt.

The AoT example moves important authority back into code. The LLM produces a plan, but code validates names, dependencies, inputs, and references before deterministic execution. This is the strongest tool-use design choice in the repo.

The memory example stores key-value facts as plain JSON and injects them into the next system prompt. It favors inspectability over scalability.

The error-handling example treats failures as typed workflow data. Stable codes, retryability, user messages, details, causes, correlation IDs, and degraded fallback create a small but coherent failure contract.

## Strengths

The examples expose the actual execution path. A reader can trace where a tool is declared, where it is passed to the model, where the handler runs, and how output returns to the model.

The progression is pedagogically strong. Function calling, memory, ReAct, structured planning, and error handling each appear as a separate runnable script.

The AoT pattern is practical for coding agents: let the model draft a structured plan, validate it in code, then execute deterministic operations. This is safer than letting the model both decide and act inside an unconstrained loop.

The error-handling example covers several guardrails usually missing from tutorials: bounded calls, selective retries, jitter, normalized errors, correlation IDs, degraded mode, and user-safe formatting.

The prompt-debugging helper is useful. Capturing context state and available functions helps diagnose why a model did or did not call a tool.

The repo keeps local-model lifecycle cleanup visible with explicit `dispose()` calls, which matters for native bindings and GPU resources.

## Weaknesses

There is no test suite. `package.json` has a dummy `npm test` that exits with an error, and targeted search found no Jest/Vitest/node:test files. The examples are demos, not verified behavior.

Most safety is prompt-level. The ReAct loop does not parse `Action:` text, verify one tool call per step, validate observations, or detect tool misuse beyond what the function-calling library and handlers do.

Tools are not sandboxed or permissioned. The demo tools are harmless arithmetic/time/user-profile functions, but the repo does not show approval gates, filesystem/network policy, secret handling, or side-effect classification.

Memory is single-file and single-user. It has no user namespace, no locking, no schema validation on load beyond basic shape fixes, no provenance policy, no retention policy, and no defense against malicious or stale memory content.

The JSON parser uses broad regex repairs. That is useful for tutorials but risky as a contract layer for production, because repairs can silently transform malformed model output into a different accepted object.

`withTimeout` rejects on timeout but does not cancel the underlying LLM/tool promise; it only races it. That is acceptable for a demo, but real agent tools need cancellation propagation or process isolation.

There is little observability beyond console logs and optional text debug logs. No structured trace spans, tool-call ledger, replay artifact, or assertion harness exists.

## Ideas To Steal

Teach tool use as an execution ladder: direct prompt, one function, memory tool, ReAct loop, structured plan, typed failure path. That ladder maps well to Agentic Coding Lab modules.

Use tiny local tools for first-principles demos. Arithmetic and time tools make model/tool boundary errors obvious without external service noise.

Keep tool definitions inspectable. Pair every handler with a short description, JSON Schema parameters, and examples of when the model should call it.

Make prompt/context debugging a first-class helper. Agents need a way to see exact prompt text, registered functions, token count, and context state after tool calls.

Prefer AoT-style plan validation when the task can be represented as structured operations. The model can propose atoms, but code should validate allowed tools, inputs, references, dependencies, and final output.

Use degraded deterministic fallback for critical tool workflows. If the model path fails, code can still extract a known identifier, call the same tools, and return a bounded answer.

Classify errors once. Stable codes plus retryable/userMessage/details/cause fields give the rest of the agent one consistent failure interface.

Show memory as data, not magic. A plain JSON file and explicit prompt summary are easy to inspect, diff, and reset.

## Do Not Copy

Do not copy the ReAct loop as a production controller. It relies on `Answer:` text detection and prompt compliance rather than a parsed action protocol with enforced state transitions.

Do not treat `JsonParser` repairs as a production validator. Use strict schema validation, fail closed on ambiguous repairs, and preserve raw model output for audit.

Do not persist shared memory as one local JSON file in a multi-user coding agent. Add user/session scope, locking, provenance, retention, review, and deletion controls.

Do not expose real side-effecting tools with only a description and JSON Schema. Add risk tags, approval gates, sandboxing, budget limits, and audit logs.

Do not use Promise-race timeouts as cancellation. Make long-running tools cancellable, killable, or isolated.

Do not rely on local model demos as quality evidence. Add deterministic tests around parsers, validators, tool handlers, error classifiers, and loop termination.

Do not mix hidden chain-of-thought style traces into user-visible or durable logs for sensitive workflows. Use structured phase outputs and concise rationales instead.

## Fit For Agentic Coding Lab

Fit is conditional and high as a tutorial pattern source. The repo should not be a dependency or runtime foundation, but it is worth mining for lab exercises and small reference implementations.

The best Agentic Coding Lab adaptation would combine:

- A minimal function-calling exercise using one safe local tool.
- A prompt-debugger artifact that records exact tool schemas and prompt state.
- A memory exercise that stores structured facts with explicit provenance and user scope.
- A ReAct exercise that starts prompt-driven, then upgrades to parsed actions and enforced loop state.
- An AoT exercise where the model writes a plan and host code validates and executes it deterministically.
- An error-handling exercise with stable codes, selective retry, timeout, fallback, and correlation IDs.

The lab should add what the tutorial omits: tests, policy metadata, tool-call ledgers, cancellation, sandbox boundaries, approval gates, schema validation, and replayable traces.

## Reviewed Paths

- `README.md` for learning path, architecture summary, prerequisites, and stated scope.
- `PROMPTING.md` for prompt strategy, JSON structuring guidance, and validation recommendations.
- `DOWNLOAD.md` for required local GGUF model setup and quantization tradeoffs.
- `package.json` for dependencies and the dummy test script.
- `.gitignore` for ignored runtime/vendor/UI/model/debug outputs.
- `examples/01_intro/intro.js` through `examples/06_coding/coding.js` for base local LLM, OpenAI intro, system prompting, reasoning-only, batching, and streaming patterns.
- `examples/07_simple-agent/simple-agent.js`, `CODE.md`, and `CONCEPT.md` for the first function-calling path.
- `examples/08_simple-agent-with-memory/simple-agent-with-memory.js`, `memory-manager.js`, `agent-memory.json`, `CODE.md`, and `CONCEPT.md` for persistent memory and save/update behavior.
- `examples/09_react-agent/react-agent.js`, `CODE.md`, and `CONCEPT.md` for the ReAct loop, calculator tools, iteration cap, and final-answer detection.
- `examples/10_aot-agent/aot-agent.js`, `CODE.md`, and `CONCEPT.md` for grammar-constrained planning, plan validation, reference resolution, and deterministic execution.
- `examples/11_error-handling/error-handling.js`, `CODE.md`, and `CONCEPT.md` for typed errors, retries, timeouts, fallback, degraded mode, and workflow errors.
- `examples/12_tree-of-thought/tree-of-thought.js`, `examples/13_graph-of-thought/graph-of-thought.js`, and `examples/14_chain-of-thought/chain-of-thought.js` for schema-constrained multi-phase reasoning orchestration.
- `helper/json-parser.js` for JSON cleaning, repair, extraction, and plan-shape validation.
- `helper/prompt-debugger.js` for prompt/context/token inspection.
- Repository-wide search for tests and tool/error/memory/function-call keywords; no real test suite was present.

## Excluded Paths

- `diagrams/agent-architecture.png`: binary diagram for README explanation, not execution logic.
- `examples/12_tree-of-thought/visualization.html`, `examples/13_graph-of-thought/visualization.html`, and `examples/14_chain-of-thought/visualization.html`: static UI visualizations of reasoning outputs, not tool invocation or safety logic.
- `helper/visualization-writers.js`: UI/HTML generation helper for later visualization demos; only its role was noted because it does not change tool-use execution.
- `package-lock.json`: generated dependency lockfile; useful for installation reproducibility but not agent design.
- `logs/.gitkeep` and ignored `logs/*.txt`: debug-output directory marker and generated runtime logs, not source behavior.
- `.env.example`, `CONTRIBUTING.md`, and `LICENSE.md`: repository metadata and setup guidance; not part of the agent execution path beyond confirming contribution/test posture.
- Ignored or absent runtime/vendor/UI paths from `.gitignore`, including `models/`, `node_modules/`, `.env`, `internal/`, `ui/`, `frontend*`, `node-llama-docs/`, and `VIDEO_SCRIPT.md`: model binaries, dependencies, local secrets, internal/UI-only or generated content outside the reviewed source snapshot.
