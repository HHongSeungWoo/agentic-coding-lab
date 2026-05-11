# tanweai/pua

- URL: https://github.com/tanweai/pua
- Category: skills-instructions
- Stars snapshot: 17,243 via GitHub REST API on 2026-05-11
- Reviewed commit: 92850d9db2292cdb3010cd8463cce844b326194d
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal coding-agent diligence and governance system. The reusable value is in trigger scoping, hook-backed verification, four-power harness separation, loop/oracle gates, and subagent lifecycle discipline. The corporate pressure rhetoric is intentionally abrasive and should not be copied as-is.

## Why It Matters

`tanweai/pua` is one of the more concrete examples of a "try harder" instruction pack becoming a real agent support system. It is not just a prompt. For Claude Code it ships skills, slash commands, lifecycle hooks, subagents, persistent state files, a loop controller, telemetry/feedback flows, upload sanitization, and static evals around those artifacts.

For Agentic Coding Lab, the interesting part is how it converts common coding-agent failure modes into enforceable workflow contracts: do not claim completion without evidence, do not blame environment without checking, switch approaches after repeated failures, preserve state across compaction, separate implementation from verification, and use external gates for loop completion.

## What It Is

PUA is a multi-platform agent skill/plugin that uses Chinese "PUA" corporate pressure rhetoric and English PIP-style performance rhetoric to push agents toward exhaustive problem solving. The repo supports Claude Code most deeply, with lighter adapters for Codex CLI, pi coding agent, Trae, Cursor, Kiro, CodeBuddy, VSCode Copilot, OpenClaw, Antigravity, OpenCode, Kimi, and Hermes.

The core artifact is a family of `SKILL.md` files. The core skill defines trigger conditions, three red lines, a diagnosis-first rule, proactivity checklists, L1-L4 failure escalation, methodology routing across 14 "flavors", and completion evidence requirements. Claude Code adds command routing and deterministic hooks. Other platforms mostly receive static instruction files or condensed skill variants.

## Research Themes

- Token efficiency: Mixed. The repo has concise Codex aliases and a `shot` skill variant, and it uses references for progressive disclosure, but the main skill and always-on SessionStart injection are large and table-heavy. It trades tokens for pressure, governance, and visibility.
- Context control: Strong for Claude Code. `SessionStart` injects configured flavor/methodology context, `PreCompact` forces a builder journal checkpoint, `session-restore.sh` reloads recent compaction state, and subagent protocols explicitly inject only needed instructions into child contexts.
- Sub-agent / multi-agent: Strong. P7/P8/P9/P10 role protocols, `[PUA-REPORT]`, `[P7-COMPLETION]`, task-prompt templates, file-domain isolation, teardown rules, and four governance agents give a clear multi-agent operating model.
- Domain-specific workflow: Strong for coding-agent behavior, not domain code generation. It targets debugging, implementation, review, ops, research, performance, architecture, and harness/eval workflows through methodology routing.
- Error prevention: Strong. It includes diagnosis-first, verification-before-completion, confidence gates, protected-asset detection, anti-cheating rules, PUA Loop oracle verification, upload consent gates, and tests for those mechanisms.
- Self-learning / memory: Moderate to strong. `~/.pua/evolution.md`, `~/.pua/builder-journal.md`, `.failure_count`, and `.claude/pua-loop-history.jsonl` capture behavior baselines, failure counts, tried approaches, and loop rejections.
- Popular skills: `pua`, `pua-en`, `pua-ja`, `pua-loop`, `pro`, `p7`, `p9`, `p10`, `yes`, `mama`, and platform-specific Codex aliases such as `pua-on`, `pua-off`, `pua-pro`, and `pua-team-status`.

## Core Execution Path

The deepest execution path is Claude Code:

1. Install through the Claude plugin manifest or by placing the repo under the Claude plugin directory.
2. User invokes `/pua`, `/pua:on`, `/pua:pua-loop`, `/pua:p9`, or a related command. `commands/pua.md` routes arguments to the corresponding skill or config action.
3. `skills/pua/SKILL.md` loads the core behavioral protocol and references such as `display-protocol.md`, `methodology-router.md`, `flavors.md`, and flavor-specific methodology files.
4. `hooks/hooks.json` wires deterministic lifecycle behavior:
   - `SessionStart`: runs silent `heartbeat.sh` and `session-restore.sh`.
   - `UserPromptSubmit`: runs `frustration-trigger.sh`, which regex-filters frustration phrases and injects concise diligence context.
   - `PostToolUse` for Bash: runs `failure-detector.sh`, increments a failure counter, and emits L1-L4 escalation.
   - `PreToolUse`: runs `integrity-guard.sh`, which asks or denies protected writes, hidden-solution reads, benchmark-answer searches, and secret access.
   - `PreCompact`: injects a prompt requiring state dump to `~/.pua/builder-journal.md`.
   - `Stop`: runs `pua-loop-hook.sh` and `stop-feedback.sh`.
   - `SubagentStop`: runs lifecycle accounting through `subagent-teardown.sh`.
5. If `~/.pua/config.json` has `always_on: true`, `session-restore.sh` injects a full PUA protocol as `additionalContext`, including red lines, harness integrity, methodology routing, and failure-switch chains.
6. If PUA Loop is started, `scripts/setup-pua-loop.sh` writes a per-project state file under `~/.claude/pua/loop-<hash>.md`, stores the task prompt and optional `verify_command`, and initializes `.claude/pua-loop-history.jsonl`.
7. On Stop, `pua-loop-hook.sh` inspects the last assistant message. `<loop-abort>` exits, `<loop-pause>` pauses, and `<promise>...</promise>` triggers an independent `verify_command`. Failed verification blocks Stop and feeds the output back into the next loop iteration.

The non-Claude paths are thinner. Codex uses symlinked `codex/pua/SKILL.md` plus `$pua-*` skill aliases. pi uses a TypeScript extension that reads/writes shared `~/.pua/config.json`, tracks failure count, and appends a concise system prompt before agent start. Cursor, Kiro, Trae, CodeBuddy, VSCode, Kimi, and Hermes mainly receive static instruction variants.

## Architecture

- `plugin.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codebuddy-plugin/*`: plugin metadata and marketplace packaging.
- `skills/`: Claude/OpenSkills skill set, including core PUA, language variants, P7/P9/P10 roles, Pro, Loop, Yes, Mama, and Shot modes.
- `codex/`: condensed Codex-compatible skills and aliases for Claude-style subcommands.
- `commands/`: Claude slash-command routing for core, role, config, loop, feedback, flavor, offline, and teardown actions.
- `hooks/`: Bash lifecycle hooks for context injection, failure detection, integrity guard, heartbeat telemetry, loop continuation, feedback/upload, sanitization, and teardown.
- `agents/`: governance and role agents, including action executor, self reviewer, verifier, policy guardian, CTO, tech lead, and senior engineer.
- `skills/pua/references/`: methodology routing, flavor details, harness governance, agent team, P7/P9/P10 protocols, teardown, display, platform, survey, and company-methodology files.
- `scripts/setup-pua-loop.sh`: state-file initializer for the autonomous loop.
- `pi/`, `.trae/`, `trae/`, `cursor/`, `kiro/`, `vscode/`, `codebuddy/`, `hermes/`, `kimi/`: platform adapters.
- `landing/`: Cloudflare Pages app and API functions for feedback, heartbeat stats, uploads, auth, leaderboard, and admin stats.
- `evals/`: shell-based static and hook tests for trigger behavior, loop gates, integrity guard, heartbeat silence, upload flow, platform compatibility, release consistency, YAML frontmatter, Windows helpers, and governance agents.

## Design Choices

The strongest design choice is separating motivational language from deterministic gates. The prompts apply pressure, but hooks do the hard work: failure counters, additional context, protected-asset checks, loop verification, telemetry opt-outs, and feedback prompts.

The second strong choice is explicit governance language. The harness protocol separates action right, self-evaluation right, scoring right, and environment-modification right. The repo reinforces this with four specialized agents and a `Task Contract` format that distinguishes `agent_proposed_status` from final `verifier_status`.

The PUA Loop design borrows an oracle pattern: the assistant may promise completion, but the Stop hook independently runs a stored verification command. The loop history file gives the next iteration memory of rejected promises and stalled approaches.

The methodology router is also useful. It maps task classes and failure modes to different operating procedures, not just different tone. Debug tasks route toward RCA, feature work toward question/delete/simplify, research toward search-first, and "done without proof" toward data-driven verification.

The privacy design is more mature than many prompt packs. Heartbeat is silent, rate-limited, hashed, and gated by offline/telemetry/feedback settings. Session upload requires explicit consent and local sanitization. That said, the plugin still introduces network surfaces by default unless users configure offline/telemetry controls.

## Strengths

- Clear trigger scoping. Skill descriptions and command frontmatter repeatedly say not to trigger on normal first-attempt tasks.
- Strong verification posture: no completion without command evidence, diagnosis-first before risky edits, confidence gates before final answers, and loop oracle checks.
- Concrete anti-cheating model for agent harnesses, including protected test/eval/scoring/CI/memory/status paths and hidden-solution contamination.
- Multi-agent work is treated as governance and lifecycle management, not just parallelism. The repo includes role boundaries, file domains, handoff formats, and teardown/orphan protocols.
- Persistent context is purposeful: failure counts, compaction journal, evolution baseline, loop state, and loop history all serve a specific workflow.
- Cross-platform packaging is broad and explicit, while README admits Claude Code is the only platform with full hook support.
- Static evals check important non-product behavior: manifest version sync, hook registration, false trigger guards, upload flow, heartbeat privacy, platform packaging, and governance-agent boundaries.

## Weaknesses

- The rhetoric is intentionally harsh. It may increase effort, but it is unsuitable as default team UX and can create noisy, performative output if copied without tone changes.
- Token cost is high. The main skill, display protocol, flavor tables, and always-on additional context can consume a lot of context before task-specific work begins.
- Some guarantees are stronger in prose than in mechanics. For example, PUA Loop says the assistant cannot modify the verifier command, but the state file is a user-writable file unless host permissions or an external location protect it.
- Claude Code is the real implementation target. Codex, Cursor, Kiro, VSCode, Trae, Kimi, Hermes, and CodeBuddy variants are mostly instruction packaging and do not inherit the hook-level gates.
- The repo mixes core agent-governance artifacts with landing-page UI, telemetry, leaderboard, upload collection, social assets, and monetization/platform plans. Adopters need to separate workflow value from product growth surfaces.
- README references `agents/pua-enforcer-en.md`, but that file was not present at the reviewed commit. Related skill text also mentions an enforcer file, so the watchdog path is partly stale.
- Always-on behavior can be overbroad if enabled globally. Even with trigger guards, a heavy "pressure" context can bias agents toward over-scoping and unnecessary extra work.
- Several features are prompt-level recipes rather than complete runtime systems across all platforms, especially Pro/platform commands outside Claude Code.

## Ideas To Steal

- Use exact trigger descriptions that include both positive triggers and "do not trigger for normal first attempts."
- Add a diagnosis-first one-line commitment before risky debug edits: problem, evidence, next action.
- Require completion evidence as a contract, not as style. "Changed code" is not "verified result."
- Model harness integrity as four powers: action, self-review, scoring, and environment modification.
- Use a protected-asset PreToolUse guard for tests, evals, scoring, verifier, CI, memory/status, hidden solutions, and secrets.
- Store loop completion criteria outside normal assistant prose and have an independent hook re-run verification before accepting a promise.
- Keep failure memory append-only: loop history, builder journals, and excluded hypotheses prevent repeated dead ends after compaction.
- Define subagent handoff formats with file domains, forbidden assets, verification commands, and explicit completion reports.
- Add teardown and orphan-reaping protocols for long-running teams, background agents, worktrees, and loop state.
- Test instruction systems with static evals that check manifests, frontmatter, hook registration, protected paths, and privacy gates.

## Do Not Copy

- Do not copy the PUA/PIP pressure language directly into a professional default assistant. Copy the contracts and gates, not the emotional management style.
- Do not make always-on context large by default. Prefer a concise context injection plus on-demand detailed references.
- Do not treat subagents as trusted verifiers merely because their context is isolated. They can recommend, but final status needs an external gate or human.
- Do not put verifier state in an agent-writable file if the claim is that the agent cannot modify it. Put oracle config in a protected location or enforce write denial.
- Do not mix telemetry, leaderboard, and session-upload product surfaces into a base coding workflow without explicit install-time privacy choices.
- Do not assume static instruction adapters provide the same safety guarantees as hook-backed Claude Code.
- Do not copy broad remote endpoints or feedback prompts unless there is a clear data policy, opt-out, sanitization proof, and rate limiting.
- Do not let "try harder" override legitimate stopping conditions such as missing credentials, destructive actions, unclear product decisions, or permission gates.

## Fit For Agentic Coding Lab

Fit is high as a design-pattern source and medium as an installable artifact source.

The repo is valuable for our research because it demonstrates how a skill can grow from reusable instructions into a lifecycle-aware support system. Its best patterns are narrow triggers, evidence-based completion, compaction state recovery, loop verification, anti-cheating governance, and role-separated subagents.

The adoption path should be selective: extract a neutral "high-agency verification" skill, a small protected-asset guard, a loop oracle pattern, and multi-agent handoff templates. Leave behind the abrasive rhetoric, large display panels, leaderboard/telemetry surfaces, and platform-specific marketing material.

## Reviewed Paths

- `README.md`: product overview, installation, platform support, commands, hook architecture, PUA Loop, agent team, and limitations.
- `docs/FAQ.md`: always-on guidance, prompt-injection troubleshooting, offline mode, Codex alias mapping, pi/Trae support, heartbeat, and upload flow.
- `plugin.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codebuddy-plugin/plugin.json`: version, plugin metadata, keywords, marketplace scope, and release claims.
- `.codex/INSTALL.md`: Codex install path, symlink model, prompt trigger, language variants, aliases, update and uninstall flow.
- `skills/pua/SKILL.md`, `skills/pua-en/SKILL.md`, `codex/pua/SKILL.md`: core trigger descriptions, red lines, diagnosis-first, proactivity, pressure escalation, methodology, and Codex condensation.
- `skills/pro/SKILL.md`, `codex/pua-pro/SKILL.md`: self-evolution, platform commands, KPI, leaderboard, and Codex alias behavior.
- `skills/pua-loop/SKILL.md`, `scripts/setup-pua-loop.sh`, `hooks/pua-loop-hook.sh`: autonomous loop setup, state file, promise tags, verify command, Stop hook, stale lock handling, history, and stall escalation.
- `commands/pua.md`, `commands/on.md`, `commands/off.md`, `commands/offline.md`, `commands/pua-loop.md`, `commands/pro.md`, `commands/team-status.md`, `commands/reap-orphans.md`, `commands/teardown-all.md`: command routing and config/lifecycle semantics.
- `hooks/hooks.json`: Claude lifecycle registration.
- `hooks/session-restore.sh`, `hooks/frustration-trigger.sh`, `hooks/failure-detector.sh`, `hooks/integrity-guard.sh`, `hooks/heartbeat.sh`, `hooks/stop-feedback.sh`, `hooks/sanitize-session.sh`, `hooks/subagent-teardown.sh`, `hooks/flavor-helper.sh`: runtime hook behavior, config parsing, telemetry, feedback, and sanitization.
- `skills/pua/references/harness-governance.md`: four-power separation, task contract, protected assets, memory permissions, and verifier-status model.
- `skills/pua/references/agent-team.md`, `p7-protocol.md`, `p9-protocol.md`, `p10-protocol.md`, `teardown-protocol.md`, `methodology-router.md`, `evolution-protocol.md`, `platform.md`, `display-protocol.md`, `flavors.md`: multi-agent roles, methodology, memory, platform, and display rules.
- `agents/pua-action-executor.md`, `agents/pua-self-reviewer.md`, `agents/pua-verifier.md`, `agents/pua-policy-guardian.md`, `agents/tech-lead-p9.md`, `agents/senior-engineer-p7.md`, `agents/cto-p10.md`: role boundaries, tools, output tags, and governance agent contracts.
- `pi/pua/index.ts`, `pi/package/extensions/pua/index.ts`, `pi/package/package.json`, `pi/package/README.md`: pi extension behavior, shared config, failure counting, and package manifest.
- `.trae/skills/pua/SKILL.md`, `.trae/skills/pua-en/SKILL.md`, `.trae/skills/pua-trae/SKILL.md`, `trae/INSTALL.md`, `trae/DIFF.md`: Trae skill packaging and Claude-vs-Trae boundary.
- `cursor/rules/pua.mdc`, `kiro/steering/pua.md`, `vscode/copilot-instructions.md`, `vscode/prompts/pua.prompt.md`, `codebuddy/pua/SKILL.md`, `hermes/pua/SKILL.md`, `kimi/pua/SKILL.md`: sampled platform instruction variants.
- `landing/functions/api/feedback.ts`, `upload.ts`, `heartbeat.ts`, `_sanitize.ts`, `_session.ts`, migrations `0003_feedback_rate_limits.sql`, `0004_heartbeat.sql`, `0005_upload_rate_limits.sql`: feedback, anonymous upload, heartbeat, sanitization, auth, and rate-limit backend.
- `landing/src/pages/Contribute.tsx`, `landing/src/pages/AdminStats.tsx`, `landing/src/App.tsx`: sampled UI flow only where it affected upload/admin routes.
- `evals/test-integrity-guard.sh`, `test-pua-loop-hook.sh`, `test-heartbeat.sh`, `test-upload-flow.sh`, `test-agent-governance.sh`, `test-release-consistency.sh`, `test-platform-compat.sh`, `test-yaml-frontmatter.sh`, `test-behavior.sh`, `test-helpers.sh`, `run-trigger-test.sh`: verification coverage and release gates.
- `.github/workflows/release.yml`, `.github/CONTRIBUTING.md`, issue templates: release mechanics and contributor surface.

## Excluded Paths

- `assets/**`, `landing/public/**`, `assets/*.jpg`, `assets/*.svg`: image/logo/social assets; not relevant to agent execution except as README decoration.
- `landing/src/components/**`, `landing/src/index.css`, `landing/src/main.tsx`, `landing/src/i18n.ts`, `landing/components.json`, `landing/vite.config.ts`, `landing/eslint.config.js`, `landing/package-lock.json`: UI and frontend build details; sampled only routes/pages tied to upload/admin behavior.
- `landing.html`: standalone promotional page; UI-only.
- `README.zh-CN.md`, `README.ja.md`: translations of the main README; not deeply reviewed after the English README and core Chinese/English skills covered semantics.
- `skills/pua/references/methodology-*.md` beyond representative router/protocol files: company-flavor prose library; sampled through router and core skill, not exhaustively analyzed because the mechanics are repetitive rhetoric variants.
- `skills/yes/SKILL.md`, `skills/mama/SKILL.md`, `skills/shot/SKILL.md`, and matching `codex/pua-yes`, `codex/pua-mama`: tone variants; noted as popular modes but not central to execution.
- `vscode/copilot-instructions-ja.md`, `vscode/copilot-instructions-en.md`, `vscode/instructions/*`, `vscode/prompts/*` language variants beyond sampled files: static instruction packaging, not unique runtime design.
- `kimi/pua-*`, `hermes/pua-*`, `codebuddy/pua-*`, `cursor/rules/pua-*`, `kiro/steering/pua-*` language duplicates beyond representative defaults: platform copy variants.
- `.github/ISSUE_TEMPLATE/**`: contribution triage templates; unrelated to coding-agent workflow mechanics.
- `.git/**`, `.gitignore`, `landing/.gitignore`, `pi/pua/tsconfig.json`, `pi/pua/global.d.ts`, `pi/package/skills/pua/SKILL.md`: repository metadata, generated clone internals, type scaffolding, or copies of already-reviewed skill content.
