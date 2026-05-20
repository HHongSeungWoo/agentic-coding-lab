# universal-tool-calling-protocol/code-mode

- URL: https://github.com/universal-tool-calling-protocol/code-mode
- Category: tool-use
- Stars snapshot: 1,459 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 10781e77ca69a25747f72e6800134e10551b30a6
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for code-mode tool use: expose one execution tool, inject namespaced tool functions and runtime schemas, and let the model batch multi-step workflows inside a sandbox. Adopt the pattern, but keep a stricter trust boundary than this repo's MCP wrapper and do not copy the Python sandbox claims without a stronger process model.

## Why It Matters

Code Mode is a concrete implementation of the tool-use direction where an agent does not receive every tool as a top-level function call. Instead, it discovers relevant tools, inspects generated interfaces, then submits one code block that can call registered UTCP/MCP tools as normal functions. That is directly useful for Agentic Coding Lab because many coding tasks are multi-step: search, inspect, transform, run verification, summarize. A code-mode layer can reduce repeated model round trips and token-heavy intermediate dumps if it returns only processed results.

## What It Is

The repository contains three related artifacts:

- `typescript-library`: `@utcp/code-mode`, a TypeScript `CodeModeUtcpClient` that upgrades a UTCP client with `callToolChain`.
- `python-library`: a Python `CodeModeUtcpClient` wrapper that executes RestrictedPython code against UTCP tools.
- `code-mode-mcp`: an MCP stdio server exposing UTCP registration, discovery, schema lookup, and TypeScript `call_tool_chain` execution to MCP clients.

The common model is: register UTCP manuals, search tools, synthesize language-native interfaces from JSON Schema, inject those tools into a sandbox namespace such as `github.get_pull_request`, execute agent-written code, and return `{ result, logs }`.

## Research Themes

- Token efficiency: High. The main idea is batching several tool calls and local data reduction into one sandbox execution so the model sees final summaries instead of full intermediate payloads.
- Context control: High. `search_tools`, generated interfaces, and runtime helpers (`__interfaces`, `__getToolInterface` in TypeScript; `interfaces`, `get_tool_interface` in Python) support progressive disclosure instead of dumping all tools.
- Sub-agent / multi-agent: Low. No sub-agent orchestration; useful as a shared tool bus beneath agents.
- Domain-specific workflow: Medium. UTCP manuals and protocol plugins make domain APIs feel like namespaced code libraries, but workflows are authored at runtime by the model.
- Error prevention: Medium. Type/interface generation, namespacing, console capture, and tests for async/error cases help; execution failures mostly return logs rather than typed diagnostics.
- Self-learning / memory: None. No persistent learning loop beyond interface caching inside a client instance.
- Popular skills: Tool discovery before execution, schema-to-type generation, code sandbox execution, MCP bridge design, output truncation, manual trust boundaries.

## Core Execution Path

TypeScript direct path:

1. `CodeModeUtcpClient.create(root_dir, config)` creates a base `UtcpClient`, then changes its prototype to `CodeModeUtcpClient` and initializes an interface cache.
2. `registerManual` and normal UTCP methods come from the base client. Tools are retrieved with `getTools`.
3. `getAllToolsTypeScriptInterfaces` converts each UTCP `Tool` JSON Schema into namespaced TypeScript input/output interfaces and access comments.
4. `callToolChain(code, timeout = 30000, memoryLimit = 128)` creates a fresh `isolated-vm` isolate and context.
5. The host injects console bridges, namespaced tool bridges, and interface helpers. Tool calls in the isolate use `applySyncPromise` to call host-side `this.callTool(toolName, args)` and return parsed JSON.
6. User code is wrapped as the body of an async function. Resolved return values are JSON-stringified back through a host callback; `undefined` normalizes to `null`.
7. Host timeout races result resolution. Syntax/runtime/tool errors return `{ result: null, logs: ["[ERROR] Code execution failed: ..."] }`; the isolate is disposed in `finally`.

MCP path:

1. `code-mode-mcp/index.ts` imports UTCP protocol plugins (`http`, `text`, `mcp`, `cli`, `dotenv-loader`, `file`) and starts an MCP stdio server.
2. It initializes a cached `CodeModeUtcpClient` from `UTCP_CONFIG_FILE`, `./.utcp_config.json`, or package-local `.utcp_config.json`.
3. It exposes MCP tools: `register_manual`, `deregister_manual`, `search_tools`, `list_tools`, `get_required_keys_for_tool`, `tools_info`, and `call_tool_chain`.
4. `search_tools` returns sanitized TypeScript tool names plus generated interfaces. `tools_info` maps either raw UTCP names or sanitized access names back to the underlying tool.
5. `call_tool_chain` invokes the TypeScript library, preserves MCP content blocks when returned, wraps non-MCP values plus logs in JSON text, and truncates output at `max_output_size`.

Python path:

1. `CodeModeUtcpClient.create` wraps `UtcpClientImplementation.create`.
2. `call_tool_chain(code, timeout = 30)` logs request metadata, fetches tools, and calls `_run_with_restricted_python`.
3. User code is wrapped in `def user_code_function(): ...`, compiled with `RestrictedPython`, and executed with `safe_globals`.
4. The context adds selected builtins, safe modules, `interfaces`, `get_tool_interface`, a `PrintCollector`, and namespaced synchronous tool functions.
5. Tool functions block on async UTCP calls using the current event loop or a helper thread. Errors become `RuntimeError` and outer failures return `{ "result": None, "logs": ["[ERROR] ..."] }`.

## Architecture

The repo is a thin code-execution layer over UTCP, not a full agent runtime. UTCP owns manual registration, protocol-specific calling, tool repositories, search strategies, and variable substitution. Code Mode owns the language binding: schema-to-interface generation, sandbox setup, tool bridge injection, runtime introspection, and result/log capture.

The strongest architectural choice is the namespaced function surface. A UTCP tool named `manual.tool` becomes `manual.tool(args)` in TypeScript/Python after identifier sanitization. This avoids global name collisions and gives the model a familiar library shape.

The MCP server acts as an adapter around the TypeScript library. It keeps the model-facing MCP tool count small: one execution tool plus discovery/inspection/admin helpers. That is the relevant pattern for Agentic Coding Lab: expose a compact meta-tool layer, not hundreds of raw tools.

## Design Choices

- Fresh isolate per TypeScript execution. This reduces cross-run contamination and makes timeout/memory parameters per call.
- Synchronous-looking tool calls. Both runtimes hide async bridge mechanics so generated code can read as straight-line workflow code.
- Runtime interface introspection. The sandbox can inspect all interfaces or one named tool, letting generated code adapt after discovery.
- JSON Schema to language types. The implementation supports common object, array, primitive, enum, and union-ish schema shapes; unsupported shapes fall back to `any`/`Any`.
- Result-plus-logs contract. The caller receives structured return value and captured console output, which is more useful than raw stdout alone.
- MCP output truncation. The bridge limits final text size to avoid flooding the MCP client, though the TypeScript library itself does not enforce result-size limits.
- Plugin side effects. The MCP bridge imports UTCP transport plugins at startup; adding a transport is an import/package change rather than a runtime registration call.

## Strengths

- Clear tool-use compression pattern: discover only relevant tools, then batch chained calls in one execution.
- TypeScript sandbox is a practical boundary for cooperative agent code: no direct Node APIs, memory limit, host-side timeout, and isolate disposal.
- Tool bridge keeps real credentials and protocol clients in the host; the sandbox only sees registered function handles.
- Generated interfaces convert tool schemas into a form coding models understand naturally.
- Tests cover chained tool calls, complex data structures, no-parameter tools, tool errors, syntax errors, infinite loops, async returns, rejected promises, hung promises, introspection, and console capture.
- MCP bridge includes useful operational tools for listing, searching, inspecting, and registering manuals.

## Weaknesses

- MCP bridge imports `@utcp/cli` by default. If a user registers an untrusted CLI manual, that manual can run arbitrary local commands through the host-side UTCP client.
- `register_manual` is exposed as an MCP tool, so the trust boundary depends on MCP client policy and user approval, not only code-mode sandboxing.
- TypeScript tool calls execute in the host process through `this.callTool`; sandboxing protects direct code execution but not the side effects of registered tools.
- TypeScript generated interfaces are hints, not validation. Runtime input validation is delegated to UTCP/tool implementations.
- Python implementation is less isolated than its README suggests. It uses `RestrictedPython` in-process and a thread executor; comments and tests acknowledge blocking synchronous code cannot be forcibly killed reliably.
- Python has no memory limit comparable to TypeScript `isolated-vm`.
- Documentation has some API drift: TypeScript README shows an options-object signature and `consoleOutput`/`getToolInterfaces`, while implementation uses positional `timeout`, `memoryLimit`, `logs`, and `getAllToolsTypeScriptInterfaces`.
- License metadata differs by package: root/TypeScript/Python are MPL-2.0, while `code-mode-mcp/package.json` says MIT.

## Ideas To Steal

- Build a "one execution tool plus discovery helpers" interface for coding agents. Keep raw tools behind a code-mode adapter.
- Require a discovery phase: `search_tools(query)` returns the smallest useful set plus exact callable names and schemas.
- Generate language-native interfaces from tool schemas and make them available both outside and inside the execution sandbox.
- Use namespaced access (`manual.tool(args)`) everywhere to avoid collisions and improve model reliability.
- Let agent code do local filtering, sorting, joining, and summarization inside the sandbox, then return a small result object.
- Capture logs separately from final result and preserve severity prefixes for monitoring.
- Normalize errors into result/log envelopes for recoverable agent workflows, but also include enough structured error detail for retry planning.
- Add output-size controls at the adapter boundary, not only in prompts.
- Treat tool manuals/plugins as the real authority boundary. Code sandbox policy and manual-registration policy must be designed together.

## Do Not Copy

- Do not expose arbitrary manual registration and CLI execution without a permission layer, allowlist, and visible provenance.
- Do not describe in-process Python `RestrictedPython` plus threads as production multi-tenant sandboxing.
- Do not rely on generated TypeScript/Python interfaces as runtime safety. Validate schemas before host tool execution.
- Do not let code-mode be the only sandbox if registered tools can access filesystem, shell, secrets, or network.
- Do not leave API docs drifting from implementation signatures; models will copy stale examples exactly.
- Do not return only stringified JSON from MCP if structured content can be preserved; keep structured result channels where possible.

## Fit For Agentic Coding Lab

This is highly relevant for tool-use design. The best fit is a local coding workflow where the agent receives:

- A small stable MCP surface: `search_tools`, `tools_info`, and `call_tool_chain`.
- A curated registry of safe coding tools: repo search, file read snippets, AST queries, test runners, package metadata, issue/PR fetchers.
- Strict manual allowlists and separate permission gates for shell, filesystem writes, network, and secrets.
- A result contract that encourages returning compact summaries, evidence paths, and verification status instead of full logs.

For Agentic Coding Lab, the TypeScript implementation is the better reference than Python. It provides a clearer isolate boundary and memory control. The Python version is still useful as a warning: cooperative LLM code sandboxes are not equivalent to adversarial sandboxes, especially when blocking code and host tool side effects are involved.

## Reviewed Paths

- `README.md`: Product-level model, MCP setup, direct TypeScript usage, multi-protocol examples, context-efficient processing, security claims, and benchmark framing.
- `typescript-library/README.md`: TypeScript package API, quick start, runtime context, tool access patterns, and isolated-vm security model.
- `typescript-library/src/code_mode_utcp_client.ts`: Main execution path, interface generation, identifier sanitization, isolated-vm setup, console bridge, host tool bridge, timeout/memory handling, and error handling.
- `typescript-library/src/index.ts`: Public package export.
- `typescript-library/tests/code_mode_utcp_client.test.ts`: Direct-call test manual, chained tool calls, interface generation, errors, timeouts, async result regression tests, and console capture.
- `typescript-library/package.json`, `typescript-library/tsconfig.json`, `typescript-library/tsup.config.ts`, `typescript-library/jest.config.cjs`: Package metadata, peer dependencies, build/test configuration, and runtime dependency boundaries.
- `python-library/README.md`: Python usage, protocol plugin notes, runtime introspection, RestrictedPython warning, and cooperative sandbox statement.
- `python-library/src/utcp_code_mode/code_mode_utcp_client.py`: Python wrapper, RestrictedPython execution context, safe imports, tool injection, print capture, timeout behavior, and base-client delegation.
- `python-library/src/utcp_code_mode/__init__.py`: Python public export and version.
- `python-library/tests/test_code_mode_utcp_client.py`: Python tests for schema conversion, simple execution, tool calls, interface access, errors, timeouts, restricted imports, builtins, and delegation.
- `python-library/pyproject.toml`: Python dependencies and packaging metadata.
- `code-mode-mcp/README.md`: MCP bridge setup, config shape, plugin/security notes, tool list, and development flow.
- `code-mode-mcp/index.ts`: MCP server startup, config loading, UTCP plugin imports, registered MCP tools, TypeScript code execution adapter, output truncation, and content-block handling.
- `code-mode-mcp/package.json`, `code-mode-mcp/tsconfig.json`, `code-mode-mcp/example.env`: MCP package metadata, dependencies, TypeScript config, and environment-example surface.

## Excluded Paths

- `typescript-library/package-lock.json` and `code-mode-mcp/package-lock.json`: Generated npm lockfiles. Dependency names and versions were reviewed through `package.json`; lockfile integrity details were not relevant to the execution design review.
- `code-mode-mcp/scripts/dev-register.mjs` and `code-mode-mcp/scripts/dev-unregister.mjs`: Local Claude Code development registration utilities. They affect developer setup, not the runtime MCP server or tool-call execution path under review.
- Remote README badges, YouTube thumbnail, and screenshot images: UI/marketing assets only. They do not define execution behavior, schemas, adapters, sandboxing, or error handling.
