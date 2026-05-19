# parcadei/Continuous-Claude-v3

- URL: https://github.com/parcadei/Continuous-Claude-v3
- Category: context-control
- Stars snapshot: 3,768 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: d07ff4b06b62f43771bc0c927d0211b734d6149e
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong context-control reference. Steal the lifecycle hooks, schema-first handoffs, TLDR read/search routing, and file-backed agent outputs; do not copy the global install model or assume its MCP path is sandboxed by default.

## Why It Matters

Continuous Claude is one of the clearest public examples of a Claude Code environment treating context as managed runtime state rather than a transcript side effect. Its main thesis is "compound, don't compact": preserve durable ledgers, handoffs, memory, active-session state, and structured code summaries so agents can resume work without dumping full history back into the prompt.

For Agentic Coding Lab, the value is not the complete distribution. The useful part is the control loop: hooks observe session lifecycle and tool usage, route token-heavy operations to summaries, write explicit workflow state to files/databases, and make resumed sessions consume a small stable contract instead of raw conversation.

## What It Is

The repo is a full Claude Code customization bundle. It includes global `.claude` settings, hooks, skills, agents, MCP configuration, a Python MCP execution runtime under `opc/`, a PostgreSQL coordination schema, TLDR code-analysis infrastructure, memory docs, and setup scripts that install or symlink the bundle into `~/.claude`.

The reviewed execution surface is:

- Claude Code hooks from `.claude/settings.json`.
- TypeScript hook implementations in `.claude/hooks/src/`.
- Continuity skills in `.claude/skills/create_handoff/` and `.claude/skills/continuity_ledger/`.
- Agent isolation skills and example agents under `.claude/skills/` and `.claude/agents/`.
- MCP runtime and wrapper generation under `opc/src/runtime/`.
- Setup, database, and safety scripts under `opc/scripts/` and `opc/docker/`.

## Research Themes

- Token efficiency: Very strong. `tldr-read-enforcer`, `smart-search-router`, and `tldr-context-inject` intercept `Read`, `Grep`, and `Task` calls, replacing broad source reads with AST/call-graph/CFG/DFG/PDG summaries and narrow offset/limit escapes. The status line tracks context percentage per session.
- Context control: Core theme. Session start restores recent handoffs, pre-compact writes auto handoffs, stop hooks force handoff creation near context limits, status line surfaces `goal -> now`, and ledgers preserve cross-session decisions.
- Sub-agent / multi-agent: Strong but internally mixed. Agents are expected to write summaries/checkpoints to `.claude/cache/agents/<agent>/` and handoff directories, avoiding transcript-heavy `TaskOutput`; another local skill says to avoid `TaskOutput` by using synchronous `Task`, so the project needs a single sharper contract.
- Domain-specific workflow: Broad. It includes TDD agents, refactor impact hooks, TypeScript/Python/Lean diagnostics, math/proof workflows, and research pipeline scripts. The context-control ideas are reusable, but the full domain bundle is too wide for a focused lab runtime.
- Error prevention: Strong coverage with fail-open caveats. Rules cover destructive commands and claim verification. Hooks run TypeScript preflight, Python diagnostics, import checks, Lean/compiler loops, impact analysis, and file-claim warnings. Several checks are heuristic or skip when optional scripts/services are absent.
- Self-learning / memory: Strong design. Docs describe archival memory, temporal facts, hybrid retrieval, and PostgreSQL/SQLite backends. User prompts trigger memory-awareness reminders; session outcomes and handoffs feed the durable record.
- Popular skills: The practical patterns are `create_handoff`, `continuity_ledger`, `agent-context-isolation`, `parallel-agent-contracts`, `tdd-migration-pipeline`, and TLDR-backed code navigation. These are better mined as small workflow skills than imported as a monolithic skill library.

## Core Execution Path

The default path starts in `.claude/settings.json`. On `SessionStart`, hooks persist the project directory, register the session, warm TLDR state, and run `session-start-continuity`. A startup session gets a brief status reminder; resume, compact, or clear paths inject the latest relevant handoff/ledger into context. The lookup prefers `thoughts/shared/handoffs/<session>/` YAML with `goal` and `now`, then falls back to older ledger files.

During prompts, `skill-activation-prompt` matches natural language against `skill-rules.json`, while memory, premortem, and refactor-impact hooks add narrow reminders. Before tools run, hooks control expensive reads and searches: `tldr-read-enforcer` blocks broad reads of code files and returns TLDR context; `smart-search-router` classifies search intent and may deny literal/structural grep in favor of TLDR or AST search; `tldr-context-inject` adds code-structure context to subagent prompts.

After edits, verification hooks run diagnostics where available and update trackers. File claims warn when another active session already owns a file. At compaction, `pre-compact-continuity` parses the JSONL transcript, recent todos, tool calls, modified files, errors, and last assistant message, then writes an auto handoff and appends the ledger. On stop, `auto-handoff-stop.py` blocks when the per-session context percentage is at or above 85%, telling the user to run `/create_handoff`.

MCP execution follows a separate runtime under `opc/src/runtime/`. `harness.py` loads `.env`, initializes MCP servers, runs the target script with `runpy.run_path`, and cleans up connections. `mcp_client.py` lazily connects enabled stdio/SSE/HTTP servers from global and project config, validates `server__tool` identifiers, retries failed calls once, and unwraps content. Wrapper generation creates typed Python functions that call `call_mcp_tool(...)`.

## Architecture

The system has five practical layers.

The hook layer is the control plane. It receives Claude Code lifecycle events and decides whether to inject context, block a tool call, update a state file, or write a durable artifact. It uses temp files under `/tmp` for per-session context percentage and recent search intent, `.claude/cache` for agent outputs and hook state, and `thoughts/` for project-visible handoffs and ledgers.

The continuity layer is file-first. Handoffs use a stable YAML schema with `goal`, `now`, `test`, `done_this_session`, `blockers`, `questions`, `decisions`, `findings`, `worked`, `failed`, `next`, and `files`. The status line consumes `goal -> now`; resume hooks consume the same fields. This makes the handoff format a runtime contract, not just documentation.

The code-intelligence layer is TLDR. It describes code through layered summaries: AST, call graph, control-flow graph, data-flow graph, and program-dependence graph. A per-project daemon socket under `/tmp/tldr-<hash>.sock` serves hook queries. Hooks use the daemon to steer reads, search, Task prompts, diagnostics, and refactor impact checks.

The coordination layer is PostgreSQL plus local files. The schema tracks sessions, file claims, archival memory, handoffs, findings, agents, broadcasts, and artifacts. `session-register` and `file-claims` give parallel Claude instances awareness of one another, but claims warn rather than lock.

The MCP layer is a Python runtime around MCP servers. It separates external tool execution from the chat prompt and generates wrappers, but the default script harness is direct in-process execution. A Docker sandbox runner exists separately, yet it is not wired into the default `runtime.harness.py` path.

## Design Choices

The strongest design choice is making handoffs machine-readable and status-line-visible. A handoff is not an essay; it is a schema consumed by hooks. This makes context restoration predictable and lets a resumed agent know the current goal, state, validation command, blockers, failed attempts, and next step without transcript replay.

The second strong choice is enforcing context policy at tool boundaries. Broad code reads and low-signal searches are intercepted before they spend context. The hooks return structured alternatives and still allow narrow `Read` ranges, config files, tests, hooks, skills, migrations, and small files. That gives the model a way forward instead of a hard dead end.

Another useful choice is cross-hook state. `smart-search-router` writes recent search intent to `/tmp/claude-search-context/<session>.json`; `tldr-read-enforcer` later uses it to choose TLDR layers and targets. `status.py` writes context percentage to `/tmp/claude-context-pct-<session>.txt`; stop hooks use that to decide when to force handoff creation.

The setup design favors power over containment. The wizard backs up `~/.claude`, can replace or symlink hooks, skills, rules, agents, servers, scripts, and MCP config, and may modify shell profile files. That makes for a cohesive personal environment but is too invasive for a shared research repo without tighter packaging.

## Strengths

The continuity workflow is concrete and executable. `create_handoff` and `continuity_ledger` define exact fields, resume hooks know how to find them, and status display reinforces keeping them current.

The token-control hooks operate where waste actually happens: before `Read`, `Grep`, and subagent calls. The model gets a structured replacement context instead of relying on prompt instructions to remember good behavior.

The project has real multi-session thinking. Session registration, file claims, broadcast tables, handoff directories, and agent cache outputs all point toward parallel work without sharing entire conversations.

The MCP runtime avoids loading every server/tool result into the prompt. It lazy-connects, validates names, retries calls, and can generate typed wrappers so scripts invoke tools through a small API.

Safety and verification are distributed through hooks and rules rather than one checklist. Destructive-command rules, claim-verification rules, compiler hooks, import checks, and outcome-marking all push toward evidence-backed work.

## Weaknesses

The repo overclaims execution isolation if read casually. `opc/src/runtime/harness.py` explicitly runs scripts in direct mode in the current process. Docker sandbox code exists, but the default MCP/script harness does not enforce container isolation.

The install model is global and high-blast-radius. It copies or symlinks a large `.claude` tree into `~/.claude`, backs up and replaces existing integration directories, and can edit shell startup files. That is risky for a lab where multiple experiments need side-by-side isolation.

Several safeguards are advisory or fail open. `path-rules.ts` injects skill guidance but does not block paths, despite docs describing enforcement. File claims warn but do not lock. Diagnostics skip when optional daemons or scripts are unavailable.

The implementation has shell-string execution surfaces in hooks and daemon clients. Some commands are constructed with interpolated paths or patterns. A lab version should prefer argv-based `spawn` calls and stricter path validation.

The repo mixes core context-control with a large math/proof/domain environment. That makes discovery harder and hides the smallest viable pattern under many optional systems.

Docs and source have inconsistencies. Examples include different agent counts, different savings claims, and memory embedding dimensions that vary across docs and schema. The practical workflow is still clear, but adoption should follow source behavior, not headline numbers.

## Ideas To Steal

Use a schema-first handoff file as a runtime API. Require stable fields for current goal, current state, validation command, blockers, known failures, next action, and touched files. Make status display and resume logic consume the same schema.

Install lifecycle hooks as a context state machine: `SessionStart` restores, `UserPromptSubmit` routes skills and memory, `PreToolUse` controls high-token operations, `PreCompact` writes emergency state, `Stop` blocks when handoff debt is high.

Route source-code reads through structured summaries. A useful policy is "deny broad source read, return code map, allow narrow line range." This gives the agent enough information to choose targeted reads.

Use tiny state files as cross-hook signals. Context percentage, recent search intent, active session ID, and current handoff pointer do not need to live in the model prompt.

Make agents write durable outputs to files and report file paths, not transcripts. Pair that with explicit checkpoint states such as `PENDING`, `IN_PROGRESS`, `VALIDATED`, and `FAILED`.

Add file-claim warnings for parallel sessions. A soft warning is enough for research workflows and avoids blocking legitimate coordinated edits.

Treat generated MCP wrappers as a prompt-compression device. Scripts call small typed functions; the chat does not need full tool schemas and results in context.

## Do Not Copy

Do not copy the global `~/.claude` takeover as the default install. Package experiments project-locally first, with an explicit opt-in bridge to global Claude Code settings.

Do not describe MCP execution as sandboxed unless the sandbox is on the actual execution path. Direct in-process harness execution and optional Docker code are different security properties.

Do not rely on advisory hooks as security boundaries. Path rules, file claims, and diagnostics are useful guidance but need explicit blocking semantics if they are meant to enforce policy.

Do not import the whole skill library. The Agentic Coding Lab should extract small, named patterns around continuity, TLDR routing, agent output contracts, and verification.

Do not keep conflicting agent-output rules. Pick one contract for background agents, synchronous agents, and output retrieval so users cannot accidentally reintroduce transcript bloat.

Do not build shell commands from raw strings in hook paths that process user/project input. Prefer argv-based spawning, allowlisted commands, and normalized project-relative paths.

## Fit For Agentic Coding Lab

This repo is a high-fit reference for the context-control category. The best lab adaptation is a smaller "context runtime" that combines handoff schema, lifecycle hooks, context-budget status, TLDR-style code summaries, and file-backed agent outputs.

The lab should not adopt Continuous Claude as a product dependency. It should translate the patterns into repo-local instructions and tests:

- A handoff schema fixture with parser tests.
- A session-start restore command that loads exactly one latest handoff.
- A pre-read policy that proves broad reads are replaced with code summaries.
- A stop/pre-compact policy that writes or requires a handoff at a threshold.
- A subagent contract that requires output files and verification evidence.
- A coordination shim for soft file claims.

The central lesson is that context control works best when encoded into the tool lifecycle, not as another prompt paragraph.

## Reviewed Paths

- `README.md` for repo purpose, setup, component overview, "compound, don't compact", anti-complexity notes, and continuity examples.
- `docs/ARCHITECTURE.md` for hook, agent, TLDR, memory, file persistence, and database architecture.
- `docs/MULTI-SESSION-ARCHITECTURE.md` for workflow checkpoint semantics, status-line behavior, and per-instance context percentage.
- `docs/hooks/README.md` for hook event map and intended safety/control behavior.
- `docs/skill-activation.md` for natural-language skill matching and context-threshold reminders.
- `docs/tools/memory.md` for archival memory, temporal facts, backend choices, and retrieval design.
- `docs/TLDR.md` for layered code summaries, daemon design, cache strategy, and semantic search.
- `.claude/settings.json` for actual Claude Code hook registration and MCP/status-line wiring.
- `.claude/mcp_config.json` for enabled and disabled MCP servers and command-based server launch design.
- `.claude/skills/create_handoff/SKILL.md` for the required YAML handoff contract and outcome-marking workflow.
- `.claude/skills/continuity_ledger/SKILL.md` for ledger naming, handoff creation, and state compaction guidance.
- `.claude/skills/agent-context-isolation/SKILL.md`, `.claude/skills/no-task-output/SKILL.md`, `.claude/skills/parallel-agent-contracts/SKILL.md`, and `.claude/skills/tdd-migration-pipeline/SKILL.md` for agent-output and multi-agent workflow contracts.
- `.claude/agents/kraken.md` for an example implementation agent using handoff checkpoints and file-backed output.
- `.claude/hooks/src/session-start-continuity.ts`, `pre-compact-continuity.ts`, `transcript-parser.ts`, `auto-handoff-stop.py`, and `status.py` for continuity, status, and context-threshold execution.
- `.claude/hooks/src/tldr-read-enforcer.ts`, `smart-search-router.ts`, `tldr-context-inject.ts`, and `daemon-client.ts` for token-control execution paths.
- `.claude/hooks/src/session-register.ts`, `file-claims.ts`, and `shared/db-utils-pg.ts` for session and file-claim coordination.
- `.claude/hooks/src/typescript-preflight.ts`, `post-edit-diagnostics.ts`, `import-validator.ts`, `compiler-in-the-loop.ts`, `impact-refactor.ts`, and `path-rules.ts` for verification, diagnostics, and safety behavior.
- `.claude/hooks/src/__tests__/findSessionHandoff.test.ts`, `mainHandoffFirst.test.ts`, `extractLedgerSection.test.ts`, `session-id-persistence.test.ts`, `session-affinity.test.ts`, and `tldr-hooks.test.ts` for local test coverage and gaps.
- `opc/pyproject.toml`, `opc/src/runtime/config.py`, `mcp_client.py`, `harness.py`, and `generate_wrappers.py` for MCP runtime architecture.
- `opc/scripts/setup/wizard.py` and `opc/scripts/setup/claude_integration.py` for install, backup, merge, and risk-acknowledgement behavior.
- `opc/docker/Dockerfile.sandbox`, `opc/docker/sandbox_runner.py`, `opc/docker/docker-compose.yml`, and `opc/docker/init-schema.sql` for sandbox code and database schema.
- `opc/scripts/mcp/github_search.py`, `opc/scripts/mcp/perplexity_search.py`, and `opc/scripts/test_research_pipeline.py` for MCP/script examples and test harness patterns.
- `.claude/rules/destructive-commands.md`, `.claude/rules/claim-verification.md`, and `.claude/rules/proactive-memory-disclosure.md` for safety and disclosure rules.
- `.tldrignore` for the project's own generated/vendor/binary/context-artifact exclusion policy.

## Excluded Paths

- `.git/**` was excluded as version-control metadata; the reviewed commit records the exact source state instead.
- `.claude/hooks/dist/**` was excluded because it is generated JavaScript bundle output from the reviewed TypeScript sources in `.claude/hooks/src/**`.
- `.claude/transcripts/**`, `.claude/backup/**`, `.claude/cache/**`, `*.bak`, `*.backup`, and other session artifacts were excluded as generated or historical local state rather than maintained design source.
- `.claude/chrome/chrome-native-host` and binary/native-host artifacts were excluded as binary integration files with no useful context-control logic for this review.
- Dependency and build-output paths listed by the repo's own `.tldrignore`, such as dependency directories, generated caches, logs, databases, build artifacts, and lock/pid files, were excluded as vendor/generated/runtime output.
- `proofs/**`, math-heavy skill subtrees, and Lean proof examples were mostly excluded because they are domain examples. I only used them where they showed verification-loop design.
- Optional disabled-provider details for Firecrawl, Morph, Perplexity, NIA, ast-grep, and RepoPrompt were not deeply reviewed beyond configuration and execution-path relevance because the context-control design does not depend on those providers being enabled.
- No dedicated UI-only application path was relevant. The repo is primarily hooks, CLI scripts, docs, agents, and runtime code.
