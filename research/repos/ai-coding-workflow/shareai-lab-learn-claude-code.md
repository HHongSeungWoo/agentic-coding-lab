# shareAI-lab/learn-claude-code

- URL: https://github.com/shareAI-lab/learn-claude-code
- Category: ai-coding-workflow
- Stars snapshot: 61,518 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: c354cf7721d7f80ec961d4820798bfc2f004365e
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value teaching repo for coding-agent harness mechanics. Best reusable pieces are the progressive "same loop, new capability" layering, dispatch-map tools, on-demand skill loading, context compression, file-backed task graph, JSONL teammate mailboxes, request-id protocols, idle auto-claiming, and task-bound worktree isolation. Do not treat it as a production harness without stronger permission, locking, verification, and sandbox controls.

## Why It Matters

`learn-claude-code` is useful because it turns Claude Code-like behavior into small, inspectable reference implementations. The repo is not mainly a prompt pack or UI. It is a sequence of Python harnesses that show how a coding agent grows from one `bash` tool into a multi-agent, task-aware, worktree-isolated system.

For Agentic Coding Lab, the strongest value is pattern extraction. Each session adds one harness mechanism while keeping the agent loop recognizable. That makes it easy to see what belongs to the model, what belongs to the harness, and which state should move out of chat into files.

The repo also matters as a boundary example. It intentionally omits production-grade hooks, permissions, MCP runtime details, session lifecycle controls, and rule-based governance. That honesty makes the patterns clearer, but it also means the code should be copied as a teaching fixture, not as a safety baseline.

## What It Is

This is a multilingual educational repo for building a minimal Claude Code-style coding-agent harness. The main artifacts are:

- `agents/s01_agent_loop.py` through `agents/s12_worktree_task_isolation.py`: progressive Python scripts, each adding one mechanism.
- `agents/s_full.py`: capstone that combines s01 through s11 into one reference agent.
- `docs/en`, `docs/zh`, and `docs/ja`: session explanations and diagrams.
- `skills/*/SKILL.md`: example on-demand skills for agent building, code review, MCP server building, and PDF work.
- `web/`: Next.js visualization site that extracts source/docs into generated data and displays the learning path.
- `tests/`: small smoke tests for Python compilation and one background-task edge case.

The repo uses Anthropic's Messages API shape, but supports Anthropic-compatible providers through `ANTHROPIC_BASE_URL` and `MODEL_ID`. The quick-start path is `pip install -r requirements.txt`, copy `.env.example`, then run individual scripts such as `python agents/s01_agent_loop.py`, `python agents/s12_worktree_task_isolation.py`, or `python agents/s_full.py`.

## Research Themes

- Token efficiency: Strong conceptual coverage. s05 keeps only skill names/descriptions in the system prompt and returns full skill bodies through `load_skill`. s06 uses micro-compaction, transcript-backed summarization, and a manual compact tool. Subagents return summaries instead of full child histories. Persistent tasks, team state, and worktree indexes move coordination state out of chat.
- Context control: Strong teaching pattern. s04 isolates noisy exploration in child `messages` arrays. s06 clears old non-reference tool results and stores full transcripts. s07 makes `.tasks/` durable across compaction. s11 re-injects teammate identity after compressed or short contexts.
- Sub-agent / multi-agent: Strong progression. s04 shows disposable subagents with fresh context and summary-only return. s09 adds persistent teammates with JSONL inboxes. s10 adds structured request-response protocols. s11 adds idle polling and auto-claiming. s12 separates execution directories by task-bound git worktrees.
- Domain-specific workflow: Moderate. The base domain is coding-agent harness engineering. The skill examples show how domain workflows can be packaged, but most local skills are generic examples rather than battle-tested project skills.
- Error prevention: Useful but incomplete. The repo has path sandboxing, exact-text edits, command timeouts, small dangerous-command deny lists, one-active-todo validation, task dependency unblocking, worktree name validation, request IDs, and lifecycle events. It lacks hard permission governance, pre-tool hooks, robust shell sandboxing, atomic mailbox/task writes, and broad automated tests.
- Self-learning / memory: Mostly externalized state, not adaptive memory. Durable artifacts include `.tasks/`, `.team/config.json`, JSONL inboxes, `.transcripts/`, `.worktrees/index.json`, and `.worktrees/events.jsonl`. There is no curation loop for long-term project memory.
- Popular skills: No usage telemetry was present. The reusable skill specimens are `agent-builder`, `code-review`, `mcp-builder`, and `pdf`; their main research value is showing frontmatter plus body packaging for on-demand loading.

## Core Execution Path

The core loop appears first in s01:

1. Append the user prompt to `messages`.
2. Call `client.messages.create` with `system`, `messages`, and `tools`.
3. Append the assistant response.
4. If `stop_reason` is not `tool_use`, return.
5. Execute each requested tool, append `tool_result` blocks as a user message, and loop.

The repo then adds mechanisms without changing that basic shape:

1. s02 adds `read_file`, `write_file`, and `edit_file` through `TOOL_HANDLERS`, plus `safe_path()` workspace containment.
2. s03 adds `TodoManager`, one `in_progress` item, and a reminder after several non-todo rounds.
3. s04 adds a `task` tool that spawns a fresh child conversation and returns only final text to the parent.
4. s05 adds `SkillLoader`, which scans `skills/**/SKILL.md`, puts metadata in the system prompt, and returns full bodies through `load_skill`.
5. s06 adds three compaction layers: clear older tool outputs, summarize and replace large conversations, and expose a manual compact tool.
6. s07 adds file-backed tasks in `.tasks/task_<id>.json` with status, owner, and `blockedBy` dependencies.
7. s08 adds background command threads and injects completion notifications before later LLM calls.
8. s09 adds named teammate threads, `.team/config.json`, append-only JSONL inboxes, direct messages, and broadcast.
9. s10 adds shared request-id protocol shape for shutdown and plan approval.
10. s11 adds autonomous teammates that idle, poll inbox/tasks, claim unowned unblocked tasks, and resume work.
11. s12 binds persistent tasks to git worktrees under `.worktrees/`, adds a worktree index, and emits lifecycle events.
12. `s_full.py` combines s01 through s11 in one file with base tools, TodoWrite, subagents, skill loading, compression, background work, persistent tasks, teams, protocols, idle, and task claiming.

## Architecture

The architecture is intentionally filesystem-native and small:

- `agents/`: executable Python harness examples. Each file is standalone and repeats enough code to be understood independently.
- `docs/<locale>/`: mental-model docs for each session, with problem, solution, diagrams, code excerpts, and "try it" prompts.
- `skills/`: example `SKILL.md` directories. s05 and `s_full.py` discover these at runtime.
- `tests/`: smoke tests. One parametrized test compiles all agent scripts; another loads `s_full.py` with fake Anthropic/dotenv modules and checks background-task output.
- `web/`: Next.js app. `web/scripts/extract-content.ts` reads `agents/` and `docs/`, extracts versions, tools, classes, functions, diffs, and docs into `web/src/data/generated/`.
- `.env.example`: runtime model/provider configuration.
- `.github/workflows/ci.yml`: web-only CI using Node 20, `npm ci`, TypeScript check, and Next build.

There is no MCP server runtime, plugin manifest, command directory, permission policy engine, or hook bus. The closest hook-like design is s12's append-only worktree event log.

## Design Choices

The strongest design choice is progressive layering. Every session makes one capability explicit, so a reader can see the smallest useful implementation of that concept.

The second choice is the dispatch-map pattern. Adding a tool means adding one schema and one handler. This keeps the LLM loop simple and makes each capability inspectable.

The third choice is file-backed coordination. Tasks, team roster, inboxes, transcripts, worktree indexes, and events live on disk instead of inside conversation history. This is the main reusable context-control pattern.

The fourth choice is summary-return isolation. Subagents and background tasks keep noisy work out of the parent loop by returning a summary, task ID, or notification.

The fifth choice is typed-enough protocols without heavy infrastructure. JSON files, JSONL inboxes, task IDs, `blockedBy`, request IDs, and worktree names are simple enough for a teaching harness but structured enough to show coordination contracts.

The sixth choice is explicit non-goals. The README calls out omitted production mechanisms such as full event/hook buses, rule-based permissions, resume/fork lifecycle controls, and full MCP runtime details.

## Strengths

- Very clear progression from one-loop agent to multi-agent worktree isolation.
- Strong reusable vocabulary for separating model agency from harness mechanisms.
- Good context-budgeting examples: on-demand skills, subagent summaries, micro-compaction, transcript-backed compaction, and external task state.
- Task graph and worktree binding are practical patterns for future coding-agent coordination.
- JSONL mailboxes and request-id protocols are easy to test and easy for models to reason about.
- s12's task/control-plane versus worktree/execution-plane split is a useful mental model for parallel coding work.
- `web/scripts/extract-content.ts` makes the teaching site source-driven instead of hand-maintained.
- Local Python source compiles with `python -m compileall -q agents tests`.

## Weaknesses

- Security controls are teaching-grade. `subprocess.run(..., shell=True)` plus substring deny lists should not be treated as a real sandbox.
- Permission governance is mostly absent. There are no PreToolUse checks, approval workflows, trust levels, or hard policy boundaries.
- File coordination is not production-safe. Task files, JSONL inboxes, config, and worktree index writes are simple writes with limited locking or recovery.
- Protocol trackers for shutdown and plan approval are in memory, so request state is lost across process restarts.
- Background and teammate loops use daemon threads. That is simple, but it gives weak lifecycle control, cancellation, and cleanup guarantees.
- Testing is narrow. The repo mostly checks syntax and one small background-manager behavior; it does not run simulated model loops or validate task/team/worktree state machines.
- `s_full.py` intentionally excludes s12 and simplifies several components, so it is a capstone sketch rather than an integrated full harness.
- Web CI validates the visualization app, but not the Python agent harness behavior.

## Ideas To Steal

- Teach or implement agent harnesses as progressive layers over one stable `while tool_use` loop.
- Keep tool addition boring: one schema, one handler, one dispatch map entry.
- Use two-layer skill loading: cheap metadata in context, expensive body through a tool result only when needed.
- Preserve read/reference outputs longer than transient shell outputs during micro-compaction.
- Store full transcripts before summarizing active context, so compaction remains recoverable.
- Promote single-session todos to a persistent file task graph when work must survive compaction or restart.
- Use JSONL append-only inboxes for simple agent-to-agent communication, but wrap important flows in typed request-response protocols with request IDs.
- Give autonomous teammates an idle cycle that polls both messages and unclaimed unblocked tasks.
- Re-inject identity when a long-lived agent resumes after context compression.
- Separate task coordination from execution isolation: `.tasks/` says what and who; `.worktrees/` says where.
- Emit lifecycle events for worktree create/remove/keep/failure so the harness can debug itself.

## Do Not Copy

- Do not copy the shell execution model as-is. Replace `shell=True` and substring deny lists with structured command execution, sandboxing, and permission review.
- Do not rely on prompt text or tool descriptions for destructive-action safety.
- Do not use drain-on-read JSONL mailboxes without locking or acknowledgement if message loss matters.
- Do not keep protocol request state only in memory for long-running teams.
- Do not run autonomous agents in one shared directory unless task/file ownership and worktree isolation are enforced.
- Do not assume compaction summaries are faithful. Keep source artifacts addressable and add explicit re-read/verify hooks.
- Do not copy the example skills as production policy. They are broad instructional samples, not project-specific procedures.
- Do not use the web app or generated visualization data as the design source of truth; review `agents/` and `docs/` directly.

## Fit For Agentic Coding Lab

Fit is high as a pattern source for AI coding workflow research. The repo directly covers commands/tools, skills, context budgeting, verification hooks by omission, memory/state externalization, subagents, multi-agent coordination, autonomous task claiming, worktree isolation, and error-prevention basics.

The best adoption path is to extract a stricter lab fixture:

- Minimal loop plus dispatch-map tools.
- Skill loader with frontmatter validation and missing-reference checks.
- Persistent task graph with schema tests and atomic writes.
- Mailbox/request-id protocol with acknowledgement and durable request state.
- Worktree isolation with explicit keep/remove closeout and lifecycle events.
- Verification harness that simulates tool calls and state transitions without needing real model calls.

Use this repo to explain and prototype mechanisms. Use stronger local policies and tests before adopting the mechanisms in a shared coding harness.

## Reviewed Paths

- `/tmp/myagents-research/shareAI-lab-learn-claude-code/README.md`: scope, learning path, architecture, omitted production mechanisms, quick start, and session map.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/.env.example`: model/provider configuration and environment surface.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/requirements.txt`: Python runtime dependencies.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/.github/workflows/ci.yml`: web typecheck/build CI.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s01_agent_loop.py`: minimal loop and bash tool.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s02_tool_use.py`: dispatch map and file tools.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s03_todo_write.py`: TodoManager and reminder injection.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s04_subagent.py`: fresh-context subagent and summary return.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s05_skill_loading.py`: `SKILL.md` scanner and `load_skill` tool.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s06_context_compact.py`: micro/auto/manual compaction.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s07_task_system.py`: file-backed task graph.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s08_background_tasks.py`: background execution and notification queue.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s09_agent_teams.py`: persistent teammates and JSONL mailboxes.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s10_team_protocols.py`: shutdown and plan approval protocols.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s11_autonomous_agents.py`: idle polling, auto-claiming, and identity reinjection.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s12_worktree_task_isolation.py`: task-bound worktrees and lifecycle event log.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/agents/s_full.py`: combined s01-s11 reference agent.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s03-todo-write.md`: planning mechanism explanation.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s05-skill-loading.md`: skill-loading token pattern.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s06-context-compact.md`: compression design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s07-task-system.md`: task graph design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s09-agent-teams.md`: team mailbox design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s10-team-protocols.md`: request-response protocol design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s11-autonomous-agents.md`: idle/auto-claim design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/docs/en/s12-worktree-task-isolation.md`: task/worktree isolation design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/skills/agent-builder/SKILL.md`: agent-building skill specimen.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/skills/code-review/SKILL.md`: review checklist skill specimen.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/skills/mcp-builder/SKILL.md`: MCP-building skill specimen.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/skills/pdf/SKILL.md`: PDF skill specimen.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/tests/test_agents_smoke.py`: compile smoke tests.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/tests/test_s_full_background.py`: background-manager unit edge case.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/web/package.json`: web extraction/build scripts and dependencies.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/web/scripts/extract-content.ts`: source/docs extraction pipeline for the visualization site.
- `https://api.github.com/repos/shareAI-lab/learn-claude-code`: repository metadata and star snapshot.

## Excluded Paths

- `/tmp/myagents-research/shareAI-lab-learn-claude-code/.git/`: VCS internals; only HEAD SHA, branch metadata, and latest commit were needed.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/README-zh.md`, `/tmp/myagents-research/shareAI-lab-learn-claude-code/README-ja.md`, `docs/zh/**`, and `docs/ja/**`: translations redundant with the reviewed English docs for workflow analysis.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/web/src/data/generated/*.json`: generated from `agents/` and `docs/` by `web/scripts/extract-content.ts`; source files were reviewed instead.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/web/src/app/**`, `web/src/components/**`, `web/src/hooks/**`, `web/src/i18n/**`, and `web/src/data/scenarios/**`: UI/visualization implementation, useful for teaching presentation but not core harness workflow design.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/web/public/*.svg` and `web/src/app/favicon.ico`: static UI/binary assets.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/web/package-lock.json`: lockfile, useful for reproducible web install but not informative for agent workflow patterns.
- `/tmp/myagents-research/shareAI-lab-learn-claude-code/LICENSE`: legal metadata, not a workflow path.
- Python `__pycache__` created under `/tmp` during local compile verification: generated cache output, not reviewed.
