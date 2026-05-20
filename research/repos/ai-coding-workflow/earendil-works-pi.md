# earendil-works/pi

- URL: https://github.com/earendil-works/pi
- Category: ai-coding-workflow
- Stars snapshot: 51,963 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 715c82ce0454b4fa9d6791bca22d6d694a2a0b28
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong source of reusable AI coding workflow patterns. Pi is most useful as a reference for runtime architecture, context loading, session trees, compaction, tool hooks, and verification loops; it is less useful as a direct skill library because many higher-level behaviors are intentionally left to extensions.

## Why It Matters

Pi is a compact but full AI coding-agent runtime rather than a prompt collection. It shows how to turn workflow policy into executable surfaces: project context discovery, typed resources, prompt templates, skills, session persistence, tool-call hooks, retry and compaction loops, and extension-based guardrails. That makes it a strong candidate for studying how reusable AI coding workflows can be encoded in a product without forcing every team into one built-in process.

The repo is also unusually explicit about what it refuses to bake into the core. Its docs and README say MCP, sub-agents, permission popups, plan mode, to-dos, and background bash are not default features; those are expected to be packages, extensions, or external tools. That boundary is valuable for Agentic Coding Lab because it separates durable runtime primitives from opinionated workflows that can be swapped per project.

## What It Is

Pi is a TypeScript monorepo for an AI agent toolkit. The important packages are `@earendil-works/pi-agent-core` for the generic agent loop and harness, `@earendil-works/pi-coding-agent` for the CLI/runtime, `@earendil-works/pi-ai` for provider abstraction, and `@earendil-works/pi-tui` for terminal UI. The coding agent exposes text, JSON, RPC, and interactive modes, with sessions, slash commands, skills, prompt templates, extensions, and package-installed resources.

The root `AGENTS.md` is itself a useful workflow artifact: it defines concise communication rules, file-reading expectations, TypeScript constraints, test commands, provider-addition checklists, release checklists, and parallel-agent git hygiene. The repo treats project instructions as operational guardrails rather than documentation-only prose.

## Research Themes

- Token efficiency: Pi uses compaction thresholds, token reserves, message serialization, output truncation, and branch summaries. Bash output is capped for model visibility, and tool results can point to full temporary output when truncated.
- Context control: The coding agent loads global and project context files, selected skills, prompt templates, settings, extensions, and session history into a structured system prompt. Session state is stored as JSONL tree history, and compaction inserts summaries while retaining recent context.
- Sub-agent / multi-agent: Sub-agents are not built into core. The example subagent extension launches isolated `pi --mode json -p --no-session` subprocesses with single, parallel, and chain execution modes, output caps, project-agent scope checks, and user confirmation for project-local agents in UI mode.
- Domain-specific workflow: Skills, prompt templates, slash commands, extension packages, settings, and context files let teams package coding workflows without modifying the core agent loop.
- Error prevention: The repo uses exact edit validation, non-overlap checks, per-file mutation queues, tool allowlists, extension hooks for permission gates and protected paths, retry classification, context-overflow handling, and tests around compaction and tool filtering.
- Self-learning / memory: Pi has durable session trees, branch summaries, compaction summaries, labels, exports, and share/import commands. It does not implement autonomous long-term memory; persistence is session-centered and user-navigable.
- Popular skills: The repo supports Agent Skills-style folders with `SKILL.md`, descriptions, optional model invocation disabling, and explicit `/skill:name` expansion. No popularity telemetry or skill ranking logic was found in the reviewed paths.

## Core Execution Path

Startup flows through the coding-agent CLI: parse flags, load settings and resources, resolve model/auth, load extensions, skills, prompt templates, themes, and context files, then create an `AgentSession`. The system prompt is rebuilt from the base prompt, appended system text, project context files such as `AGENTS.md` and `CLAUDE.md`, loaded skills, active tool snippets, and tool guidelines.

Prompt handling is ordered and extensible. A user prompt can first dispatch an extension slash command, pass through an `input` hook, expand a `/skill:name` command or prompt template, preflight model/auth, compact if near the context threshold, run a `before_agent_start` hook, then enter the agent loop. The loop streams assistant messages, validates tool arguments, executes tool calls, applies `beforeToolCall` and `afterToolCall` hooks, appends tool results, and prepares the next turn. Tool calls run in parallel unless global sequential mode or a sequential tool requires ordering.

After each run, Pi handles retryable provider/network errors with exponential backoff, detects context-window overflow once and compacts before retrying, persists message/session events, and continues queued `steer`, `followUp`, or `nextTurn` messages. Session tree navigation can summarize abandoned branches before moving the active leaf.

## Architecture

`packages/agent` contains the reusable agent core: the loop, typed tool definitions, harness resources, context hooks, compaction hooks, session repository abstractions, and system-prompt formatting. The core `Agent` exposes `prompt`, `continue`, `steer`, `followUp`, abort, idle waiting, and queue modes.

`packages/coding-agent` wires that core into a concrete coding agent. Important subsystems include CLI argument parsing, `AgentSession`, runtime construction, default tool factories, resource loading, settings management, session management, slash commands, compaction, and file tools. The runtime supports built-in tools (`read`, `bash`, `edit`, `write`, grep/find/ls-style helpers), custom tools, extension tools, and tool allowlists.

`packages/ai` abstracts model/provider calls. `packages/tui` and interactive-mode components provide UI surfaces around the same runtime. Examples under `examples/extensions` demonstrate optional policy and workflow layers such as permission gates, protected paths, custom compaction, dirty-repo guards, sandboxed bash, and subagents.

## Design Choices

Pi keeps the agent core small and moves opinionated workflow into resources and extensions. This makes the runtime adaptable: teams can add skills, prompts, settings, tools, hooks, and packages without changing the main loop.

Project context is layered deliberately. The coding-agent resource loader reads global agent instructions and ancestor project context files from root to current working directory, then wraps them into the system prompt. This provides predictable inheritance for monorepos and nested projects.

The session model is tree-shaped rather than flat. Every session entry has identity and parentage, the active leaf can move, and branch summaries preserve context from abandoned paths. This supports exploration without pretending every branch of an agent conversation is linear ground truth.

Tool safety is implemented through precise mechanics rather than only instructions. Edits require exact text, multi-edits are checked against the original file, overlapping edits are rejected, BOM and line endings are preserved, and file writes/edits are serialized per real path. Policy examples then build on top of that with permission and sandbox extensions.

## Strengths

- First-class workflow resources: skills, prompt templates, context files, settings, slash commands, and extensions are all explicit runtime concepts.
- Strong context machinery: session trees, compaction summaries, branch summaries, file tracking, and threshold-based compaction give the model durable but bounded state.
- Practical verification loop support: the root instructions document when to run `npm run check`, specific Vitest invocations, provider test patterns, release checks, and parallel-agent git rules.
- Extensible guardrails: hooks can inspect or modify provider payloads, context, tool calls, tool results, session compaction, and tree navigation.
- Tool execution discipline: argument validation, sequential-tool support, ordered parallel results, exact edit checks, output truncation, and per-path mutation queues reduce common coding-agent failure modes.
- Good harness tests: faux-provider tests cover prompt/tool loops, skill expansion, template expansion, compaction, retry behavior, queued messages, and tool allowlist filtering.

## Weaknesses

- Important safety features are optional. Permission prompts, protected paths, sandboxed bash, dirty-repo guards, and subagents live as examples or extensions, not default policy.
- Installed extensions, packages, and skills are powerful and require trust. The docs warn about security, but the runtime still depends on package review and local execution boundaries.
- The architecture is broader than many teams need. Copying the whole runtime would add significant surface area if the goal is only project instructions or a few reusable skills.
- Compaction summaries are useful but lossy. The repo mitigates this with recent-message retention and file tracking, but downstream workflows still need to treat summaries as context, not proof.
- UI/TUI code dominates some surface area but contributes little to reusable AI coding workflow patterns beyond interaction affordances.

## Ideas To Steal

- Load global and ancestor project instruction files deterministically, then render them as structured project context in the system prompt.
- Treat skills and prompt templates as resources with metadata, validation, argument expansion, and explicit invocation commands.
- Provide `steer`, `followUp`, and `nextTurn` queues so users and extensions can inject work at well-defined turn boundaries.
- Persist sessions as JSONL trees with parent pointers, active leaves, branch summaries, labels, and compaction entries.
- Track read and modified files inside compaction summaries so resumed agents know which files require re-reading before edits.
- Use exact-edit tools with uniqueness checks, non-overlap checks, line-ending preservation, diff details, and per-file mutation queues.
- Put policy in hookable extension surfaces: `input`, `context`, `before_provider_request`, `before_provider_payload`, `tool_call`, `tool_result`, compaction, and session tree events.
- Implement subagents as isolated subprocesses with explicit prompt files, bounded output, concurrency limits, and project-agent confirmation instead of merging subagent state into the parent context.
- Keep a faux-provider harness for deterministic tests of agent loops, compaction, queues, and tool-call behavior.

## Do Not Copy

- Do not rely on extension examples as sufficient security for a production coding agent; make permission, sandbox, and path policies explicit for the deployment.
- Do not install remote skill/extension packages without review. Pi's package system is flexible, but trust and provenance remain workflow responsibilities.
- Do not copy the full UI/TUI stack if the research goal is headless agent workflow. The reusable patterns live mostly in the harness, resource loader, session manager, compaction code, tools, and extension interfaces.
- Do not treat compaction summaries or branch summaries as authoritative facts after long-running work; force re-reading of critical files before modification.
- Do not make project-local subagents active by default. Pi's confirmation and scope metadata are worth preserving.
- Do not expose unrestricted `write`/`bash` equivalents without tool allowlists, protected-path policy, or a sandbox boundary.

## Fit For Agentic Coding Lab

Pi is a strong reviewed candidate for the AI coding workflow category. It is most valuable as a pattern library for runtime primitives: instruction discovery, skill/resource loading, command expansion, tool hooks, queueing, session trees, compaction, and deterministic tests around agent behavior.

It should be referenced as an architecture and workflow-control source, not as a drop-in answer to every coding-agent feature. Its philosophy is deliberately anti-kitchen-sink: advanced workflows such as subagents, MCP-like integrations, permissions, planning, and to-dos should be composable layers. That design direction fits Agentic Coding Lab if we want reusable patterns that can be adopted independently.

## Reviewed Paths

- `README.md`
- `AGENTS.md`
- `CONTRIBUTING.md`
- `package.json`
- `packages/agent/package.json`
- `packages/agent/src/agent.ts`
- `packages/agent/src/agent-loop.ts`
- `packages/agent/src/harness/agent-harness.ts`
- `packages/agent/src/harness/types.ts`
- `packages/agent/src/harness/system-prompt.ts`
- `packages/agent/src/harness/prompt-templates.ts`
- `packages/agent/src/harness/skills.ts`
- `packages/agent/src/harness/session/*`
- `packages/agent/src/harness/compaction/*`
- `packages/coding-agent/package.json`
- `packages/coding-agent/src/cli.ts`
- `packages/coding-agent/src/main.ts`
- `packages/coding-agent/src/cli/args.ts`
- `packages/coding-agent/src/core/sdk.ts`
- `packages/coding-agent/src/core/agent-session.ts`
- `packages/coding-agent/src/core/system-prompt.ts`
- `packages/coding-agent/src/core/resource-loader.ts`
- `packages/coding-agent/src/core/skills.ts`
- `packages/coding-agent/src/core/prompt-templates.ts`
- `packages/coding-agent/src/core/slash-commands.ts`
- `packages/coding-agent/src/core/settings-manager.ts`
- `packages/coding-agent/src/core/session-manager.ts`
- `packages/coding-agent/src/core/tools/bash.ts`
- `packages/coding-agent/src/core/tools/edit.ts`
- `packages/coding-agent/src/core/tools/edit-diff.ts`
- `packages/coding-agent/src/core/tools/write.ts`
- `packages/coding-agent/src/core/tools/file-mutation-queue.ts`
- `packages/coding-agent/src/core/tools/read.ts`
- `packages/coding-agent/src/core/compaction/*`
- `packages/coding-agent/test/suite/harness.ts`
- `packages/coding-agent/test/agent-session-prompt.test.ts`
- `packages/coding-agent/test/agent-session-compaction.test.ts`
- `packages/coding-agent/test/regression/2835-tools-allowlist-filters-extension-tools.test.ts`
- `packages/coding-agent/test/skills.test.ts`
- `packages/coding-agent/test/prompt-templates.test.ts`
- `docs/usage.md`
- `docs/skills.md`
- `docs/extensions.md`
- `docs/sessions.md`
- `docs/compaction.md`
- `docs/settings.md`
- `docs/sdk.md`
- `docs/packages.md`
- `examples/extensions/subagent/*`
- `examples/extensions/permission-gate.ts`
- `examples/extensions/protected-paths.ts`
- `examples/extensions/sandbox/index.ts`
- `examples/extensions/custom-compaction.ts`
- `examples/extensions/dirty-repo-guard.ts`
- GitHub REST API response for repository metadata on 2026-05-20

## Excluded Paths

- `.git/**` and local repository metadata were not reviewed.
- `node_modules/**`, package manager caches, and generated install output were not present in the reviewed source tree and were excluded if encountered.
- Lockfiles and shrinkwrap files such as package lock artifacts were not deep-reviewed because dependency pinning was not the research focus.
- `packages/ai/src/models.generated.ts` was excluded as generated model metadata, consistent with the repo's own contributor instructions.
- Provider implementation details under `packages/ai/src/providers/**` were sampled only for architecture context; individual model conversion code was not deeply reviewed.
- UI-only implementation details in `packages/tui/**` and interactive rendering components were excluded except where they documented workflow surfaces.
- Binary, image, and demo assets were excluded, including docs images and the Doom overlay example's built game artifacts such as `doom.wasm` and generated JavaScript.
- Vendored browser export libraries under HTML export support were excluded as third-party UI/export implementation detail.
