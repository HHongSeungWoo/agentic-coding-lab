# graykode/abtop

- URL: https://github.com/graykode/abtop
- Category: context-control
- Stars snapshot: 2,271 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: d28dc30f1a9f18cd77f487a172f4d457a6fe1969
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit observability reference for agent context control. It does not manage prompts directly, but it shows how to reconstruct live agent state from local telemetry: token totals, current context window fill, rate-limit pressure, tool execution, subprocesses, ports, subagents, MCP rollouts, and stale session edge cases.

## Why It Matters

Agentic Coding Lab needs more than prompt policies. It needs runtime visibility into whether agents are burning context, waiting on rate limits, running tools, leaking child servers, or losing continuity after compaction or `/clear`.

`abtop` is useful because it treats agent sessions as observable processes with local evidence trails. It reads Claude Code, Codex CLI, and OpenCode local state, correlates transcripts with PIDs and child processes, and renders a compact terminal dashboard. The strongest lesson is how many context-control signals already exist outside the prompt if the runtime records them with enough care.

## What It Is

`abtop` is a Rust `ratatui` terminal monitor for AI coding agents. It supports Claude Code, Codex CLI, and OpenCode sessions, with a TUI plus `--once`, `--demo`, `--setup`, `--theme`, `--version`, and `--update` command paths.

The monitored data is local: process snapshots, file descriptors, JSON/JSONL transcripts, SQLite rows, git status, Claude StatusLine rate-limit files, Codex rollout rate-limit events, and TCP listening ports. The default app is read-oriented, but explicit UI actions and flags can mutate state: `--setup` writes Claude settings and a hook script, `x`/`X` can kill processes, theme/panel toggles write config, and `--update` downloads and runs the release installer.

## Research Themes

- Token efficiency: Strong as observability, not as prompt packing. It tails transcripts incrementally, separates active tokens from cache reads for rate graphs, tracks token history per turn, caches expensive port/git/rate-limit scans, and gives users context-window pressure before compaction becomes urgent.
- Context control: Strong for monitoring. Claude context is derived from assistant usage and hardcoded model windows, Codex context from `token_count` and `turn_context`, compaction is inferred from context/cache drops, and sessions over 90% matching account quota are promoted from Waiting to RateLimited.
- Sub-agent / multi-agent: Moderate. Claude subagents are discovered from per-session subagent directories, and Codex MCP server rollouts are separated from normal sessions. It does not coordinate agents or enforce contracts.
- Domain-specific workflow: Strong for local coding agents. It knows Claude/Codex/OpenCode transcript shapes, tool events, current task signals, git branch/status, tmux pane jumping, and agent-spawned ports.
- Error prevention: Strong implementation instincts. It caps hostile JSONL lines at 10 MB, skips symlinked session/DB files, sanitizes terminal output, redacts common secret prefixes in chat/tool text, verifies PIDs before kills, refreshes ports before killing orphans, and has broad collector tests.
- Self-learning / memory: Limited. It reports Claude memory file counts and lines, and caches session summaries under `~/.cache/abtop/summaries.json`; it is not a learning or durable preference-memory system.
- Popular skills: Runtime dashboards, transcript tailing, status-line hooks, per-agent collector interfaces, local-only telemetry, orphan-port cleanup, context gauges, and focused terminal UI layout.

## Core Execution Path

`main.rs` handles flags first. `--setup` installs a Claude StatusLine hook. `--once` creates `App`, runs one `tick`, waits up to 30 seconds for session summaries, prints a sanitized snapshot, and exits. Normal TUI mode enters the alternate screen, enables raw mode and mouse capture, then calls `run_app`.

`run_app` draws the UI every 500 ms and performs a data `tick` every 2 seconds when input is idle. Key and mouse events mutate `App` state: selection, filtering, panel visibility, theme, tree/timeline/file-audit views, tmux jumps, and kill actions.

`App::tick` is the control point:

1. `MultiCollector::collect` builds a shared process snapshot, detects MCP servers, runs each enabled agent collector, refreshes slow-path git/port data, filters dead sessions, sorts newest first, and updates orphan ports.
2. The app computes per-session active-token deltas into a 200-point graph buffer.
3. Every five ticks, or immediately when empty, it reads Claude rate-limit files from all known config dirs and merges live/cached Codex rate-limit data.
4. Waiting sessions are promoted to RateLimited only when a rate-limit record from the same agent source exceeds 90%.
5. Session summary workers run in the background with a three-job cap and two retries; results are cached locally.

The Claude collector is the richest path. It discovers config roots from default `~/.claude`, `CLAUDE_CONFIG_DIR`, Linux `/proc/<pid>/environ`, and open session/transcript paths. It reads `sessions/{PID}.json`, resolves the right project transcript directory, handles `/clear` by finding the newest safe transcript, tails JSONL from the last offset, and derives tokens, context, compaction count, current tool, chat tail, file accesses, version, branch, subagents, memory status, and status.

The Codex collector finds running Codex PIDs, maps them to open `rollout-*.jsonl` files through `/proc/<pid>/fd` on Linux, Windows directory heuristics, or `lsof`, parses events, and scans today's session dir for recently finished rollouts. It extracts `session_meta`, `turn_context`, token counts, rate-limit windows, function calls, pending tool state, and `exec_command`/`write_stdin` duration linkage.

The OpenCode collector is intentionally thinner. It finds live `opencode` PIDs, queries `~/.local/share/opencode/opencode.db` with `sqlite3 -readonly -json` on slow ticks, and matches DB sessions to PIDs by cwd or command-line substring.

## Architecture

The repo is small and layered:

- CLI/TUI shell: `src/main.rs` owns flags, terminal lifecycle, event loop, mouse handling, `--once`, and self-update.
- App state: `src/app.rs` owns session lists, collectors, summaries, token rates, rate limits, orphan ports, status messages, config overlays, filtering, panel toggles, tmux jump, and kill flows.
- Agent collectors: `src/collector/{claude,codex,opencode,mcp,process,rate_limit}.rs` gather local evidence and normalize it into `AgentSession`.
- Shared model: `src/model/session.rs` defines session status, token accounting, child processes, orphan ports, subagents, tool calls, chat lines, file accesses, and rate-limit records.
- Config/setup: `src/config.rs` reads and rewrites a small TOML-like config. `src/setup.rs` writes the Claude StatusLine hook and settings entry.
- UI: `src/ui/**` renders context, quota, tokens, projects, ports, sessions, MCP servers, overlays, and narrow/desktop responsive layouts.
- Host metrics and demo: `src/host_info.rs` samples Linux `/proc`, and `src/demo.rs` provides synthetic sessions for demos/screenshots.

The common contract is `AgentSession`. That keeps the UI agent-agnostic while allowing collectors to vary heavily in how they discover sessions.

## Design Choices

The best design choice is using a shared process snapshot per tick. Process info, child maps, and listening ports are collected once and reused across collectors, which avoids duplicate `ps`/`lsof` work and makes cross-agent features such as orphan-port detection possible.

Another strong choice is tailing append-only transcripts rather than rereading them every poll. Claude transcript cache entries carry file identity, read offset, token totals, context state, chat tail, tool timeline, and file accesses. If identity changes or the file shrinks, the collector reparses from zero. If a line is incomplete, it defers it; if a line is huge and hostile, it caps allocation and skips.

The code treats status as a set of weak signals instead of a single timestamp. Claude status combines active descendants, pending tool_use, and trailing real user prompts. Codex status combines live PID, `codex exec` completion, active descendants, pending function calls, and model-generating markers. Synthetic Claude user lines such as tool results, `/plugin`, and `!bash` output are filtered so they do not pin sessions in Thinking.

Context math is pragmatic rather than authoritative. Claude windows are inferred from model names, configured model settings, or a high-water mark above 200k. Codex windows come from event fields. Claude compaction detection watches for a context drop above 30% plus a hard cache-read drop, reducing false positives from normal cache variation.

MCP rollouts get their own panel because `codex mcp-server` can hold many old rollout file descriptors. `abtop` detects these PIDs, counts active rollouts by recent mtime, and suppresses their rollouts from normal Codex sessions by default to avoid ghost rows.

The safety posture is mostly "local and defensive." The app avoids following symlinked session files and OpenCode DB paths, redacts common token prefixes from chat/tool display, strips control and bidi characters for terminal output, and verifies process identity before kill actions.

## Strengths

- Practical end-to-end observability for token, context, quota, status, subprocess, port, MCP, git, and memory signals.
- Strong local-data correlation across transcripts, PIDs, child processes, ports, cwd, config roots, and session IDs.
- Collector abstraction is simple enough to add new agents without rewriting the TUI.
- Handles many real agent edge cases: Claude `/clear`, multiple config profiles, worktree transcript dirs, self-spawned `claude --print` summaries, Codex MCP server file descriptors, Windows Codex shims, and OpenCode duplicate DB rows.
- Incremental parsing and slow-poll separation keep the TUI responsive while still tracking expensive data.
- Tests are unusually rich for this kind of monitor: about 142 Rust tests across collectors, process parsing, UI layout/clicks, token accounting, config rewriting, rate-limit promotion, symlink rejection, and transcript edge cases.
- `--once` gives a scriptable snapshot path, useful for CI logs or agent status probes.
- Orphan-port tracking turns a common coding-agent failure mode into a visible, actionable state.

## Weaknesses

- It observes context but does not control prompt assembly. Agentic Coding Lab should treat it as an observability pattern, not a compaction or retrieval engine.
- Data sources are undocumented internals of Claude Code, Codex CLI, and OpenCode. Transcript schemas, config paths, StatusLine payloads, and rollout formats can break without warning.
- Privacy docs are too strong for the implementation. The UI can show prompt-derived titles, selected-session task text, chat history, file paths, commands, and tool arguments. Claude initial prompts are not redacted before every display path, and summary generation sends prompt/assistant snippets to `claude --print`.
- "All read-only" is only true for passive monitoring. `--setup`, theme/panel saves, `x`, `X`, and `--update` write files or affect processes.
- Rate-limit staleness behavior differs from docs. Docs say stale data is rejected after 10 minutes, but the quota UI still renders percentages while dimming the source and hiding reset countdowns.
- `scripts/abtop-statusline.sh` appears older than the embedded `src/setup.rs` script; it expects `session`/`weekly` fields, while the setup script expects `five_hour`/`seven_day`.
- Context-window logic is hardcoded and will lag new models unless updated.
- `src/config.rs` uses a small hand-rolled TOML subset, so complex valid TOML will not be parsed.
- OpenCode support has less state fidelity: no context window, no rate limits, and DB-to-PID matching by cwd/command heuristic.
- Upstream tests could not be run in this worker because `cargo`/`rustc` were not installed in PATH, so this review relies on reading code/tests plus project research verification.

## Ideas To Steal

- Define a normalized `AgentSession` telemetry contract: source, PID, cwd, model, effort, status, context percent/window, token buckets, tool timeline, chat tail, file accesses, child processes, ports, git stats, and rate-limit source.
- Split fast and slow telemetry. Poll transcripts/process state frequently, but cache expensive port scans, git status, config discovery, DB reads, and rate-limit files.
- Tail transcripts with file identity, offset, partial-line handling, hostile-line caps, and reset-on-replacement semantics.
- Track active tokens separately from total tokens so cache hits do not fake work-rate spikes.
- Turn context pressure into first-class UI state: per-session bars, warnings at thresholds, compaction counts, and context-history sparklines.
- Promote waiting sessions to rate-limited only when quota evidence matches the same agent source.
- Detect orphan ports by remembering child port owners across ticks, then comparing against current live session children.
- Before killing anything, rescan fresh state and verify both PID identity and ownership signal.
- Suppress long-lived service processes such as MCP servers from normal session lists and give them a separate, lower-noise view.
- Treat prompt, tool, and file telemetry as sensitive terminal output: redact known secret prefixes, strip controls/bidi, truncate aggressively, and document exactly what can still appear.
- Make `--once` output a machine-friendly health probe for agent supervisor scripts.

## Do Not Copy

- Do not copy private agent transcript parsing without versioned schemas, fixtures, and fallback behavior.
- Do not claim local-only privacy if any path invokes the agent CLI, model API, update installer, or displays prompt-derived data.
- Do not hardcode model context windows without a visible update path or unknown-model fallback policy.
- Do not use PID alone as identity. Always pair it with command, cwd, open file, start time, or fresh port ownership evidence.
- Do not let advisory dashboard actions become hidden mutations. Kill, setup, update, and config writes need explicit labels and safeguards.
- Do not rely on hand-rolled config parsing if users will expect general TOML semantics.
- Do not treat process CPU as enough to distinguish thinking, executing, waiting, permissions, and rate-limit states. Keep status labels approximate unless the agent runtime exposes authoritative events.

## Fit For Agentic Coding Lab

`abtop` is a strong fit as a runtime observability source for the context-control category. The lab should not adopt it as the core context engine, but should mine it for instrumentation patterns.

Best adaptation: a repo-local "agent telemetry panel" or status probe that reads our own agent run logs and process state, not third-party private paths. It should emit a stable JSON snapshot and optional TUI with context pressure, quota pressure, pending tools, subprocesses, open ports, file accesses, and handoff/summary health.

For future lab artifacts, the useful invariant is: context control needs measured state. Handoff rules, compaction prompts, retrieval tools, and subagent contracts should be backed by telemetry showing context fill, token burn, tool duration, child processes, file churn, and stale memory.

## Reviewed Paths

- `README.md`: purpose, install, supported agents, config, keybindings, privacy claims, and feature matrix.
- `AGENTS.md`, `CLAUDE.md`: repo architecture, data-source notes, context-window calculation, status heuristics, privacy/gotchas, commands, and release flow.
- `Cargo.toml`, `Cargo.lock`, `dist-workspace.toml`, `.github/workflows/ci.yml`: crate metadata, dependencies, build/release targets, and CI expectations.
- `src/main.rs`: CLI flags, TUI loop, event handling, `--once`, terminal sanitization, tmux jump UI path, and self-update path.
- `src/app.rs`: central tick loop, collector orchestration, token-rate calculation, rate-limit polling, summary generation, kill confirmation, orphan-port kill logic, tmux pane resolution, and rate-limited promotion tests.
- `src/collector/mod.rs`: shared collector trait, shared process data, hidden-agent filtering, slow-poll scheduling, MCP suppression, git stat caching, and orphan-port detection.
- `src/collector/claude.rs`: Claude config-root discovery, session file and transcript parsing, incremental JSONL cache, `/clear` handling, symlink checks, context/compaction math, subagent/memory discovery, effort/model settings, chat/tool/file extraction, and extensive tests.
- `src/collector/codex.rs`: Codex PID discovery, rollout file mapping, event parsing, rate-limit extraction, tool timeline reconstruction, recent-finished sessions, MCP-owned rollout suppression, Windows shim handling, and tests.
- `src/collector/opencode.rs`: OpenCode SQLite query path, PID matching, DB row sanitation, cache strategy, symlink fail-closed behavior, and tests.
- `src/collector/mcp.rs`: Codex MCP server detection, profile parsing, rollout fd mapping, active mtime threshold, and suppression metadata.
- `src/collector/process.rs`: Linux `/proc`, Windows `sysinfo`/`netstat`, macOS/Unix `ps`/`lsof`, child-tree walking, TCP listen detection, binary matching, git stat collection, and process utility tests.
- `src/collector/rate_limit.rs`: Claude rate-limit file reading and Codex rate-limit cache writes/reads.
- `src/config.rs`, `src/setup.rs`, `scripts/abtop-statusline.sh`: config load/save, panel/theme persistence, Claude StatusLine setup, and script example mismatch.
- `src/model/session.rs`: normalized telemetry structs and token accounting.
- `src/ui/mod.rs`, `src/ui/context.rs`, `src/ui/quota.rs`, `src/ui/tokens.rs`, `src/ui/ports.rs`, `src/ui/sessions.rs`, `src/ui/mcp.rs`, `src/ui/projects.rs`, `src/ui/header.rs`, `src/ui/footer.rs`, `src/ui/config.rs`, `src/ui/help.rs`, `src/ui/view_menu.rs`: terminal presentation, responsive layout, context/quota/tokens/session detail/timeline/file audit/MCP/ports behavior, and UI tests.
- `src/host_info.rs`, `src/demo.rs`, `src/theme.rs`, `src/locale.rs`: host metric sampling, synthetic demo sessions, themes, and localization.

## Excluded Paths

- `assets/*.gif`, `assets/*.mp4`, `assets/*.tape`, `assets/themes/*.png`, and `assets/themes/*.tape`: demo media, screenshots, and VHS recording inputs. Useful for product presentation, not runtime context-control logic.
- `.github/ISSUE_TEMPLATE/**`: issue templates only.
- `.github/workflows/publish.yml`, `.github/workflows/release.yml`: release automation reviewed only at metadata level through Cargo/dist config; not part of live observability behavior.
- `.gitignore`, `LICENSE`, repository metadata, and binary build outputs: maintenance/legal/generated artifacts outside the execution path.
- Vendored dependencies and generated source trees: none were present in the reviewed checkout; Rust dependencies are external crates resolved by Cargo.
