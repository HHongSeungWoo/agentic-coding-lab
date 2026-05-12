# karthikscale3/ctx-zip

- URL: https://github.com/karthikscale3/ctx-zip
- Category: token-efficiency
- Stars snapshot: 168 (GitHub repo page, captured 2026-05-12)
- Reviewed commit: 76580f7ba1555c891928702743ac74412c7fac60
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal prototype for two agent context patterns: move tool definitions into an explorable sandbox filesystem, and replace AI SDK tool-result payloads with file references. Strong idea fit for coding agents, but not production-ready without fixes for fidelity, tests, lockfile health, sandbox policy, secret exposure, path scope, and overwrite semantics.

## Why It Matters

ctx-zip attacks two common causes of context bloat in tool-heavy agents. First, tool schemas and descriptions can consume context before the model starts work. Second, every large tool result can remain in the transcript even after the agent only needs a small part of it.

The useful pattern is "externalize, then retrieve." MCP and local tool definitions become TypeScript files in a sandbox, so the agent can inspect only the tools it needs with `sandbox_ls`, `sandbox_cat`, `sandbox_grep`, and `sandbox_find`. Large tool results become JSON files under a compact storage directory, while the conversation keeps a short pointer. This is directly relevant to coding agents because source search, dependency inspection, API calls, logs, and test outputs are often too large to keep inline.

The caution is that this implementation is a library/prototype, not an enforcement layer. It reduces prompt pressure only when the host agent calls `compact()` in the loop and supplies safe retrieval tools. It does not count tokens, enforce a budget, redact sensitive data, guarantee stable historical references, or sandbox local execution strongly by itself.

## What It Is

ctx-zip is a TypeScript package for the Vercel AI SDK. It exposes:

- `compact(messages, options)`: rewrites AI SDK `ModelMessage[]` histories by replacing tool-result outputs with either file references or drop notices.
- `SandboxManager`: creates a workspace with `mcp/`, `local-tools/`, `user-code/`, and `compact/` directories.
- Sandbox providers: local filesystem, E2B, and Vercel Sandbox.
- Exploration tools: `sandbox_ls`, `sandbox_cat`, `sandbox_grep`, `sandbox_find`.
- Execution/editing tools: `sandbox_exec`, `sandbox_write_file`, `sandbox_edit_file`, `sandbox_delete_file`, and `sandbox_lint`.
- Tool generation: MCP tool definitions become TypeScript wrapper files; in-process AI SDK tools become inspectable TypeScript source files.
- File adapters: local and sandbox-backed adapters for persisted compacted outputs.

The repo is small: root README and package metadata, `src/sandbox-code-generator/**`, `src/tool-results-compactor/**`, one boundary test file, and examples for MCP search, local tools, and email output compaction.

## Research Themes

- Token efficiency: Strong concept fit. It removes tool definitions and large results from the model transcript by putting them in files. README claims large reductions, but the code has no token-aware budget, threshold, benchmark, or automatic measurement outside examples' rough character-count estimator.
- Context control: Good primitive layer. Agents can inspect tool docs/code and compacted outputs on demand. Boundaries support `"all"`, `keep-first`, and `keep-last`, but there is no policy for "compact if over N tokens" or "keep only relevant slices."
- Sub-agent / multi-agent: No native subagent model. Multiple agents could share a sandbox/file adapter, but there is no locking, ownership, provenance beyond tool-call metadata, or concurrent-session policy.
- Domain-specific workflow: Strongest for coding agents that already use sandboxes. Tool definitions as code plus `sandbox_exec` let an agent write scripts that combine many tools without serializing every intermediate result into context.
- Error prevention: Mixed. Generated TypeScript interfaces and mandatory exploration prompt reduce wrong tool calls. Tests are shallow and currently suspect; `npm ci` failed because `package-lock.json` is not in sync with `package.json`.
- Self-learning / memory: Not a learning system. It gives durable-ish transcript side storage under `compact/{sessionId}/tool-results`, but no retrieval ranking, summarization, embeddings, or cross-session memory hygiene.
- Popular skills: No skill pack. Reusable artifacts are the compaction loop, sandbox exploration tools, and generated-code tool discovery pattern.

## Core Execution Path

Output compaction path:

1. Host agent calls `compact(messages, options)` after a model step, usually from `prepareStep` or after appending response messages.
2. `compact()` selects a strategy. Default is `"write-tool-results-to-file"`; `"drop-tool-results"` is also implemented.
3. A `FileAdapter` is resolved from an object, `file://` URI, or current working directory.
4. `writeToolResultsToFileStrategy()` shallow-copies the message array, requires the last message to be assistant text, computes a compaction window, and skips the final assistant message.
5. For each `role: "tool"` message with `type: "tool-result"`, it extracts `output.value` for JSON outputs, `output.text` for text outputs, or the raw output object.
6. If the tool name is in `fileReaderTools` (`sandbox_ls`, `sandbox_cat`, `sandbox_grep`, `sandbox_find`, plus caller additions), it replaces the result with `Read from file: ...` or a generic storage-read message instead of persisting that read result again.
7. Otherwise it writes `{ metadata, output }` as JSON through the adapter and replaces the inline result with `Written to file: ... To read it, use: sandbox_cat({ file: "..." })`.
8. `dropToolResultsStrategy()` follows the same window logic but replaces each tool result with `Results dropped for tool: ... to preserve context`.

Tool discovery path:

1. `SandboxManager.create()` chooses a provider, defaulting to `LocalSandboxProvider`, and creates `mcp/`, `local-tools/`, `user-code/`, and `compact/`.
2. `register({ servers })` connects to MCP servers, lists tools, installs MCP dependencies in the sandbox, and writes wrappers under `mcp/{server}/`.
3. `register({ standardTools })` serializes AI SDK tool metadata and `execute.toString()` into `local-tools/*.ts`.
4. The host passes `manager.getAllTools()` to the model. The model sees filesystem exploration and execution tools rather than every downstream MCP tool directly.
5. Prompt guidance (`SANDBOX_SYSTEM_PROMPT`) tells the model to inspect `user-code/README.md`, `mcp/README.md`, `local-tools/README.md`, and specific tool files before writing code.
6. `sandbox_exec` writes generated TypeScript into `user-code/` and runs it with `npx tsx`.

## Architecture

The repo has two mostly separate layers.

The compactor layer is message-transform middleware:

- `src/tool-results-compactor/compact.ts`: public options and strategy dispatch.
- `src/tool-results-compactor/strategies/index.ts`: boundary calculation, write-to-file strategy, drop strategy, file-reader special case, metadata wrapper, and reference text generation.
- `src/tool-results-compactor/lib/resolver.ts`: resolves `FileAdapter` or `file://` URI storage.
- `src/tool-results-compactor/lib/grep.ts`: helper for searching persisted objects through adapter read APIs, but not wired into public AI SDK tools.

The sandbox-code layer is agent tool discovery and execution:

- `SandboxProvider`: minimal interface for `writeFiles`, `runCommand`, `stop`, `getId`, and `getWorkspacePath`.
- Providers: local, E2B, Vercel.
- `SandboxManager`: owns workspace paths, directory creation, MCP registration, local tool generation, exploration tools, execution tools, and file adapters.
- `mcp-client.ts` and generated `_client.ts`: fetch MCP definitions and route generated wrapper calls to MCP servers.
- `file-generator.ts`: generates MCP wrapper files, README files, usage examples, and a verbose MCP client.
- `tool-code-writer.ts`: generates local AI SDK tool files from tool names, schemas, descriptions, and `execute` source.
- `sandbox-tools.ts`: exposes read/search/list/find, code execution, file write/edit/delete, and TypeScript lint tools to the model.

The architecture intentionally uses files as the agent's working memory surface. That is promising for coding agents, but it also means filesystem permissions, path scope, secrets, and command execution become the real security boundary.

## Design Choices

The main design choice is to compress by indirection, not summarization. Tool outputs are stored exactly as JSON under a metadata wrapper, then the transcript keeps a pointer. This preserves more fidelity than a summary, but shifts retrieval burden to the model.

The compactor only runs when the final message is assistant text. This matches an AI SDK pattern where tool calls/results are followed by an assistant answer before history is compacted. It will not compact mid-step tool results.

Boundary handling is simple. `"all"` compacts all eligible old tool messages before the final assistant message. `keep-first` preserves the first N messages. `keep-last` preserves the last N messages. There is an unused older `detectWindowStart()` helper whose comments do not match the active range logic.

The file naming policy is one file per tool name: `fetchEmails.json`, `search.json`, and so on. README explicitly says later calls overwrite the same tool's file. Code comments still mention `{toolName}-{seq}.json`, but the implementation does not sequence files.

Read tools are special-cased to avoid re-compacting retrieval output. That is necessary; otherwise reading a compacted file would immediately write another compacted file and pollute the transcript with recursive references.

Generated code is meant to be inspected. MCP tools become typed wrapper functions that call `callMCPTool(server, tool, args)`. Local tools become files containing metadata, a best-effort TypeScript interface, and the original `execute` function source.

The local sandbox is a development convenience, not a security sandbox. It writes to a local directory and executes host commands through Node `child_process.spawn` with `shell: true`. Absolute paths and broad read commands are not confined by `sandbox_cat`, `sandbox_ls`, `sandbox_grep`, or `sandbox_find`.

## Strengths

The core abstraction is easy to understand and easy to integrate into AI SDK loops. The examples show where to call `compact()` and how to provide retrieval tools.

The filesystem discovery pattern is strong for large MCP surfaces. Instead of loading many downstream tool schemas into prompt context, the model can list servers, inspect only relevant files, then write code that imports those tool wrappers.

The metadata wrapper keeps useful provenance: tool name, timestamp, tool call ID, and session ID. This is enough for debugging basic compacted outputs.

`sandbox_cat` unwraps compacted result JSON and returns only `output`, avoiding accidental metadata noise when the agent reads a compacted file.

The same sandbox abstraction works across local, E2B, and Vercel providers, so the pattern can be tested locally and moved to stronger remote isolation.

The generated prompt and README files push the model toward a good workflow: explore first, read exact API definitions, write code, optionally lint, execute, and show results.

The drop strategy is useful for tools whose outputs are ephemeral or already consumed. It provides maximum context reduction with no storage surface.

## Weaknesses

Historical fidelity is weak for repeated calls to the same tool. Every call to a given tool writes the same `{toolName}.json` key, so older transcript references can point to newer output after overwrite. This is a major issue for agents that need to revisit earlier searches, logs, or API responses.

No token budget exists. The system compacts all eligible tool results in the selected window, regardless of size, importance, or budget. It also retrieves whole files with `sandbox_cat`; there is no pagination, chunking, preview, or token cap.

The compactor shallow-copies the message array but mutates nested message parts. Callers expecting the original `messages` object to remain unchanged can be surprised.

Tests are not trustworthy in the reviewed checkout. `tests/boundary.spec.ts` has contradictory expectations for `run("all")`, expects `readFile` to be reference-only without configuring it as a file reader, and appears stale relative to current boundary code.

Dependency verification is broken at checkout. `npm ci` fails because `package-lock.json` is not in sync with `package.json` (`express` and `zod` missing from lock resolution). I did not run upstream tests after elevated install was rejected for third-party lifecycle-script risk.

Security boundaries are too loose for untrusted coding-agent use. Local provider command execution is host execution, exploration tools accept broad paths, and E2B command execution builds shell strings by joining arguments.

MCP credentials can leak into generated files and logs. `generateMCPClient()` serializes server headers into `_client.ts`; if `Authorization` headers contain real bearer tokens, the agent can read them. The generated client also logs full server config JSON, which can include those headers.

There is no privacy layer for compacted outputs. Raw tool results are written to local or sandbox files with no redaction, encryption, retention policy, access classification, or user confirmation.

## Ideas To Steal

Use file references for large tool outputs, but give every tool call a stable unique key such as `{toolName}-{toolCallId}.json` or `{step}-{toolName}.json`. Never let old transcript references drift to new data.

Expose retrieval tools separately from data-producing tools, and mark retrieval tools as non-persisted so compacted reads do not recursively generate more compacted files.

Generate an explorable tool filesystem for large tool surfaces. For coding agents, this is more useful than dumping every tool schema into the prompt.

Keep the "explore before coding" system prompt pattern. It reduces guessed imports and wrong tool signatures.

Store metadata beside raw output. Include tool name, tool call ID, step number, timestamp, schema/version, source adapter, hash, byte length, and possibly content classification.

Combine compaction with retrieval slices: `cat` with byte/range limits, `grep` with match caps, JSON path selection, table previews, and top-level key listing.

Treat compaction as a policy decision. Add thresholds, token estimates, allowlists/denylists, "never persist secrets" rules, and a visible audit log.

Use a real sandbox provider for generated code execution. Local mode should be explicitly labeled development-only and default to path-restricted reads if exposed to models.

## Do Not Copy

Do not copy the one-file-per-tool overwrite policy. It saves storage but breaks historical references.

Do not expose real MCP auth headers in generated files. Use runtime secret injection or a broker that can call tools without making credentials readable to the model.

Do not use local filesystem execution as a security boundary. `LocalSandboxProvider` is useful for development, not for untrusted model-written code.

Do not rely on `sandbox_cat` for large persisted outputs without byte limits or structured selectors. It can reintroduce the same context flood the compactor was meant to avoid.

Do not treat drop compaction as reversible. It is useful only when the result has been fully consumed or can be reproduced cheaply.

Do not ship this pattern without tests for multi-call same-tool history, repeated compaction idempotence, file-reader references, empty outputs, text outputs, failed writes, and malicious path inputs.

Do not claim measured token reductions from this code without a benchmark harness. The README claims are plausible but not reproduced in this repo.

## Fit For Agentic Coding Lab

High fit as a pattern source for token-efficient coding-agent workflows. The best local adaptation is a safer "tool result artifact store" paired with retrieval tools that are byte-capped, path-scoped, and auditable.

For Agentic Coding Lab, the reusable pieces are:

- Tool-output compaction after each agent step.
- Stable artifact references in transcript messages.
- On-demand retrieval through read/search/list tools.
- Tool-definition discovery through generated files instead of prompt-injected schemas.
- A prompt that forces the agent to inspect available tool files before writing integration code.

The implementation should be rebuilt with stricter invariants: immutable artifact keys, content hashes, token and byte budgets, redaction hooks, path allowlists, no readable bearer tokens, no host-local execution by default, and verification tests that cover the actual AI SDK message shape.

## Reviewed Paths

- `README.md`: product thesis, installation, tool discovery flow, output compaction strategies, boundary options, examples, provider overview, and public API claims.
- `package.json`, `tsconfig.json`, `.env.example`: package entrypoints, scripts, dependency model, optional sandbox dependencies, TypeScript config, and environment expectations.
- `src/index.ts`: public API exports.
- `src/tool-results-compactor/compact.ts`: strategy dispatch, default options, file adapter resolution, `fileReaderTools`, and public types.
- `src/tool-results-compactor/strategies/index.ts`: active compaction logic, boundaries, final-assistant guard, tool-result extraction, file-reader special case, metadata wrapper, overwrite key generation, reference text, and drop strategy.
- `src/tool-results-compactor/lib/resolver.ts`, `src/tool-results-compactor/lib/grep.ts`: local file URI resolution and adapter read/search helper behavior.
- `src/sandbox-code-generator/sandbox-manager.ts`: workspace layout, registration flow, tool accessors, file adapter creation, summary, display tree, and cleanup.
- `src/sandbox-code-generator/sandbox-tools.ts`: `sandbox_ls`, `sandbox_cat`, `sandbox_grep`, `sandbox_find`, `sandbox_exec`, write/edit/delete/lint tools, error text, path behavior, and compacted JSON unwrapping.
- `src/sandbox-code-generator/file-adapter.ts`: local and sandbox-backed storage, key resolution, writes, reads, and URI formatting.
- `src/sandbox-code-generator/file-generator.ts`, `tool-code-writer.ts`, `schema-converter.ts`, `mcp-client.ts`, `prompts.ts`: MCP wrapper generation, local AI SDK tool generation, schema-to-TypeScript conversion, MCP definition fetching, generated client behavior, and exploration prompt.
- `src/sandbox-code-generator/local-sandbox-provider.ts`, `e2b-sandbox-provider.ts`, `vercel-sandbox-provider.ts`, `sandbox-provider.ts`, `sandbox-utils.ts`, `types.ts`: provider abstraction, local execution, E2B/Vercel command/file adapters, convenience creation helpers, and config types.
- `tests/boundary.spec.ts`: existing test coverage and stale/contradictory expectations around boundaries and file-reader behavior.
- `examples/ctx-management/email_management.ts`: full compaction demo, rough token estimator, message persistence, strategy selection, and retrieval tool inclusion.
- `examples/tools/weather_tool_sandbox.ts`: standard AI SDK tool generation demo across providers.
- `examples/mcp/local_mcp_search.ts`, `examples/mcp/e2b_mcp_search.ts`, `examples/mcp/vercel_mcp_search.ts`, `examples/mcp/vercel_mcp_simple.ts`: representative MCP registration, sandbox tool exposure, persistent messages, and prompt usage.
- Git metadata: tracked file list, clean checkout status, reviewed commit, latest commit date/message, and remote HEAD.
- GitHub repo page: current public star/fork snapshot and repository file inventory.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for commit, remote HEAD, file list, and checkout status; not reviewed as source content.
- `package-lock.json`: dependency snapshot. Reviewed only enough to verify repository health after `npm ci` failed because the lockfile is not in sync with `package.json`; not treated as architecture.
- `examples/ctx-management/mock_emails.json`: sample email dataset for the compaction demo. Sample shape was noted, but all 628 lines were not reviewed because it is fixture data, not compaction logic.
- `node_modules/`: absent in the reviewed checkout. No vendored dependency source was reviewed.
- Generated build output such as `dist/`: absent in the reviewed checkout.
- Binary/media/UI-only assets: none present in tracked files.
- External services and docs linked from examples, including AI SDK docs, E2B, Vercel Sandbox, grep.app MCP, and npm registry package pages: relevant operational context, but outside the assigned repo review.
