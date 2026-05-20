# JuliusBrussee/caveman

- URL: https://github.com/JuliusBrussee/caveman
- Category: ai-coding-workflow
- Stars snapshot: 62.5k stars, 3.5k forks, 77 issues, 134 PRs on GitHub UI, reviewed 2026-05-20
- Reviewed commit: 655b7d9c5431f822264b7732e9901c5578ac84cf
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reusable pattern library for token-efficient AI coding workflows. Best ideas are mode-based compression prompts, always-on activation hooks, compressed subagent output contracts, memory-file compression with validation, and MCP catalog shrinking. Main caution: token savings are better measured than answer fidelity, so any adoption needs explicit correctness and clarity escape hatches.

## Why It Matters

This repo turns "be concise" into a full operating layer for coding agents: install paths, prompt modes, slash commands, hooks, statusline state, memory compression, subagent roles, MCP middleware, benchmarks, and safety tests. It is directly useful for Agentic Coding Lab because it treats token reduction as workflow infrastructure rather than a one-off style prompt.

The most reusable idea is not the caveman voice itself. The useful pattern is an always-on communication contract: terse by default, exact on code and symbols, normal prose for risky cases, with mode switches and visible state. That gives teams a way to reduce transcript growth while keeping agent work auditable.

## What It Is

`caveman` is a cross-agent skill/plugin suite for compressed AI-coding communication. It installs into Claude Code, Codex, Gemini, opencode, OpenClaw, Cursor, Windsurf, Cline, Copilot, and many other agents through native plugins, rule files, or `npx skills add`.

Core surfaces:

- `/caveman [lite|full|ultra|wenyan]` changes response compression level.
- `/caveman-commit` generates terse Conventional Commit messages.
- `/caveman-review` emits one-line review findings.
- `/caveman-stats` reads Claude Code session logs and estimates savings.
- `/caveman-compress <file>` rewrites memory/prose files while preserving code, URLs, paths, and structure.
- `caveman-shrink` proxies MCP servers and compresses safe description fields.
- `cavecrew-*` defines compressed investigator, builder, and reviewer subagents.

## Research Themes

- Token efficiency: Main prompt drops articles, filler, pleasantries, and hedging while preserving technical terms. Benchmarks in README claim average 65% output reduction across 10 prompts, and memory compression fixtures claim average 46% input-token reduction.
- Context control: Claude Code hooks inject rules at `SessionStart`, track mode at `UserPromptSubmit`, and reinforce active mode each turn with a small reminder. Static rule files cover agents without hooks.
- Sub-agent / multi-agent: `cavecrew` defines investigator, builder, and reviewer subagents with strict output contracts, short receipts, and model choices aimed at reducing main-context tool result size.
- Domain-specific workflow: Separate skills compress commit messages, review comments, memory-file rewrite, and stats receipts instead of using one generic brevity rule everywhere.
- Error prevention: Auto-Clarity tells agents to drop terse mode for security warnings, irreversible actions, ambiguous multi-step sequences, and confused users. Code includes symlink-safe flag reads/writes, JSONC-tolerant settings merges, backups, and compression validation.
- Self-learning / memory: No autonomous learning loop in this repo. Memory angle is compression of existing project notes plus stats history; persistent memory is deferred to the related `cavemem` ecosystem project.
- Popular skills: Most reusable skills are `caveman`, `caveman-compress`, `caveman-review`, `caveman-commit`, `caveman-stats`, and `cavecrew`.

## Core Execution Path

Install starts at `install.sh`, `install.ps1`, or `bin/install.js`. The Node installer checks Node >=18, parses flags, detects installed agent providers from a single `PROVIDERS` matrix, then runs each provider's native install mechanism. For Claude Code it installs the plugin, copies hook files into `$CLAUDE_CONFIG_DIR/hooks`, merges `SessionStart` and `UserPromptSubmit` hooks into `settings.json`, optionally configures a statusline, and registers `caveman-shrink`.

At runtime, `src/hooks/caveman-activate.js` writes `$CLAUDE_CONFIG_DIR/.caveman-active`, reads the current `skills/caveman/SKILL.md` when available, filters it to the active intensity, and emits it as hidden SessionStart context. `src/hooks/caveman-mode-tracker.js` parses `/caveman` and natural-language activation/deactivation, updates the flag, runs `/caveman-stats` as a blocking hook command, and injects one-line per-turn reinforcement when a normal caveman mode is active.

For agents without hook APIs, `src/tools/caveman-init.js` writes always-on rule files into `.cursor/rules/`, `.windsurf/rules/`, `.clinerules/`, `.github/copilot-instructions.md`, `.opencode/AGENTS.md`, and `AGENTS.md`. OpenClaw gets a workspace skill plus a marker-fenced `SOUL.md` bootstrap block so the terse contract is injected every turn.

## Architecture

The repo is organized around source-of-truth prompt files and distribution adapters:

- `skills/` holds primary LLM-facing skills.
- `agents/` holds cavecrew subagent definitions.
- `commands/` holds Codex/Gemini TOML command stubs.
- `src/hooks/` holds Claude Code hooks and shared config/state helpers.
- `src/tools/caveman-init.js` writes repo-local activation rules.
- `src/plugins/opencode/` adapts the same flag and reinforcement model to opencode lifecycle hooks.
- `src/mcp-servers/caveman-shrink/` is a stdio MCP proxy that compresses description-like fields.
- `bin/install.js` is the cross-platform installer and provider matrix.
- `bin/lib/settings.js` and `bin/lib/openclaw.js` are defensive config writers.
- `plugins/caveman/` and `dist/caveman.skill` are distribution mirrors/build artifacts.
- `tests/`, `benchmarks/`, and `evals/` provide regression tests and measurement harnesses.

State is intentionally tiny: mode is a short whitelisted string in `.caveman-active`; lifetime stats are append-only JSONL plus a pre-rendered statusline suffix.

## Design Choices

The project separates compression levels from operational commands. `lite`, `full`, `ultra`, and `wenyan*` are style modes; `commit`, `review`, and `compress` are independent skills because their output contracts would conflict with base caveman prose.

The hook design favors persistence over a one-shot prompt. SessionStart injects the full ruleset, while UserPromptSubmit adds a compact reminder so later tool/plugin context does not wash out the style instruction.

The installer uses a provider matrix rather than parallel shell and PowerShell logic. That reduces drift across 30+ agent targets and makes detection/installation policy inspectable.

The compression tools explicitly protect code blocks, inline code, URLs, paths, commands, headings, technical identifiers, and structured Markdown. This is the right boundary: compress human glue text, not machine-readable content.

The MCP proxy is conservative: it compresses catalog descriptions in list responses but leaves requests and `tools/call` responses unchanged. That avoids silently mutating tool output semantics.

## Strengths

Clear reusable prompt contract. The `caveman` skill states exactly what to drop, what to preserve, how to switch modes, when to resume normal prose, and how to keep code and commit/PR text normal.

Operational activation is strong. Hooks, statusline, per-turn reinforcement, static rules, OpenClaw bootstrap, opencode plugin, and Gemini/Codex command files show how to make a prompt mode stick across many agent surfaces.

Compressed subagent receipts are a high-value idea. Tool results from subagents enter the main context verbatim, so structured `path:line - symbol - note` outputs are a real context-control primitive.

Safety engineering is above average for a prompt repo. Symlink-safe file operations, mode whitelist reads, backup verification before overwrite, JSONC settings validation, and dry-run installer tests reduce the chance that a token-saving tool damages local config or leaks secrets.

The eval design includes a terse control arm. Measuring skill output against `Answer concisely.` is more honest than comparing only to verbose baseline behavior.

## Weaknesses

Correctness measurement is thin. The eval README explicitly says it does not measure fidelity, and the README's "technical accuracy 100%" claim is not backed by a judge rubric or task-level correctness checks.

Compression may hide nuance. Auto-Clarity is a prompt rule, not a guarantee. Security findings, architectural tradeoffs, migrations, and user-confusion cases still depend on the model recognizing when terse output is unsafe.

The repo has several distribution mirrors and stale hidden mirrors. `plugins/caveman/**`, `.junie/`, `.kiro/`, `.roo/`, and `.agents/skills/` increase drift risk even though CLAUDE.md documents which mirrors are authoritative.

`caveman-compress` sends file contents to Claude or the Anthropic API when used. It has path-based sensitive-file guards, but adoption in regulated projects would need an explicit local/offline or approval mode.

`caveman-shrink` assumes newline-delimited JSON-RPC framing. Some MCP stdio transports use LSP-style `Content-Length` framing, so the proxy may need transport hardening before broad reuse.

## Ideas To Steal

Use a persistent mode file for communication style. Store only a whitelisted enum, keep readers size-capped, and let hooks/statusline/commands share it.

Split "brevity style" from "operational mini-skills." Commit messages, code review, compression, and stats need their own contracts; they should not inherit a generic terse mode blindly.

Add an Auto-Clarity escape hatch to every compression system. Terse by default, normal prose for security, destructive operations, data loss, complex sequencing, and confused users.

Make subagent output contracts context-first. Investigator results should be path/line/symbol tables; builder results should be minimal receipts; reviewers should emit findings only.

Compress memory files with validation, not blind rewriting. Preserve headings, code blocks, inline code, URLs, paths, and commands; write a backup; verify backup bytes; restore on failed validation.

Create MCP catalog shrinkers that never touch tool call results. Tool descriptions are safe-ish compression targets; tool payloads are not.

Benchmark against a terse control, not just a verbose baseline. This isolates whether the skill adds value beyond "answer concisely."

## Do Not Copy

Do not copy the exact caveman persona as a default product voice unless the target users want that tone. The underlying compression contract is useful independent of the meme wrapper.

Do not treat output-token savings as proof of quality. Add fidelity checks, task success checks, or reviewer scoring before claiming accuracy is preserved.

Do not compress everything. Tool outputs, code, config, logs, stack traces, migrations, security guidance, and irreversible commands need stricter preservation or normal prose.

Do not rely on prompt compliance alone for safety. High-risk modes need enforcement in wrappers, validators, or review gates where possible.

Do not add many generated mirrors without a sync story. If mirrors are needed for agent discovery, document ownership and test sync drift.

## Fit For Agentic Coding Lab

High fit as an ai-coding-workflow reference. The repo provides concrete patterns for token-efficient communication, compressed subagent workflows, hook-driven context control, and agent-neutral install adapters.

Best immediate artifacts for Agentic Coding Lab:

- A neutral "compressed technical mode" skill without meme-specific language.
- A cavecrew-style subagent output contract for research locator/reviewer agents.
- A memory-note compressor that preserves code/paths and validates structure.
- A small MCP description compressor prototype with transport-safe framing.
- A benchmark harness that compares baseline, terse control, and skill mode, plus a fidelity rubric.

Adoption should be selective. Use the architecture and guardrails; avoid overfitting to the voice or treating brevity as a universal good.

## Reviewed Paths

- `README.md`, `INSTALL.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `AGENTS.md`, `GEMINI.md`
- `package.json`, `.claude-plugin/plugin.json`, `.codex/config.toml`, `.codex/hooks.json`, `gemini-extension.json`
- `bin/install.js`, `bin/lib/settings.js`, `bin/lib/openclaw.js`
- `skills/caveman/SKILL.md`, `skills/caveman-compress/SKILL.md`, `skills/caveman-commit/SKILL.md`, `skills/caveman-review/SKILL.md`, `skills/caveman-stats/SKILL.md`, `skills/cavecrew/SKILL.md`
- `skills/caveman-compress/scripts/detect.py`, `compress.py`, `validate.py`, `cli.py`
- `agents/cavecrew-investigator.md`, `agents/cavecrew-builder.md`, `agents/cavecrew-reviewer.md`
- `commands/caveman.toml`, `commands/caveman-commit.toml`, `commands/caveman-review.toml`, `commands/caveman-init.toml`
- `src/hooks/caveman-activate.js`, `caveman-mode-tracker.js`, `caveman-config.js`, `caveman-stats.js`, `caveman-statusline.sh`, `README.md`
- `src/tools/caveman-init.js`, `src/rules/caveman-activate.md`, `src/rules/caveman-openclaw-bootstrap.md`
- `src/plugins/opencode/plugin.js`, `src/plugins/opencode/commands/*.md`
- `src/mcp-servers/caveman-shrink/index.js`, `compress.js`, `README.md`
- `tests/test_symlink_flag.js`, `tests/test_compress_safety.py`, `tests/test_hooks.py`, `tests/test_caveman_stats.js`, `tests/test_mcp_shrink.js`, selected installer tests
- `benchmarks/prompts.json`, `evals/README.md`, `evals/measure.py`, `evals/snapshots/results.json`

## Excluded Paths

- `dist/caveman.skill`: generated release ZIP/build artifact, not source behavior.
- `plugins/caveman/**`: distribution mirror of source skills/agents; read only to understand packaging, not treated as canonical behavior.
- `.junie/`, `.kiro/`, `.roo/`, `.agents/skills/`: hidden stale or compatibility mirrors documented as non-authoritative; excluded from design assessment.
- `docs/index.html`, `docs/assets/dancing-rock-32.png`, `docs/assets/dancing-rock.svg`, `plugins/caveman/assets/**`: UI/docs assets and binary/image files, not core workflow logic.
- `tests/caveman-compress/*.original.md` and paired compressed fixtures: used as evidence of compression behavior, not reviewed as independent source design.
- `.github/ISSUE_TEMPLATE/**`, `.github/FUNDING.yml`, Star History images, and general GitHub UI chrome: project operations or UI-only metadata, not AI workflow mechanics.
